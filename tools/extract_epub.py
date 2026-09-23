"""Split a Wandering Inn epub into plain-text chapter files.

Usage (PowerShell, from repo root):
    python tools/extract_epub.py "The Wandering Inn Books 1-17 Pirateaba/Book 1 - The Wandering Inn.epub" canon/raw/book1

Output:
    <out_dir>/NNN_<chapter-slug>.txt   one file per chapter, paragraphs split by a blank line
    <out_dir>/index.json               [{order, id, title, file, source, word_count, images_skipped}]

Images (svg/<image>/<img>) and their art-credit captions are skipped.
The cover page and other spine items with no text are skipped.
Stdlib only. The output is copyrighted text: canon/raw/ is gitignored.
"""

from __future__ import annotations

import argparse
import json
import posixpath
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from html.parser import HTMLParser
from pathlib import Path

NS = {
    "c": "urn:oasis:names:tc:opendocument:xmlns:container",
    "opf": "http://www.idpf.org/2007/opf",
    "ncx": "http://www.daisy.org/z3986/2005/ncx/",
}

# Tags whose content is never text we want.
SKIP_TAGS = {"head", "script", "style", "svg", "title"}
# Tags that end a paragraph.
BLOCK_TAGS = {"p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "li", "blockquote", "br", "hr", "tr"}
HEADING_TAGS = {"h1", "h2", "h3", "h4", "h5", "h6"}
IMAGE_TAGS = {"img", "image"}


class _ChapterParser(HTMLParser):
    """Collects paragraphs from one xhtml chapter. Drops images and their captions."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.paragraphs: list[str] = []
        self.headings: list[str] = []
        self.images = 0
        self._buf: list[str] = []
        self._skip_depth = 0
        self._in_heading = False
        self._after_image = False  # next centred <p> is an art credit
        self._in_caption = False

    # --- helpers
    def _flush(self) -> None:
        text = " ".join("".join(self._buf).split())
        self._buf = []
        if not text:
            return
        # Empty paragraphs between an image and its caption do not count.
        self._after_image = False
        if self._in_caption:
            return
        if self._in_heading:
            self.headings.append(text)
        else:
            self.paragraphs.append(text)

    # --- HTMLParser hooks
    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag in IMAGE_TAGS:
            self.images += 1
            self._after_image = True
            return
        if tag in SKIP_TAGS:
            if tag == "svg":
                self._after_image = True
            self._skip_depth += 1
            return
        if self._skip_depth:
            return
        if tag in BLOCK_TAGS:
            self._flush()
        if tag in HEADING_TAGS:
            self._in_heading = True
        if tag == "p":
            style = (dict(attrs).get("style") or "").replace(" ", "").lower()
            self._in_caption = self._after_image and "text-align:center" in style

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag.lower() in SKIP_TAGS:
            self.handle_endtag(tag)

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag in SKIP_TAGS:
            self._skip_depth = max(0, self._skip_depth - 1)
            return
        if self._skip_depth:
            return
        if tag in BLOCK_TAGS:
            self._flush()
        if tag in HEADING_TAGS:
            self._in_heading = False
        if tag == "p":
            self._in_caption = False

    def handle_data(self, data):
        if not self._skip_depth:
            self._buf.append(data)

    def close(self):
        super().close()
        self._flush()


def parse_chapter(xhtml: str) -> tuple[list[str], list[str], int]:
    """Returns (headings, paragraphs, image_count)."""
    p = _ChapterParser()
    p.feed(xhtml)
    p.close()
    return p.headings, p.paragraphs, p.images


def chapter_id(title: str) -> str:
    """'1.00' -> '1.00', '1.19 R' -> '1.19R', 'Interlude – The Great Ritual' -> 'interlude_the_great_ritual'."""
    t = title.strip()
    m = re.fullmatch(r"(\d+\.\d+)\s*([A-Za-z]*)", t)
    if m:
        return m.group(1) + m.group(2).upper()
    slug = re.sub(r"[^a-z0-9]+", "_", t.lower()).strip("_")
    return slug or "untitled"


def file_slug(cid: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]+", "-", cid)


def word_count(paragraphs: list[str]) -> int:
    return sum(len(p.split()) for p in paragraphs)


def _read_xml(z: zipfile.ZipFile, name: str) -> ET.Element:
    return ET.fromstring(z.read(name))


def read_book(epub_path: str | Path) -> list[dict]:
    """Returns chapters in spine order: {id, title, source, paragraphs, images_skipped}."""
    with zipfile.ZipFile(epub_path) as z:
        container = _read_xml(z, "META-INF/container.xml")
        rootfile = container.find(".//c:rootfile", NS)
        if rootfile is None:
            raise ValueError("container.xml has no rootfile")
        opf_path = rootfile.attrib["full-path"]
        opf_dir = posixpath.dirname(opf_path)
        opf = _read_xml(z, opf_path)

        manifest = {}
        for item in opf.findall(".//opf:manifest/opf:item", NS):
            manifest[item.attrib["id"]] = {
                "href": posixpath.normpath(posixpath.join(opf_dir, item.attrib["href"])),
                "type": item.attrib.get("media-type", ""),
            }

        # Titles from the NCX table of contents, keyed by file path.
        toc_titles: dict[str, str] = {}
        spine = opf.find(".//opf:spine", NS)
        ncx_id = spine.attrib.get("toc") if spine is not None else None
        if ncx_id and ncx_id in manifest:
            ncx = _read_xml(z, manifest[ncx_id]["href"])
            ncx_dir = posixpath.dirname(manifest[ncx_id]["href"])
            for nav in ncx.iter(f"{{{NS['ncx']}}}navPoint"):
                label = nav.find("ncx:navLabel/ncx:text", NS)
                content = nav.find("ncx:content", NS)
                if label is None or content is None:
                    continue
                src = content.attrib["src"].split("#", 1)[0]
                href = posixpath.normpath(posixpath.join(ncx_dir, src))
                toc_titles.setdefault(href, (label.text or "").strip())

        chapters = []
        for ref in spine.findall("opf:itemref", NS) if spine is not None else []:
            item = manifest.get(ref.attrib["idref"])
            if not item or "html" not in item["type"]:
                continue
            xhtml = z.read(item["href"]).decode("utf-8")
            headings, paragraphs, images = parse_chapter(xhtml)
            if not paragraphs:
                continue  # cover or image-only page
            title = toc_titles.get(item["href"]) or (headings[0] if headings else posixpath.basename(item["href"]))
            chapters.append({
                "id": chapter_id(title),
                "title": title,
                "source": item["href"],
                "paragraphs": paragraphs,
                "images_skipped": images,
            })
    return chapters


def extract(epub_path: str | Path, out_dir: str | Path) -> list[dict]:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    index = []
    seen: set[str] = set()
    for order, ch in enumerate(read_book(epub_path), start=1):
        cid = ch["id"]
        if cid in seen:
            raise ValueError(f"duplicate chapter id {cid!r}")
        seen.add(cid)
        fname = f"{order:03d}_{file_slug(cid)}.txt"
        (out / fname).write_text("\n\n".join(ch["paragraphs"]) + "\n", encoding="utf-8", newline="\n")
        index.append({
            "order": order,
            "id": cid,
            "title": ch["title"],
            "file": fname,
            "source": ch["source"],
            "word_count": word_count(ch["paragraphs"]),
            "images_skipped": ch["images_skipped"],
        })
    (out / "index.json").write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    return index


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("epub", help="path to the .epub file")
    ap.add_argument("out_dir", help="output folder, e.g. canon/raw/book1")
    args = ap.parse_args(argv)
    index = extract(args.epub, args.out_dir)
    words = sum(c["word_count"] for c in index)
    images = sum(c["images_skipped"] for c in index)
    print(f"{len(index)} chapters, {words} words, {images} images skipped -> {args.out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
