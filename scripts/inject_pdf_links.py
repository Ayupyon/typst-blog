#!/usr/bin/env python3
"""Add static, relative PDF links to generated article metadata blocks."""

from __future__ import annotations

import argparse
from pathlib import Path

from bs4 import BeautifulSoup

from build_pdfs import discover
from typst_blog_core.context import BlogContext


def inject(root: Path) -> None:
    context = BlogContext.create(root)
    for source, meta in discover(context):
        slug = meta["slug"]
        html_path = root / "public" / slug / "index.html"
        pdf_path = root / "public" / slug / "post.pdf"
        if meta.get("draft", True):
            if html_path.exists() or pdf_path.exists():
                raise ValueError(f"draft output exists under public: {slug}")
            continue
        if not html_path.is_file():
            raise FileNotFoundError(f"published HTML is missing: {html_path}")
        if not pdf_path.is_file() or pdf_path.stat().st_size == 0:
            raise FileNotFoundError(f"published PDF is missing: {pdf_path}")

        soup = BeautifulSoup(html_path.read_text(encoding="utf-8"), "html.parser")
        metadata = soup.select_one(".article-meta")
        if metadata is None:
            raise ValueError(f"article metadata block is missing: {html_path}")
        existing = metadata.select_one("a.pdf-download")
        if existing is None:
            wrapper = soup.new_tag("div", attrs={"class": "meta-pdf"})
            link = soup.new_tag("a", attrs={"class": "pdf-download", "href": "post.pdf"})
            link.string = "下载 PDF"
            wrapper.append(link)
            metadata.append(wrapper)
            html_path.write_text(str(soup), encoding="utf-8")
        elif existing.get("href") != "post.pdf" or existing.get_text(strip=True) != "下载 PDF":
            raise ValueError(f"unexpected PDF link in {html_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    inject(args.root.resolve())
    print("Injected localized PDF links")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
