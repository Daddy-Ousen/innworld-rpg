"""Tests for tools/divergence_report.py. Uses toy data (no book text).

Run: python -m unittest discover -s tools/tests
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import divergence_report as dr  # noqa: E402


def ev(alive=(), roles=None, deps=(), on_fail=("cancel",), hooks=None):
    e = {"tier": 2, "roles": roles or {}, "requires": {"alive": list(alive)},
         "depends_on": list(deps), "on_fail": list(on_fail)}
    if hooks:
        e["hooks"] = hooks
    return e


def role(*prefer, tags=(), optional=False):
    return {"prefer": list(prefer), "fallback_tags": list(tags), "optional": optional}


class PinTests(unittest.TestCase):
    def test_alive_pins_but_player_does_not(self):
        self.assertEqual(dr.pinned_npcs(ev(alive=["alice", "player"])), {"alice"})

    def test_single_prefer_required_role_pins(self):
        self.assertEqual(dr.pinned_npcs(ev(roles={"cook": role("alice")})), {"alice"})

    def test_optional_or_two_prefers_do_not_pin(self):
        e = ev(roles={"a": role("alice", optional=True), "b": role("bob", "carl")})
        self.assertEqual(dr.pinned_npcs(e), set())

    def test_substitute_with_tags_unpins(self):
        e = ev(roles={"cook": role("alice", tags=["cook"])}, on_fail=["substitute", "cancel"])
        self.assertEqual(dr.pinned_npcs(e), set())
        # Tags without a substitute step do not help.
        self.assertEqual(dr.pinned_npcs(ev(roles={"cook": role("alice", tags=["cook"])})), {"alice"})


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.root = root
        chapters = {
            1: {"1.01": {"b1.a": ev(alive=["alice"]), "b1.b": ev(deps=["b1.a"])}},
            2: {"2.01": {"b2.c": ev(deps=["b1.b"], hooks=[{"then": "change"}, {"then": "mutate:b2.d"}]),
                         "b2.d": ev(roles={"x": role("bob")}, on_fail=["delay", "cancel"])}},
        }
        for book, chs in chapters.items():
            d = root / f"book{book}" / "chapters"
            d.mkdir(parents=True)
            (root / f"book{book}" / "npcs.json").write_text(json.dumps(
                {"npcs": {"alice": {"name": "Alice"}} if book == 1 else {"bob": {"name": "Bob"}}}))
            for ch, events in chs.items():
                (d / f"{ch}.json").write_text(json.dumps({"book": book, "chapter": ch, "events": events}))

    def tearDown(self):
        self.tmp.cleanup()

    def test_cascade_counts_same_book_and_later(self):
        events, npcs = dr.load_canon(self.root)
        s = dr.book_stats(events, npcs, 1, 10)
        alice = s["key_npcs"][0]
        self.assertEqual((alice["name"], alice["direct"], alice["lost"], alice["later_books"]), ("Alice", 1, 2, 1))
        self.assertEqual(s["key_events"][0], {"id": "b1.a", "chapter": "1.01", "tier": 2, "dependents": 2,
                                              "pins": ["alice"], "hooks": 0})

    def test_counts_on_fail_and_hook_kinds(self):
        events, npcs = dr.load_canon(self.root)
        s = dr.book_stats(events, npcs, 2, 10)
        self.assertEqual(s["on_fail"], {"cancel": 2, "delay": 1})
        self.assertEqual(s["hooks"], {"change": 1, "mutate": 1})
        self.assertEqual((s["with_hooks"], s["pinned_events"], s["single_pin_events"]), (1, 1, 1))

    def test_main_writes_markdown_for_a_range(self):
        out = self.root / "r.md"
        self.assertEqual(dr.main([str(self.root), "--books", "2", "--out", str(out)]), 0)
        text = out.read_text(encoding="utf-8")
        self.assertIn("## Book 2", text)
        self.assertNotIn("## Book 1", text)
        self.assertIn("| Bob | `bob` | 1 | 1 | 0 |", text)


if __name__ == "__main__":
    unittest.main()
