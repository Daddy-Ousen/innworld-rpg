"""Tests for tools/extract_epub.py. Uses a tiny synthetic epub (no book text).

Run: python -m unittest discover -s tools/tests
"""

import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import extract_epub as ee  # noqa: E402

CONTAINER = """<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>"""

OPF = """<?xml version="1.0" encoding="utf-8"?><package xmlns="http://www.idpf.org/2007/opf" version="2.0">
<manifest>
<item href="Text/Cover.xhtml" id="cover" media-type="application/xhtml+xml"/>
<item href="Text/a.xhtml" id="a" media-type="application/xhtml+xml"/>
<item href="Text/b.xhtml" id="b" media-type="application/xhtml+xml"/>
<item href="Text/c.xhtml" id="c" media-type="application/xhtml+xml"/>
<item href="Images/pic.png" id="pic" media-type="image/png"/>
<item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>
</manifest>
<spine toc="ncx"><itemref idref="cover"/><itemref idref="a"/><itemref idref="b"/><itemref idref="c"/></spine></package>"""

NCX = """<?xml version="1.0" encoding="utf-8"?><ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<navMap>
<navPoint id="n1" playOrder="1"><navLabel><text>9.00</text></navLabel><content src="Text/a.xhtml"/></navPoint>
<navPoint id="n2" playOrder="2"><navLabel><text>Interlude – Test Things</text></navLabel><content src="Text/b.xhtml"/></navPoint>
<navPoint id="n3" playOrder="3"><navLabel><text>9.01 R</text></navLabel><content src="Text/c.xhtml"/></navPoint>
</navMap></ncx>"""

HEAD = '<?xml version="1.0" encoding="utf-8"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>T</title></head><body>'
IMG = ('<div class="svg_outer svg_inner"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
       '<image xlink:href="../Images/pic.png" width="10" height="10"/><desc>https://example.com/pic.png</desc></svg></div>')

COVER = HEAD + IMG + "</body></html>"
CH_A = (HEAD + "<h1>9.00</h1><p>Alpha beta\n gamma.</p><p> </p><p>Second <em>line</em> here.</p>"
        + IMG + '<p></p><p style="text-align: center"><em>Pic</em> by <a href="https://example.com">Artist</a></p></body></html>')
CH_B = HEAD + "<p>One two three four.</p>" + IMG + '<p>After the picture.</p></body></html>'
CH_C = HEAD + "<p>[Skill – Test obtained!]</p></body></html>"


def make_epub(path: Path) -> None:
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("mimetype", "application/epub+zip")
        z.writestr("META-INF/container.xml", CONTAINER)
        z.writestr("OEBPS/content.opf", OPF)
        z.writestr("OEBPS/toc.ncx", NCX)
        z.writestr("OEBPS/Text/Cover.xhtml", COVER)
        z.writestr("OEBPS/Text/a.xhtml", CH_A)
        z.writestr("OEBPS/Text/b.xhtml", CH_B)
        z.writestr("OEBPS/Text/c.xhtml", CH_C)
        z.writestr("OEBPS/Images/pic.png", b"\x89PNG fake")


class ChapterIdTest(unittest.TestCase):
    def test_ids(self):
        self.assertEqual(ee.chapter_id("1.00"), "1.00")
        self.assertEqual(ee.chapter_id("1.19 R"), "1.19R")
        self.assertEqual(ee.chapter_id("Interlude – The Great Ritual"), "interlude_the_great_ritual")
        self.assertEqual(ee.file_slug("1.19R"), "1-19R")


class ParseChapterTest(unittest.TestCase):
    def test_drops_heading_images_captions_and_blank_paragraphs(self):
        headings, paras, images = ee.parse_chapter(CH_A)
        self.assertEqual(headings, ["9.00"])
        self.assertEqual(paras, ["Alpha beta gamma.", "Second line here."])
        self.assertEqual(images, 1)

    def test_keeps_centred_text_that_is_not_right_after_an_image_credit(self):
        _, paras, _ = ee.parse_chapter(HEAD + '<p style="text-align: center">Keep me.</p></body></html>')
        self.assertEqual(paras, ["Keep me."])

    def test_no_image_url_leaks_and_story_text_after_image_is_kept(self):
        _, paras, _ = ee.parse_chapter(CH_B)
        self.assertEqual(paras, ["One two three four.", "After the picture."])


class ExtractTest(unittest.TestCase):
    def test_extract_writes_files_and_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            epub = tmp / "book.epub"
            make_epub(epub)
            index = ee.extract(epub, tmp / "out")

            self.assertEqual([c["id"] for c in index], ["9.00", "interlude_test_things", "9.01R"])
            self.assertEqual([c["order"] for c in index], [1, 2, 3])
            self.assertEqual(index[0]["file"], "001_9-00.txt")
            self.assertEqual(index[0]["word_count"], 6)
            self.assertEqual(index[0]["images_skipped"], 1)

            on_disk = json.loads((tmp / "out" / "index.json").read_text(encoding="utf-8"))
            self.assertEqual(on_disk, index)
            text = (tmp / "out" / "001_9-00.txt").read_text(encoding="utf-8")
            self.assertEqual(text, "Alpha beta gamma.\n\nSecond line here.\n")
            self.assertEqual((tmp / "out" / "003_9-01R.txt").read_text(encoding="utf-8"), "[Skill – Test obtained!]\n")

    def test_same_input_same_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            make_epub(tmp / "b.epub")
            self.assertEqual(ee.extract(tmp / "b.epub", tmp / "o1"), ee.extract(tmp / "b.epub", tmp / "o2"))


if __name__ == "__main__":
    unittest.main()
