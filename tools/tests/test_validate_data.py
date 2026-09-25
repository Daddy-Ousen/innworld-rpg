"""Tests for tools/validate_data.py. Uses toy data (no book text).

Run: python -m unittest discover -s tools/tests
"""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import validate_data as vd  # noqa: E402


def ref(ch="9.00", conf="confirmed"):
    return {"book": 9, "chapter": ch, "confidence": conf}


NPCS = {
    "schema_version": 1,
    "npcs": {
        "alice": {"name": "Alice", "race": "Human", "tags": ["human", "cook"], "faction": None, "home": "hut",
                  "classes": [{"name": "[Cook]", "level": 3}], "alive_at_start": True, "status": "candidate",
                  "canon_ref": ref(), "summary": "A cook who lives in a hut."},
        "bob": {"name": "Bob", "race": "Drake", "tags": ["drake", "guard"], "faction": "town_watch", "home": None,
                "classes": [], "alive_at_start": True, "status": "reviewed",
                "canon_ref": ref(conf="likely"), "summary": "A guard."},
    },
}
LOCATIONS = {
    "schema_version": 1,
    "locations": {
        "plains": {"name": "The Plains", "kind": "region", "parent": None, "tags": [], "status": "candidate",
                   "canon_ref": ref(), "summary": "Grass."},
        "hut": {"name": "Hut", "kind": "building", "parent": "plains", "tags": ["shelter"], "status": "candidate",
                "canon_ref": ref(), "summary": "A hut on the plains."},
    },
}


def event(**over):
    ev = {
        "tier": 2,
        "window": {"earliest": 1, "latest": 2, "confidence": "guess"},
        "location": "hut",
        "roles": {"cook": {"prefer": ["alice"], "fallback_tags": ["cook"]}},
        "requires": {"alive": ["alice"], "flags": [], "not_flags": ["hut.burned"]},
        "depends_on": [],
        "on_fail": ["substitute", "delay", "cancel"],
        "delay_limit": 2,
        "effects": {"set_flags": ["hut.fed"], "relationship": [{"from": "alice", "to": "bob", "delta": 1}]},
        "status": "candidate",
        "canon_ref": ref(),
        "summary": "Alice cooks soup in the hut.",
    }
    ev.update(over)
    return ev


CH_900 = {"schema_version": 1, "book": 9, "chapter": "9.00",
          "events": {"b9.soup": event()},
          "system": [{"who": "alice", "kind": "level", "name": "[Cook]", "level": 3, "confidence": "confirmed"}]}
CH_901 = {"schema_version": 1, "book": 9, "chapter": "9.01",
          "events": {"b9.guard_visit": event(depends_on=["b9.soup"], canon_ref=ref("9.01"),
                                             window={"earliest": 2, "latest": 3, "confidence": "likely"},
                                             roles={"guard": {"prefer": ["bob"], "fallback_tags": ["guard"]}},
                                             requires={"alive": ["bob"], "flags": ["hut.fed"], "not_flags": []},
                                             summary="Bob visits the hut after the soup.")},
          "system": []}

RAW_INDEX = [{"order": 1, "id": "9.00", "title": "9.00", "file": "001_9-00.txt", "source": "x", "word_count": 12,
              "images_skipped": 0},
             {"order": 2, "id": "9.01", "title": "9.01", "file": "002_9-01.txt", "source": "y", "word_count": 5,
              "images_skipped": 0}]
RAW_900 = "The quick brown fox jumps over the lazy dog near the old hut.\n"


class Fixture:
    def __init__(self, tmp: Path):
        self.root = tmp / "book9"
        self.data = {"npcs.json": copy.deepcopy(NPCS), "locations.json": copy.deepcopy(LOCATIONS),
                     "chapters/9.00.json": copy.deepcopy(CH_900), "chapters/9.01.json": copy.deepcopy(CH_901)}
        self.raw = tmp / "raw9"

    def write(self, with_raw=False):
        for rel, doc in self.data.items():
            p = self.root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(json.dumps(doc), encoding="utf-8")
        if with_raw:
            self.raw.mkdir(parents=True, exist_ok=True)
            (self.raw / "index.json").write_text(json.dumps(RAW_INDEX), encoding="utf-8")
            (self.raw / "001_9-00.txt").write_text(RAW_900, encoding="utf-8")
            (self.raw / "002_9-01.txt").write_text("Bob came by later.\n", encoding="utf-8")

    def run(self, with_raw=False):
        self.write(with_raw)
        return vd.validate_dir(self.root, self.raw if with_raw else None)


class ValidateTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.fx = Fixture(Path(self._tmp.name))

    def tearDown(self):
        self._tmp.cleanup()

    def ev(self, chapter="9.00", eid="b9.soup"):
        return self.fx.data[f"chapters/{chapter}.json"]["events"][eid]

    def assertError(self, rep, fragment):
        self.assertTrue(any(fragment in e for e in rep.errors), f"no error containing {fragment!r} in {rep.errors}")

    def test_valid_data_passes(self):
        rep = self.fx.run(with_raw=True)
        self.assertEqual(rep.errors, [])

    def test_valid_data_passes_without_raw(self):
        self.assertEqual(self.fx.run().errors, [])

    def test_missing_and_unknown_keys(self):
        del self.ev()["summary"]
        self.ev()["day"] = 4
        rep = self.fx.run()
        self.assertError(rep, "missing key 'summary'")
        self.assertError(rep, "unknown key 'day'")

    def test_bad_enums(self):
        self.ev()["tier"] = 3
        self.ev()["canon_ref"]["confidence"] = "maybe"
        self.ev()["status"] = "done"
        rep = self.fx.run()
        self.assertError(rep, ".tier")
        self.assertError(rep, "canon_ref.confidence")
        self.assertError(rep, ".status")

    def test_window_order(self):
        self.ev()["window"] = {"earliest": 5, "latest": 4, "confidence": "guess"}
        self.assertError(self.fx.run(), "window.latest")

    def test_unknown_references(self):
        ev = self.ev()
        ev["location"] = "castle"
        ev["roles"]["cook"]["prefer"] = ["carol"]
        ev["effects"]["kill"] = ["dave"]
        rep = self.fx.run()
        self.assertError(rep, "unknown location 'castle'")
        self.assertError(rep, "unknown npc 'carol'")
        self.assertError(rep, "unknown npc 'dave'")

    def test_revive(self):
        ev = self.ev()
        ev["effects"]["revive"] = ["dave"]
        rep = self.fx.run()
        self.assertError(rep, "unknown npc 'dave'")
        ev["effects"]["revive"] = "bob"
        self.assertError(self.fx.run(), "effects.revive")
        ev["effects"]["kill"] = ["bob"]
        ev["effects"]["revive"] = ["bob"]
        self.assertError(self.fx.run(), "'bob' is also in kill")

    def test_unknown_system_npc(self):
        self.fx.data["chapters/9.00.json"]["system"][0]["who"] = "zed"
        self.assertError(self.fx.run(), "unknown npc 'zed'")

    def test_depends_on_unknown_and_cycle(self):
        self.ev()["depends_on"] = ["b9.guard_visit"]
        self.assertError(self.fx.run(), "depends_on cycle")
        self.ev()["depends_on"] = ["b9.nope"]
        self.assertError(self.fx.run(), "unknown event 'b9.nope'")

    def test_dependency_after_window(self):
        self.ev()["window"] = {"earliest": 10, "latest": 12, "confidence": "guess"}
        self.assertError(self.fx.run(), "can only start after")

    def test_on_fail_must_end_with_cancel_and_mutate_target_exists(self):
        self.ev()["on_fail"] = ["mutate:b9.ghost", "delay"]
        rep = self.fx.run()
        self.assertError(rep, "last step must be 'cancel'")
        self.assertError(rep, "unknown mutate target 'b9.ghost'")

    def test_event_chapter_must_match_file(self):
        self.ev()["canon_ref"]["chapter"] = "9.01"
        self.assertError(self.fx.run(), "must match the file's chapter")

    def test_duplicate_event_id_across_chapters(self):
        self.fx.data["chapters/9.01.json"]["events"]["b9.soup"] = event(canon_ref=ref("9.01"))
        self.assertError(self.fx.run(), "duplicate event id")

    def test_event_id_prefix(self):
        evs = self.fx.data["chapters/9.00.json"]["events"]
        evs["b1.wrong_book"] = evs.pop("b9.soup")
        self.fx.data["chapters/9.01.json"]["events"]["b9.guard_visit"]["depends_on"] = []
        self.assertError(self.fx.run(), "event id must look like 'b9.snake_case'")

    def test_location_parent_unknown(self):
        self.fx.data["locations.json"]["locations"]["hut"]["parent"] = "moon"
        self.assertError(self.fx.run(), "unknown location 'moon'")

    def test_summary_length(self):
        self.ev()["summary"] = "x" * (vd.SUMMARY_MAX + 1)
        self.assertError(self.fx.run(), "too long")

    def test_chapter_must_exist_in_raw_index(self):
        self.ev()["canon_ref"]["chapter"] = "9.07"
        self.fx.data["chapters/9.00.json"]["chapter"] = "9.00"
        rep = self.fx.run(with_raw=True)
        self.assertError(rep, "not in raw index.json")

    def test_copied_book_text_is_an_error(self):
        self.ev()["summary"] = "Here the quick brown fox jumps over the lazy dog again."
        rep = self.fx.run(with_raw=True)
        self.assertError(rep, "copies book text")

    def test_short_shared_phrases_are_fine(self):
        self.ev()["summary"] = "A brown fox is near the old hut."
        self.assertEqual(self.fx.run(with_raw=True).errors, [])

    def test_whole_float_numbers_are_ints(self):
        self.ev()["window"] = {"earliest": 1.0, "latest": 2.0, "confidence": "guess"}
        self.assertEqual(self.fx.run().errors, [])

    # --- M6.4 news and player hooks

    def hook(self, **over):
        h = {"id": "player_cooked", "did": [{"action": ["cook_stew"], "context": {"location": "hut"}}],
             "days": [1, 2], "then": "change", "effects": {"set_flags": ["hut.player_cooked"]},
             "news": "The soup was better today."}
        h.update(over)
        return h

    def test_news_and_hooks_pass(self):
        ev = self.ev()
        ev["news"] = "People say Alice made soup."
        ev["hooks"] = [self.hook(), self.hook(id="player_left", then="cancel", effects=None),
                       self.hook(id="player_swapped", then="mutate:b9.guard_visit", effects=None)]
        for h in ev["hooks"]:
            if h["effects"] is None:
                del h["effects"]
        ev["hooks"][2]["did"] = [{"action": ["attack_melee"], "outcome": ["success"],
                                  "context": {"enemy": ["rat", "crab"]}}]
        self.assertEqual(self.fx.run(with_raw=True).errors, [])

    def test_hook_shape_errors(self):
        self.ev()["hooks"] = [
            self.hook(days=[3, 1]),
            self.hook(id="player_cooked", then="explode"),
            self.hook(id="no_fx", effects=None),
            self.hook(id="cancel_fx", then="cancel"),
            self.hook(id="empty_did", did=[]),
            self.hook(id="bad_outcome", did=[{"action": ["cook_stew"], "outcome": ["great"]}]),
            self.hook(id="long_span", days=[1, 9]),
        ]
        del self.ev()["hooks"][2]["effects"]
        rep = self.fx.run()
        self.assertError(rep, "hooks[0].days")
        self.assertError(rep, "duplicate hook id")
        self.assertError(rep, "hooks[1].then")
        self.assertError(rep, "hooks[2]: 'change' needs effects")
        self.assertError(rep, "hooks[3]: effects only with 'change'")
        self.assertError(rep, "hooks[4].did")
        self.assertError(rep, "hooks[5].did[0].outcome")
        self.assertError(rep, "hooks[6].days: the action log keeps 7 days")

    def test_hook_references(self):
        self.ev()["hooks"] = [
            self.hook(effects={"kill": ["zed"]}),
            self.hook(id="ghost", then="mutate:b9.ghost", effects=None),
        ]
        del self.ev()["hooks"][1]["effects"]
        rep = self.fx.run()
        self.assertError(rep, "unknown npc 'zed'")
        self.assertError(rep, "unknown mutate target 'b9.ghost'")

    def test_hook_actions_checked_when_known(self):
        self.ev()["hooks"] = [self.hook(did=[{"action": ["juggle"]}])]
        self.fx.write()
        rep = vd.validate_dir(self.fx.root, None, actions={"cook_stew"})
        self.assertError(rep, "unknown action 'juggle'")
        self.assertEqual(self.fx.run().errors, [], "no action list: not checked")

    def test_hook_days_after_the_window_warn(self):
        self.ev()["hooks"] = [self.hook(days=[5, 6])]
        rep = self.fx.run()
        self.assertEqual(rep.errors, [])
        self.assertTrue(any("after the event's window" in w for w in rep.warnings), rep.warnings)

    def test_news_copy_check(self):
        self.ev()["news"] = "Here the quick brown fox jumps over the lazy dog again."
        self.ev()["hooks"] = [self.hook(news="Here the quick brown fox jumps over the lazy dog again.")]
        rep = self.fx.run(with_raw=True)
        self.assertError(rep, ".news: copies book text")
        self.assertError(rep, "hooks[0].news: copies book text")

    def test_a_hook_may_change_how_an_npc_sees_the_player(self):
        self.ev()["hooks"] = [self.hook(effects={"relationship": [{"from": "alice", "to": "player", "delta": 2}]})]
        self.assertEqual(self.fx.run().errors, [])
        self.ev()["effects"]["relationship"] = [{"from": "alice", "to": "player", "delta": 2}]
        self.assertError(self.fx.run(), "unknown npc 'player'")

    # --- M6.5 stages

    def stage(self, **over):
        st = {"area": "hut_inside", "hours": [9, 12], "foes": [{"enemy": "rat", "pos": [2, 3]}],
              "when_flags": ["hut.rats_near"], "allies": ["bob"], "line": "A rat runs in.",
              "note": "Design guess."}
        st.update(over)
        return st

    def test_a_stage_passes(self):
        self.ev()["stage"] = self.stage()
        self.assertEqual(self.fx.run(with_raw=True).errors, [])

    def test_stage_shape_errors(self):
        self.ev()["stage"] = self.stage(hours=[12, 12], foes=[{"enemy": "rat"}], allies=["zed"],
                                        unless_flags="nope")
        rep = self.fx.run()
        self.assertError(rep, "stage.hours")
        self.assertError(rep, "stage.foes[0]")
        self.assertError(rep, "stage.allies: unknown npc 'zed'")
        self.assertError(rep, "stage.unless_flags")
        self.ev()["stage"] = {"area": "hut_inside", "hours": [9, 12], "foes": [], "boss": True}
        rep = self.fx.run()
        self.assertError(rep, "stage.foes")
        self.assertError(rep, "boss")

    # --- M7.B waves

    def test_stage_waves_pass(self):
        self.ev()["stage"] = self.stage(waves=[
            {"after_seconds": 60, "left_at_most": 2, "from": [2, 3], "foes": ["rat", "rat"],
             "helpers": ["dog"], "allies": ["bob"], "line": "More rats pour in."}])
        self.assertEqual(self.fx.run(with_raw=True).errors, [])

    def test_stage_wave_errors(self):
        self.ev()["stage"] = self.stage(waves=[
            {"after_seconds": -5, "from": [2], "foes": ["rat"], "left_at_most": "x"},
            {"after_seconds": 5, "from": [2, 3]},
            {"after_seconds": 5, "from": [2, 3], "allies": ["zed"], "boss": True}])
        rep = self.fx.run()
        self.assertError(rep, "waves[0].after_seconds")
        self.assertError(rep, "waves[0].from")
        self.assertError(rep, "waves[0].left_at_most")
        self.assertError(rep, "waves[1]: needs at least one foe, helper or ally")
        self.assertError(rep, "waves[2].allies: unknown npc 'zed'")
        self.assertError(rep, "boss")

    def test_stage_wave_line_copy_check(self):
        self.ev()["stage"] = self.stage(waves=[{"after_seconds": 5, "from": [2, 3], "foes": ["rat"],
                                               "line": "Here the quick brown fox jumps over the lazy dog again."}])
        self.assertError(self.fx.run(with_raw=True), "waves[0].line: copies book text")

    def test_stage_line_copy_check(self):
        self.ev()["stage"] = self.stage(line="Here the quick brown fox jumps over the lazy dog again.")
        self.assertError(self.fx.run(with_raw=True), "stage.line: copies book text")

    def test_cli_exit_codes(self):
        self.fx.write()
        self.assertEqual(vd.main([str(self.fx.root), "--no-raw"]), 0)
        self.ev()["tier"] = 7
        self.fx.write()
        self.assertEqual(vd.main([str(self.fx.root), "--no-raw"]), 1)



