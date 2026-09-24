"""Validate canon data (events, NPCs, locations) for one book.

Usage (PowerShell, from repo root):
    python tools/validate_data.py game/data/canon/book1
    python tools/validate_data.py game/data/canon/book1 --raw canon/raw/book1
    python tools/validate_data.py game/data/canon/book1 --actions game/data/actions.json

Layout checked (schema in docs/adr/0004-m2-canon-schemas.md):
    <dir>/npcs.json                {"schema_version": 1, "npcs": {id: npc}}
    <dir>/locations.json           {"schema_version": 1, "locations": {id: location}}
    <dir>/chapters/<chapter>.json  {"schema_version": 1, "book": N, "chapter": "1.00", "events": {id: event}, "system": [...]}

--raw points at the extractor output (index.json + chapter text). It is optional.
When present, chapter ids must exist in index.json, and summaries must not copy
book text (no run of COPY_RUN words in common with the chapter).
Default for --raw: canon/raw/book<N> next to the repo root, if it exists.
--actions is the game's actions.json; hook "did" action ids must exist in it.
Default: <dir>/../../actions.json, if it exists.

Exit code 0 = valid, 1 = errors. Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

SCHEMA_VERSION = 1
CONFIDENCE = {"confirmed", "likely", "guess"}
STATUS = {"candidate", "reviewed"}
TIERS = {1, 2}
LOCATION_KINDS = {"region", "settlement", "district", "building", "landmark", "wild"}
SYSTEM_KINDS = {"class", "level", "skill", "other"}
ON_FAIL_SIMPLE = {"substitute", "delay", "cancel"}
SUMMARY_MAX = 300
NEWS_MAX = 200
OUTCOMES = {"success", "partial", "fail"}
HOOK_THEN = {"cancel", "change"}
LOG_DAYS = 7  # the action log keeps this many days (rules xp.novelty.window_days)
COPY_RUN = 7  # words; a shared run this long counts as copied text
PLAYER = "player"  # relationship id of the player (a hook's effects may name it as "to")

RE_ID = re.compile(r"^[a-z][a-z0-9_]*$")
RE_FLAG = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$")
RE_TAG = RE_FLAG
RE_CHAPTER = re.compile(r"^(\d+\.\d+[A-Z]?|interlude_[a-z0-9_]+)$")
RE_WORD = re.compile(r"[a-z0-9']+")


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def err(self, where: str, msg: str) -> None:
        self.errors.append(f"{where}: {msg}")

    def warn(self, where: str, msg: str) -> None:
        self.warnings.append(f"{where}: {msg}")


# ---------------------------------------------------------------- field checks

def _keys(r: Report, where: str, obj, required: set[str], optional: set[str] = frozenset()) -> bool:
    if not isinstance(obj, dict):
        r.err(where, "must be an object")
        return False
    missing = sorted(required - obj.keys())
    for k in missing:
        r.err(where, f"missing key '{k}'")
    for k in sorted(obj.keys() - required - optional):
        r.err(where, f"unknown key '{k}'")
    return not missing  # False: caller skips field checks that need the missing keys


def _str(r: Report, where: str, v, max_len: int | None = None, allow_null: bool = False) -> bool:
    if v is None and allow_null:
        return True
    if not isinstance(v, str) or not v.strip():
        r.err(where, "must be a non-empty string" + (" or null" if allow_null else ""))
        return False
    if max_len is not None and len(v) > max_len:
        r.err(where, f"too long ({len(v)} > {max_len} chars); summarise in your own words")
        return False
    return True


def _int(v) -> bool:
    # JSON 3.0 is a float in Python; accept whole floats (Godot writes them).
    return (isinstance(v, int) and not isinstance(v, bool)) or (isinstance(v, float) and v.is_integer())


def _str_list(r: Report, where: str, v, pattern: re.Pattern | None = None) -> list[str]:
    if not isinstance(v, list):
        r.err(where, "must be a list")
        return []
    out = []
    for i, s in enumerate(v):
        if not isinstance(s, str):
            r.err(f"{where}[{i}]", "must be a string")
        elif pattern is not None and not pattern.match(s):
            r.err(f"{where}[{i}]", f"bad format '{s}'")
        else:
            out.append(s)
    if len(set(out)) != len(out):
        r.err(where, "has duplicates")
    return out


def check_canon_ref(r: Report, where: str, ref, book: int, chapters: set[str] | None) -> None:
    if not _keys(r, where, ref, {"book", "chapter", "confidence"}, {"note"}):
        return
    if ref.get("book") != book:
        r.err(f"{where}.book", f"must be {book}")
    ch = ref.get("chapter")
    if not isinstance(ch, str) or not RE_CHAPTER.match(ch):
        r.err(f"{where}.chapter", f"bad chapter id {ch!r}")
    elif chapters is not None and ch not in chapters:
        r.err(f"{where}.chapter", f"chapter {ch!r} not in raw index.json")
    if ref.get("confidence") not in CONFIDENCE:
        r.err(f"{where}.confidence", f"must be one of {sorted(CONFIDENCE)}")
    if "note" in ref:
        _str(r, f"{where}.note", ref["note"], SUMMARY_MAX)


def check_npc(r: Report, where: str, npc, book: int, chapters) -> None:
    req = {"name", "race", "tags", "faction", "home", "classes", "alive_at_start", "status", "canon_ref", "summary"}
    if not _keys(r, where, npc, req):
        return
    _str(r, f"{where}.name", npc["name"], 80)
    _str(r, f"{where}.race", npc["race"], 40)
    _str_list(r, f"{where}.tags", npc["tags"], RE_TAG)
    _str(r, f"{where}.faction", npc["faction"], 60, allow_null=True)
    if npc["home"] is not None and not (isinstance(npc["home"], str) and RE_ID.match(npc["home"])):
        r.err(f"{where}.home", "must be a location id or null")
    if isinstance(npc["classes"], list):
        for i, c in enumerate(npc["classes"]):
            w = f"{where}.classes[{i}]"
            if _keys(r, w, c, {"name", "level"}):
                if not (isinstance(c["name"], str) and c["name"].startswith("[") and c["name"].endswith("]")):
                    r.err(f"{w}.name", "must look like '[Class]'")
                if c["level"] is not None and not (_int(c["level"]) and c["level"] >= 0):
                    r.err(f"{w}.level", "must be an int >= 0 or null")
    else:
        r.err(f"{where}.classes", "must be a list")
    if not isinstance(npc["alive_at_start"], bool):
        r.err(f"{where}.alive_at_start", "must be true or false")
    if npc["status"] not in STATUS:
        r.err(f"{where}.status", f"must be one of {sorted(STATUS)}")
    check_canon_ref(r, f"{where}.canon_ref", npc["canon_ref"], book, chapters)
    _str(r, f"{where}.summary", npc["summary"], SUMMARY_MAX)


def check_location(r: Report, where: str, loc, book: int, chapters) -> None:
    req = {"name", "kind", "parent", "tags", "status", "canon_ref", "summary"}
    if not _keys(r, where, loc, req):
        return
    _str(r, f"{where}.name", loc["name"], 80)
    if loc["kind"] not in LOCATION_KINDS:
        r.err(f"{where}.kind", f"must be one of {sorted(LOCATION_KINDS)}")
    if loc["parent"] is not None and not (isinstance(loc["parent"], str) and RE_ID.match(loc["parent"])):
        r.err(f"{where}.parent", "must be a location id or null")
    _str_list(r, f"{where}.tags", loc["tags"], RE_TAG)
    if loc["status"] not in STATUS:
        r.err(f"{where}.status", f"must be one of {sorted(STATUS)}")
    check_canon_ref(r, f"{where}.canon_ref", loc["canon_ref"], book, chapters)
    _str(r, f"{where}.summary", loc["summary"], SUMMARY_MAX)


def check_event(r: Report, where: str, ev, book: int, chapters) -> None:
    req = {"tier", "window", "location", "roles", "requires", "depends_on", "on_fail", "effects",
           "status", "canon_ref", "summary"}
    opt = {"delay_limit", "rumor", "news", "hooks", "stage"}
    if not _keys(r, where, ev, req, opt):
        return
    if ev["tier"] not in TIERS:
        r.err(f"{where}.tier", f"must be one of {sorted(TIERS)} (T3 is emergent, not data)")

    w = ev["window"]
    if _keys(r, f"{where}.window", w, {"earliest", "latest", "confidence"}):
        e, l = w["earliest"], w["latest"]
        if not (_int(e) and e >= 1):
            r.err(f"{where}.window.earliest", "must be an int day >= 1")
        elif not (_int(l) and l >= e):
            r.err(f"{where}.window.latest", "must be an int day >= earliest")
        if w["confidence"] not in CONFIDENCE:
            r.err(f"{where}.window.confidence", f"must be one of {sorted(CONFIDENCE)}")

    if not (isinstance(ev["location"], str) and RE_ID.match(ev["location"])):
        r.err(f"{where}.location", "must be a location id")

    roles = ev["roles"]
    if isinstance(roles, dict):
        for name, role in roles.items():
            rw = f"{where}.roles.{name}"
            if not RE_ID.match(name):
                r.err(rw, "role name must be snake_case")
            if _keys(r, rw, role, {"prefer", "fallback_tags"}, {"optional"}):
                _str_list(r, f"{rw}.prefer", role["prefer"], RE_ID)
                _str_list(r, f"{rw}.fallback_tags", role["fallback_tags"], RE_TAG)
                if "optional" in role and not isinstance(role["optional"], bool):
                    r.err(f"{rw}.optional", "must be true or false")
                if not role["prefer"] and not role["fallback_tags"]:
                    r.err(rw, "needs at least one of prefer / fallback_tags")
    else:
        r.err(f"{where}.roles", "must be an object")

    rq = ev["requires"]
    if _keys(r, f"{where}.requires", rq, {"alive", "flags", "not_flags"}):
        _str_list(r, f"{where}.requires.alive", rq["alive"], RE_ID)
        _str_list(r, f"{where}.requires.flags", rq["flags"], RE_FLAG)
        _str_list(r, f"{where}.requires.not_flags", rq["not_flags"], RE_FLAG)

    _str_list(r, f"{where}.depends_on", ev["depends_on"], re.compile(r"^b\d+\.[a-z0-9_]+$"))

    of = ev["on_fail"]
    if isinstance(of, list) and of:
        for i, step in enumerate(of):
            if not isinstance(step, str) or not (step in ON_FAIL_SIMPLE or step.startswith("mutate:")):
                r.err(f"{where}.on_fail[{i}]", "must be substitute | delay | cancel | mutate:<event id>")
        if of[-1] != "cancel":
            r.err(f"{where}.on_fail", "last step must be 'cancel' so the director always ends")
    else:
        r.err(f"{where}.on_fail", "must be a non-empty list")
    if "delay_limit" in ev and not (_int(ev["delay_limit"]) and ev["delay_limit"] >= 1):
        r.err(f"{where}.delay_limit", "must be an int >= 1 (days)")

    check_effects(r, f"{where}.effects", ev["effects"])

    if ev["status"] not in STATUS:
        r.err(f"{where}.status", f"must be one of {sorted(STATUS)}")
    check_canon_ref(r, f"{where}.canon_ref", ev["canon_ref"], book, chapters)
    _str(r, f"{where}.summary", ev["summary"], SUMMARY_MAX)
    if "rumor" in ev:
        _str(r, f"{where}.rumor", ev["rumor"], 200)
    if "news" in ev:
        _str(r, f"{where}.news", ev["news"], NEWS_MAX)
    if "hooks" in ev:
        check_hooks(r, where, ev["hooks"], ev.get("window"))
    if "stage" in ev:
        check_stage(r, f"{where}.stage", ev["stage"])


def check_stage(r: Report, where: str, st) -> None:
    """A canon fight on the map (M6.5, ADR 0011). The game checks enemies and map tiles."""
    if not _keys(r, where, st, {"area", "hours", "foes"},
                 {"when_flags", "unless_flags", "allies", "line", "note"}):
        return
    if not (isinstance(st["area"], str) and RE_ID.match(st["area"])):
        r.err(f"{where}.area", "must be a map id")
    h = st["hours"]
    if not (isinstance(h, list) and len(h) == 2 and all(_int(x) for x in h)
            and 0 <= h[0] <= 24 and 0 <= h[1] <= 24 and h[0] != h[1]):
        r.err(f"{where}.hours", "must be [from, to] whole hours with 0 <= from != to <= 24")
    foes = st["foes"]
    if not isinstance(foes, list) or not foes:
        r.err(f"{where}.foes", "must be a non-empty list")
    else:
        for i, f in enumerate(foes):
            fw = f"{where}.foes[{i}]"
            if not _keys(r, fw, f, {"enemy", "pos"}):
                continue
            if not (isinstance(f["enemy"], str) and RE_ID.match(f["enemy"])):
                r.err(f"{fw}.enemy", "must be an enemy id")
            p = f["pos"]
            if not (isinstance(p, list) and len(p) == 2 and all(_int(x) and x >= 0 for x in p)):
                r.err(f"{fw}.pos", "must be [x, y] with x, y >= 0")
    for k in ("when_flags", "unless_flags"):
        if k in st:
            _str_list(r, f"{where}.{k}", st[k], RE_FLAG)
    if "allies" in st:
        _str_list(r, f"{where}.allies", st["allies"], RE_ID)
    if "line" in st:
        _str(r, f"{where}.line", st["line"], NEWS_MAX)
    if "note" in st:
        _str(r, f"{where}.note", st["note"], SUMMARY_MAX)


def check_effects(r: Report, where: str, fx) -> None:
    if not _keys(r, where, fx, set(), {"set_flags", "clear_flags", "kill", "relationship"}):
        return
    for k in ("set_flags", "clear_flags"):
        if k in fx:
            _str_list(r, f"{where}.{k}", fx[k], RE_FLAG)
    if "kill" in fx:
        _str_list(r, f"{where}.kill", fx["kill"], RE_ID)
    for i, rel in enumerate(fx.get("relationship", []) if isinstance(fx.get("relationship", []), list) else []):
        rw = f"{where}.relationship[{i}]"
        if _keys(r, rw, rel, {"from", "to", "delta"}):
            for k in ("from", "to"):
                if not (isinstance(rel[k], str) and RE_ID.match(rel[k])):
                    r.err(f"{rw}.{k}", "must be an npc id")
            if not (_int(rel["delta"]) and rel["delta"] != 0):
                r.err(f"{rw}.delta", "must be a non-zero int")


def _scalar(v) -> bool:
    return isinstance(v, (str, int, float, bool))


def check_hooks(r: Report, where: str, hooks, window) -> None:
    """Player hooks (M6.4, ADR 0011): what the player did can cancel, change or mutate the event."""
    if not isinstance(hooks, list) or not hooks:
        r.err(f"{where}.hooks", "must be a non-empty list")
        return
    seen: set[str] = set()
    for i, h in enumerate(hooks):
        hw = f"{where}.hooks[{i}]"
        if not _keys(r, hw, h, {"id", "did", "days", "then"}, {"effects", "news"}):
            continue
        if not (isinstance(h["id"], str) and RE_ID.match(h["id"])):
            r.err(f"{hw}.id", "must be snake_case")
        elif h["id"] in seen:
            r.err(f"{hw}.id", f"duplicate hook id '{h['id']}'")
        else:
            seen.add(h["id"])
        did = h["did"]
        if not isinstance(did, list) or not did:
            r.err(f"{hw}.did", "must be a non-empty list")
        else:
            for j, m in enumerate(did):
                mw = f"{hw}.did[{j}]"
                if not _keys(r, mw, m, {"action"}, {"outcome", "context"}):
                    continue
                if not _str_list(r, f"{mw}.action", m["action"], RE_ID):
                    r.err(f"{mw}.action", "must name at least one action")
                if "outcome" in m:
                    for o in _str_list(r, f"{mw}.outcome", m["outcome"]):
                        if o not in OUTCOMES:
                            r.err(f"{mw}.outcome", f"must be in {sorted(OUTCOMES)}")
                if "context" in m:
                    ctx = m["context"]
                    if not isinstance(ctx, dict) or not ctx:
                        r.err(f"{mw}.context", "must be a non-empty object")
                    else:
                        for k, v in ctx.items():
                            ok = _scalar(v) or (isinstance(v, list) and v and all(_scalar(x) for x in v))
                            if not RE_ID.match(k) or not ok:
                                r.err(f"{mw}.context.{k}", "must be key: value or key: [values]")
        days = h["days"]
        if not (isinstance(days, list) and len(days) == 2 and all(_int(x) for x in days)
                and 1 <= days[0] <= days[1]):
            r.err(f"{hw}.days", "must be [from, to] days with 1 <= from <= to")
        elif days[1] - days[0] >= LOG_DAYS:
            r.err(f"{hw}.days", f"the action log keeps {LOG_DAYS} days; span at most {LOG_DAYS} days")
        elif isinstance(window, dict) and _int(window.get("latest")) and days[0] > window["latest"]:
            r.warn(hw, "days start after the event's window; the hook only matches if the event is delayed")
        then = h["then"]
        if not (isinstance(then, str) and (then in HOOK_THEN or then.startswith("mutate:"))):
            r.err(f"{hw}.then", "must be cancel | change | mutate:<event id>")
        elif then == "change":
            if "effects" in h:
                check_effects(r, f"{hw}.effects", h["effects"])
            else:
                r.err(hw, "'change' needs effects")
        elif "effects" in h:
            r.err(hw, "effects only with 'change'")
        if "news" in h:
            _str(r, f"{hw}.news", h["news"], NEWS_MAX)


def check_system_entry(r: Report, where: str, s) -> None:
    if not _keys(r, where, s, {"who", "kind", "name", "level", "confidence"}, {"note"}):
        return
    if not (isinstance(s["who"], str) and RE_ID.match(s["who"])):
        r.err(f"{where}.who", "must be an npc id")
    if s["kind"] not in SYSTEM_KINDS:
        r.err(f"{where}.kind", f"must be one of {sorted(SYSTEM_KINDS)}")
    _str(r, f"{where}.name", s["name"], 80)
    if s["level"] is not None and not (_int(s["level"]) and s["level"] >= 0):
        r.err(f"{where}.level", "must be an int >= 0 or null")
    if s["confidence"] not in CONFIDENCE:
        r.err(f"{where}.confidence", f"must be one of {sorted(CONFIDENCE)}")
    if "note" in s:
        _str(r, f"{where}.note", s["note"], SUMMARY_MAX)


# ---------------------------------------------------------------- copy check

def _words(text: str) -> list[str]:
    return RE_WORD.findall(text.lower().replace("’", "'"))


def _shingles(words: list[str], n: int) -> set[tuple[str, ...]]:
    return {tuple(words[i:i + n]) for i in range(len(words) - n + 1)}


def copied_run(own_text: str, book_shingles: set[tuple[str, ...]], n: int = COPY_RUN) -> str | None:
    """Returns the first run of n words that also appears in the book text, else None."""
    for sh in _shingles(_words(own_text), n):
        if sh in book_shingles:
            return " ".join(sh)
    return None


# ---------------------------------------------------------------- loading

def _load(r: Report, path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        r.err(str(path), "file not found")
    except json.JSONDecodeError as e:
        r.err(str(path), f"invalid JSON: {e}")
    return None


def _book_from_dir(d: Path) -> int | None:
    m = re.search(r"book(\d+)$", d.name)
    return int(m.group(1)) if m else None


def _has_cycle(graph: dict[str, list[str]]) -> list[str] | None:
    WHITE, GREY, BLACK = 0, 1, 2
    color = {k: WHITE for k in graph}
    stack: list[str] = []

    def visit(n: str) -> list[str] | None:
        color[n] = GREY
        stack.append(n)
        for m in graph.get(n, []):
            if m not in color:
                continue
            if color[m] == GREY:
                return stack[stack.index(m):] + [m]
            if color[m] == WHITE:
                c = visit(m)
                if c:
                    return c
        stack.pop()
        color[n] = BLACK
        return None

    for n in sorted(graph):
        if color[n] == WHITE:
            c = visit(n)
            if c:
                return c
    return None


def validate_dir(data_dir: str | Path, raw_dir: str | Path | None = None,
                 actions: set[str] | None = None) -> Report:
    r = Report()
    d = Path(data_dir)
    book = _book_from_dir(d)
    if book is None:
        r.err(str(d), "folder name must end in book<N>")
        return r

    chapters: set[str] | None = None
    raw_text: dict[str, str] = {}
    if raw_dir is not None:
        rd = Path(raw_dir)
        index = _load(r, rd / "index.json")
        if isinstance(index, list):
            chapters = {c["id"] for c in index}
            for c in index:
                p = rd / c["file"]
                if p.exists():
                    raw_text[c["id"]] = p.read_text(encoding="utf-8")

    # --- registries
    npcs, locations = {}, {}
    for fname, key, checker, store in (
        ("npcs.json", "npcs", check_npc, npcs),
        ("locations.json", "locations", check_location, locations),
    ):
        doc = _load(r, d / fname)
        if doc is None:
            continue
        if _keys(r, fname, doc, {"schema_version", key}):
            if doc["schema_version"] != SCHEMA_VERSION:
                r.err(f"{fname}.schema_version", f"must be {SCHEMA_VERSION}")
            if not isinstance(doc[key], dict):
                r.err(f"{fname}.{key}", "must be an object keyed by id")
                continue
            for rid, rec in doc[key].items():
                where = f"{fname}:{key}.{rid}"
                if not RE_ID.match(rid):
                    r.err(where, "id must be lowercase snake_case")
                checker(r, where, rec, book, chapters)
                store[rid] = rec

    for lid, loc in locations.items():
        if isinstance(loc, dict) and loc.get("parent") not in (None, *locations.keys()):
            r.err(f"locations.json:locations.{lid}.parent", f"unknown location '{loc['parent']}'")
    parent_graph = {lid: [loc["parent"]] for lid, loc in locations.items()
                    if isinstance(loc, dict) and isinstance(loc.get("parent"), str)}
    cyc = _has_cycle({k: parent_graph.get(k, []) for k in locations})
    if cyc:
        r.err("locations.json", f"parent cycle: {' -> '.join(cyc)}")
    for nid, npc in npcs.items():
        if isinstance(npc, dict) and npc.get("home") not in (None, *locations.keys()):
            r.err(f"npcs.json:npcs.{nid}.home", f"unknown location '{npc['home']}'")

    # --- chapter files
    events: dict[str, tuple[str, dict]] = {}
    system_refs: list[tuple[str, str]] = []
    ch_dir = d / "chapters"
    files = sorted(ch_dir.glob("*.json")) if ch_dir.is_dir() else []
    if not files:
        r.err(str(ch_dir), "no chapter files")
    for f in files:
        doc = _load(r, f)
        fn = f"chapters/{f.name}"
        if doc is None or not _keys(r, fn, doc, {"schema_version", "book", "chapter", "events", "system"}):
            continue
        if doc["schema_version"] != SCHEMA_VERSION:
            r.err(f"{fn}.schema_version", f"must be {SCHEMA_VERSION}")
        if doc["book"] != book:
            r.err(f"{fn}.book", f"must be {book}")
        ch = doc["chapter"]
        if f.stem != ch:
            r.err(fn, f"file name must be '{ch}.json'")
        if chapters is not None and ch not in chapters:
            r.err(f"{fn}.chapter", f"chapter {ch!r} not in raw index.json")
        if not isinstance(doc["events"], dict):
            r.err(f"{fn}.events", "must be an object keyed by event id")
        else:
            for eid, ev in doc["events"].items():
                where = f"{fn}:events.{eid}"
                if not re.match(rf"^b{book}\.[a-z0-9_]+$", eid):
                    r.err(where, f"event id must look like 'b{book}.snake_case'")
                if eid in events:
                    r.err(where, f"duplicate event id (also in {events[eid][0]})")
                check_event(r, where, ev, book, chapters)
                if isinstance(ev, dict) and isinstance(ev.get("canon_ref"), dict) and ev["canon_ref"].get("chapter") != ch:
                    r.err(f"{where}.canon_ref.chapter", f"must match the file's chapter '{ch}'")
                events[eid] = (fn, ev)
        if isinstance(doc["system"], list):
            for i, s in enumerate(doc["system"]):
                check_system_entry(r, f"{fn}:system[{i}]", s)
                if isinstance(s, dict) and isinstance(s.get("who"), str):
                    system_refs.append((f"{fn}:system[{i}].who", s["who"]))
        else:
            r.err(f"{fn}.system", "must be a list")

    # --- cross references
    def need_npc(where: str, nid: str) -> None:
        if nid not in npcs:
            r.err(where, f"unknown npc '{nid}'")

    def effect_npcs(where: str, fx, player_ok: bool = False) -> None:
        if not isinstance(fx, dict):
            return
        for nid in fx.get("kill", []) if isinstance(fx.get("kill"), list) else []:
            need_npc(f"{where}.kill", nid)
        for i, rel in enumerate(fx.get("relationship", []) if isinstance(fx.get("relationship"), list) else []):
            if isinstance(rel, dict):
                for k in ("from", "to"):
                    if isinstance(rel.get(k), str) and not (player_ok and k == "to" and rel[k] == PLAYER):
                        need_npc(f"{where}.relationship[{i}].{k}", rel[k])

    for where, nid in system_refs:
        need_npc(where, nid)

    graph: dict[str, list[str]] = {}
    for eid, (fn, ev) in events.items():
        if not isinstance(ev, dict):
            continue
        w = f"{fn}:events.{eid}"
        if isinstance(ev.get("location"), str) and ev["location"] not in locations:
            r.err(f"{w}.location", f"unknown location '{ev['location']}'")
        for rname, role in (ev.get("roles") or {}).items():
            if isinstance(role, dict):
                for nid in role.get("prefer", []) if isinstance(role.get("prefer"), list) else []:
                    need_npc(f"{w}.roles.{rname}.prefer", nid)
        rq = ev.get("requires") if isinstance(ev.get("requires"), dict) else {}
        for nid in rq.get("alive", []) if isinstance(rq.get("alive"), list) else []:
            need_npc(f"{w}.requires.alive", nid)
        effect_npcs(f"{w}.effects", ev.get("effects"))
        st = ev.get("stage") if isinstance(ev.get("stage"), dict) else {}
        for nid in st.get("allies", []) if isinstance(st.get("allies"), list) else []:
            if isinstance(nid, str):
                need_npc(f"{w}.stage.allies", nid)
        hooks = ev.get("hooks") if isinstance(ev.get("hooks"), list) else []
        mutates = [(f"{w}.on_fail", s) for s in (ev.get("on_fail") if isinstance(ev.get("on_fail"), list) else [])]
        for i, h in enumerate(hooks):
            if not isinstance(h, dict):
                continue
            effect_npcs(f"{w}.hooks[{i}].effects", h.get("effects"), player_ok=True)
            mutates.append((f"{w}.hooks[{i}].then", h.get("then")))
            for j, m in enumerate(h.get("did") if isinstance(h.get("did"), list) else []):
                acts = m.get("action") if isinstance(m, dict) and isinstance(m.get("action"), list) else []
                for a in acts:
                    if actions is not None and isinstance(a, str) and a not in actions:
                        r.err(f"{w}.hooks[{i}].did[{j}].action", f"unknown action '{a}'")
        deps = [x for x in ev.get("depends_on", []) if isinstance(x, str)] if isinstance(ev.get("depends_on"), list) else []
        graph[eid] = deps
        for dep in deps:
            if dep == eid:
                r.err(f"{w}.depends_on", "event depends on itself")
            elif dep not in events:
                r.err(f"{w}.depends_on", f"unknown event '{dep}'")
            else:
                dw, ew = events[dep][1].get("window"), ev.get("window")
                if (isinstance(dw, dict) and isinstance(ew, dict)
                        and _int(dw.get("earliest")) and _int(ew.get("latest"))
                        and dw["earliest"] > ew["latest"]):
                    r.err(f"{w}.depends_on", f"'{dep}' can only start after this event's window ends")
        for mw, step in mutates:
            if isinstance(step, str) and step.startswith("mutate:"):
                target = step[len("mutate:"):]
                if target == eid:
                    r.err(mw, "event mutates into itself")
                elif target not in events:
                    r.err(mw, f"unknown mutate target '{target}'")
        if "delay" in (ev.get("on_fail") or []) and "delay_limit" not in ev:
            r.warn(w, "uses 'delay' without delay_limit; the director default applies")

    cyc = _has_cycle(graph)
    if cyc:
        r.err("events", f"depends_on cycle: {' -> '.join(cyc)}")

    # --- no copied book text
    if raw_text:
        book_shingles: dict[str, set] = {}

        def shingles_for(ch: str) -> set:
            if ch not in book_shingles:
                book_shingles[ch] = _shingles(_words(raw_text.get(ch, "")), COPY_RUN)
            return book_shingles[ch]

        def copy_check(where: str, rec: dict, fields: tuple[str, ...], ref: dict | None = None) -> None:
            if ref is None:
                ref = rec.get("canon_ref") if isinstance(rec.get("canon_ref"), dict) else {}
            ch = ref.get("chapter")
            if ch not in raw_text:
                return
            for fld in fields:
                val = ref.get("note") if fld == "canon_ref.note" else rec.get(fld)
                if isinstance(val, str):
                    run = copied_run(val, shingles_for(ch))
                    if run:
                        r.err(f"{where}.{fld}", f"copies book text: \"{run}\"")

        for eid, (fn, ev) in events.items():
            if isinstance(ev, dict):
                copy_check(f"{fn}:events.{eid}", ev, ("summary", "rumor", "news", "canon_ref.note"))
                ref = ev.get("canon_ref") if isinstance(ev.get("canon_ref"), dict) else {}
                for i, h in enumerate(ev.get("hooks") if isinstance(ev.get("hooks"), list) else []):
                    if isinstance(h, dict):
                        copy_check(f"{fn}:events.{eid}.hooks[{i}]", h, ("news",), ref)
                if isinstance(ev.get("stage"), dict):
                    copy_check(f"{fn}:events.{eid}.stage", ev["stage"], ("line",), ref)
        for nid, npc in npcs.items():
            if isinstance(npc, dict):
                copy_check(f"npcs.json:npcs.{nid}", npc, ("summary", "canon_ref.note"))
        for lid, loc in locations.items():
            if isinstance(loc, dict):
                copy_check(f"locations.json:locations.{lid}", loc, ("summary", "canon_ref.note"))

    return r


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("data_dir", help="e.g. game/data/canon/book1")
    ap.add_argument("--raw", help="extractor output, e.g. canon/raw/book1 (default: auto)")
    ap.add_argument("--no-raw", action="store_true", help="skip chapter-id and copy checks")
    ap.add_argument("--actions", help="the game's actions.json (default: <dir>/../../actions.json)")
    args = ap.parse_args(argv)

    actions = None
    act_path = Path(args.actions) if args.actions else Path(args.data_dir).parent.parent / "actions.json"
    if act_path.exists():
        doc = json.loads(act_path.read_text(encoding="utf-8"))
        actions = set(doc.get("actions", doc))

    raw = None
    if not args.no_raw:
        if args.raw:
            raw = args.raw
        else:
            book = _book_from_dir(Path(args.data_dir))
            guess = Path(__file__).resolve().parent.parent / "canon" / "raw" / f"book{book}"
            if book is not None and (guess / "index.json").exists():
                raw = guess

    rep = validate_dir(args.data_dir, raw, actions)
    for w in rep.warnings:
        print(f"WARN  {w}")
    for e in rep.errors:
        print(f"ERROR {e}")
    mode = f"raw={raw}" if raw else "no raw text (chapter-id and copy checks skipped)"
    mode += f", actions={act_path}" if actions is not None else ", no actions.json (hook actions not checked)"
    print(f"{len(rep.errors)} errors, {len(rep.warnings)} warnings ({mode})")
    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
