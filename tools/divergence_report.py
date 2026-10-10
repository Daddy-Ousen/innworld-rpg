"""Divergence report: how far each book's canon events can bend (M23.0).

Per book it counts roles, fallbacks, on_fail steps and player hooks, and it
ranks two kinds of pick candidates for M23.1+:
  - key NPCs: the NPCs whose death (at book start) loses the most events,
    directly (the NPC is in `requires.alive`, or is the only `prefer` of a
    required role that cannot be substituted) and through `depends_on`;
  - key events: the events that the most later events depend on.

Read-only. Output is Markdown (stdout or --out).

Run: python tools/divergence_report.py game/data/canon [--books 2-7] [--top 12] [--out docs/divergence/report.md]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

PLAYER = "player"


def load_canon(canon_root: str | Path) -> tuple[dict[str, dict], dict[str, dict]]:
    """Returns (events, npcs). Each event gets `_book` (its folder) and `_chapter`."""
    events: dict[str, dict] = {}
    npcs: dict[str, dict] = {}
    for book_dir in sorted(Path(canon_root).glob("book*")):
        m = re.fullmatch(r"book(\d+)", book_dir.name)
        if not m:
            continue
        book = int(m.group(1))
        npc_file = book_dir / "npcs.json"
        if npc_file.exists():
            npcs.update(json.loads(npc_file.read_text(encoding="utf-8")).get("npcs", {}))
        for ch_file in sorted((book_dir / "chapters").glob("*.json")):
            data = json.loads(ch_file.read_text(encoding="utf-8"))
            for eid, ev in data.get("events", {}).items():
                events[eid] = dict(ev, _book=book, _chapter=data.get("chapter", ch_file.stem))
    return events, npcs


def pinned_npcs(ev: dict) -> set[str]:
    """NPCs whose death alone makes this event fail hard (no substitute can help)."""
    pins = {n for n in ev.get("requires", {}).get("alive", []) if n != PLAYER}
    can_sub = "substitute" in ev.get("on_fail", [])
    for role in ev.get("roles", {}).values():
        prefer = role.get("prefer", [])
        if role.get("optional", False) or len(prefer) != 1 or prefer[0] == PLAYER:
            continue
        if can_sub and role.get("fallback_tags"):
            continue
        pins.add(prefer[0])
    return pins


def dependents(events: dict[str, dict]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = defaultdict(list)
    for eid, ev in events.items():
        for dep in ev.get("depends_on", []):
            out[dep].append(eid)
    return out


def closure(start: set[str], deps: dict[str, list[str]]) -> set[str]:
    """`start` plus every event that depends on one of them, transitively."""
    seen = set(start)
    stack = list(start)
    while stack:
        for nxt in deps.get(stack.pop(), []):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return seen


def book_stats(events: dict[str, dict], npcs: dict[str, dict], book: int, top: int) -> dict:
    deps = dependents(events)
    mine = {eid: ev for eid, ev in events.items() if ev["_book"] == book}
    on_fail: Counter = Counter()
    hooks: Counter = Counter()
    tiers: Counter = Counter()
    roles = fallback = optional = with_hooks = 0
    by_npc: dict[str, set[str]] = defaultdict(set)
    for eid, ev in mine.items():
        tiers[ev.get("tier")] += 1
        for step in ev.get("on_fail", []):
            on_fail["mutate" if step.startswith("mutate:") else step] += 1
        if ev.get("hooks"):
            with_hooks += 1
        for h in ev.get("hooks", []):
            then = h.get("then", "")
            hooks["mutate" if then.startswith("mutate:") else then] += 1
        for role in ev.get("roles", {}).values():
            roles += 1
            fallback += bool(role.get("fallback_tags"))
            optional += bool(role.get("optional", False))
        for npc in pinned_npcs(ev):
            by_npc[npc].add(eid)

    key_npcs = []
    for npc, direct in by_npc.items():
        lost = {e for e in closure(direct, deps) if events[e]["_book"] == book}
        key_npcs.append({"npc": npc, "name": npcs.get(npc, {}).get("name", npc),
                         "direct": len(direct), "lost": len(lost),
                         "later_books": len({e for e in closure(direct, deps) if events[e]["_book"] > book})})
    key_npcs.sort(key=lambda r: (-r["lost"], -r["direct"], r["npc"]))

    key_events = []
    for eid, ev in mine.items():
        after = closure({eid}, deps) - {eid}
        if not after:
            continue
        key_events.append({"id": eid, "chapter": ev["_chapter"], "tier": ev.get("tier"),
                           "dependents": len(after), "pins": sorted(pinned_npcs(ev)),
                           "hooks": len(ev.get("hooks", []))})
    key_events.sort(key=lambda r: (-r["dependents"], r["id"]))

    return {"book": book, "events": len(mine), "tiers": dict(sorted(tiers.items())),
            "roles": roles, "fallback_roles": fallback, "optional_roles": optional,
            "on_fail": dict(on_fail), "with_hooks": with_hooks, "hooks": dict(hooks),
            "pinned_events": sum(1 for ev in mine.values() if pinned_npcs(ev)),
            "single_pin_events": sum(1 for ev in mine.values() if len(pinned_npcs(ev)) == 1),
            "key_npcs": key_npcs[:top], "key_events": key_events[:top]}


def _fmt(c: dict) -> str:
    return ", ".join(f"{k} {v}" for k, v in c.items()) or "none"


def render(stats: list[dict]) -> str:
    out = ["# Divergence report (M23.0)", "",
           "Generated by `tools/divergence_report.py`. Do not edit by hand.", "",
           "- **Pinned**: the event fails if this one NPC is dead (`requires.alive`, or the only `prefer` of a "
           "required role that cannot be substituted).",
           "- **Lost**: pinned events plus the events in the same book that depend on them (`depends_on`, "
           "transitive). **Later**: lost events in later books.",
           "- **Dependents**: events (any book) that wait on this event, transitive.", "",
           "## Summary", "",
           "| Book | Events | Roles | With fallback tags | Optional | on_fail | Events with hooks | Hook kinds "
           "| Pinned events | One pin |",
           "|---|---|---|---|---|---|---|---|---|---|"]
    for s in stats:
        out.append(f"| {s['book']} | {s['events']} | {s['roles']} | {s['fallback_roles']} | {s['optional_roles']} "
                   f"| {_fmt(s['on_fail'])} | {s['with_hooks']} | {_fmt(s['hooks'])} "
                   f"| {s['pinned_events']} | {s['single_pin_events']} |")
    for s in stats:
        out += ["", f"## Book {s['book']}", "", "### Key NPC candidates", "",
                "| NPC | Id | Pinned | Lost | Later |", "|---|---|---|---|---|"]
        out += [f"| {r['name']} | `{r['npc']}` | {r['direct']} | {r['lost']} | {r['later_books']} |"
                for r in s["key_npcs"]]
        out += ["", "### Key event candidates", "",
                "| Event | Ch | Tier | Dependents | Pinned on | Hooks |", "|---|---|---|---|---|---|"]
        out += [f"| `{r['id']}` | {r['chapter']} | {r['tier']} | {r['dependents']} "
                f"| {', '.join(r['pins']) or '-'} | {r['hooks']} |" for r in s["key_events"]]
    return "\n".join(out) + "\n"


def _books(spec: str | None, have: set[int]) -> list[int]:
    if not spec:
        return sorted(have)
    lo, _, hi = spec.partition("-")
    return [b for b in range(int(lo), int(hi or lo) + 1) if b in have]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("canon_root", help="folder with book<N>/ folders, e.g. game/data/canon")
    ap.add_argument("--books", help="a book or a range, e.g. 2-7 (default: all)")
    ap.add_argument("--top", type=int, default=12, help="rows per candidate table (default 12)")
    ap.add_argument("--out", help="write the Markdown here instead of stdout")
    args = ap.parse_args(argv)
    events, npcs = load_canon(args.canon_root)
    books = _books(args.books, {ev["_book"] for ev in events.values()})
    text = render([book_stats(events, npcs, b, args.top) for b in books])
    if args.out:
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(text, encoding="utf-8")
    else:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