def earlier_book():
    """A valid book8 folder: book9 data may use its ids (M8.0)."""
    r8 = {"book": 8, "chapter": "8.00", "confidence": "confirmed"}
    ev = event(location="field", roles={"farmer": {"prefer": ["carl"], "fallback_tags": []}},
               requires={"alive": ["carl"], "flags": [], "not_flags": []},
               effects={"set_flags": ["field.harvested"]}, canon_ref=r8, summary="Carl brings in the harvest.")
    return {
        "npcs.json": {"schema_version": 1, "npcs": {
            "carl": {"name": "Carl", "race": "Human", "tags": ["human"], "faction": None, "home": "field",
                     "classes": [], "alive_at_start": True, "status": "reviewed", "canon_ref": r8,
                     "summary": "A farmer."}}},
        "locations.json": {"schema_version": 1, "locations": {
            "field": {"name": "Field", "kind": "region", "parent": None, "tags": [], "status": "reviewed",
                      "canon_ref": r8, "summary": "A wheat field."}}},
        "chapters/8.00.json": {"schema_version": 1, "book": 8, "chapter": "8.00",
                               "events": {"b8.harvest": ev}, "system": []},
    }


class CrossBookTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)
        self.fx = Fixture(self.tmp)
        for rel, doc in earlier_book().items():
            p = self.tmp / "book8" / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(json.dumps(doc), encoding="utf-8")
        ev = self.fx.data["chapters/9.01.json"]["events"]["b9.guard_visit"]
        ev["location"] = "field"
        ev["roles"]["farmer"] = {"prefer": ["carl"], "fallback_tags": []}
        ev["depends_on"] = ["b9.soup", "b8.harvest"]
        ev["on_fail"] = ["substitute", "mutate:b8.harvest", "cancel"]
        self.fx.data["npcs.json"]["npcs"]["alice"]["home"] = "field"

    def tearDown(self):
        self._tmp.cleanup()

    def run_known(self):
        self.fx.write()
        return vd.validate_dir(self.fx.root, None, None, vd.load_known(self.tmp, 9))

    def assertError(self, rep, fragment):
        self.assertTrue(any(fragment in e for e in rep.errors), f"no error containing {fragment!r} in {rep.errors}")

    def test_load_known_reads_earlier_books_only(self):
        k = vd.load_known(self.tmp, 9)
        self.assertEqual(set(k.npcs), {"carl"})
        self.assertEqual(set(k.locations), {"field"})
        self.assertEqual(set(k.events), {"b8.harvest"})
        self.assertEqual(vd.load_known(self.tmp, 8).npcs, {})

    def test_earlier_ids_are_known(self):
        self.assertEqual(self.run_known().errors, [])

    def test_alone_the_earlier_ids_are_unknown(self):
        self.fx.write()
        rep = vd.validate_dir(self.fx.root)
        self.assertError(rep, "unknown npc 'carl'")
        self.assertError(rep, "unknown location 'field'")
        self.assertError(rep, "unknown event 'b8.harvest'")
        self.assertError(rep, "unknown mutate target 'b8.harvest'")

    def test_still_unknown_ids_fail(self):
        self.fx.data["chapters/9.01.json"]["events"]["b9.guard_visit"]["depends_on"] = ["b8.nothing"]
        self.assertError(self.run_known(), "unknown event 'b8.nothing'")

    def test_earlier_window_is_checked(self):
        ev = self.fx.data["chapters/9.01.json"]["events"]["b9.guard_visit"]
        ev["window"] = {"earliest": 0, "latest": 0, "confidence": "guess"}
        self.assertError(self.run_known(), "'b8.harvest' can only start after this event's window ends")

    def test_redefining_an_earlier_id_fails(self):
        self.fx.data["npcs.json"]["npcs"]["carl"] = copy.deepcopy(NPCS["npcs"]["bob"])
        self.fx.data["locations.json"]["locations"]["field"] = copy.deepcopy(LOCATIONS["locations"]["plains"])
        rep = self.run_known()
        self.assertError(rep, "npcs.carl: duplicate id (also in book8)")
        self.assertError(rep, "locations.field: duplicate id (also in book8)")

    def test_cli_loads_earlier_books_and_all(self):
        self.fx.write()
        self.assertEqual(vd.main([str(self.fx.root), "--no-raw"]), 0)
        self.assertEqual(vd.main([str(self.fx.root), "--no-raw", "--no-earlier"]), 1)
        self.assertEqual(vd.main([str(self.tmp), "--all", "--no-raw"]), 0)
        self.ev_bad()
        self.assertEqual(vd.main([str(self.tmp), "--all", "--no-raw"]), 1)

    def ev_bad(self):
        self.fx.data["chapters/9.00.json"]["events"]["b9.soup"]["tier"] = 7
        self.fx.write()


if __name__ == "__main__":
    unittest.main()
