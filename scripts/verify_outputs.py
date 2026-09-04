#!/usr/bin/env python3
"""Verify generated HTML/PDF structure and publication boundaries."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from bs4 import BeautifulSoup
from pypdf import PdfReader

from build_pdfs import discover
from typst_blog_core.context import BlogContext
from typst_blog_core.metadata import load_site_config


def _json_ld(soup: BeautifulSoup) -> dict:
    script = soup.select_one('script[type="application/ld+json"]')
    if script is None or not script.string:
        raise AssertionError("article JSON-LD is missing")
    value = json.loads(script.string)
    if not isinstance(value, dict):
        raise AssertionError("article JSON-LD must be an object")
    return value


def verify(root: Path, production: bool) -> None:
    context = BlogContext.create(root)
    site = load_site_config(context)
    base_url = site["base_url"]
    records = discover(context)
    public = root / "public"
    if not public.is_dir():
        raise AssertionError("public/ does not exist")

    published = {meta["slug"]: meta for _, meta in records if not meta.get("draft", True)}
    drafts = {meta["slug"]: meta for _, meta in records if meta.get("draft", True)}

    for slug, meta in published.items():
        html_path = public / slug / "index.html"
        pdf_path = public / slug / "post.pdf"
        if not html_path.is_file() or html_path.stat().st_size == 0:
            raise AssertionError(f"published HTML is missing or empty: {html_path}")
        if not pdf_path.is_file() or pdf_path.stat().st_size == 0:
            raise AssertionError(f"published PDF is missing or empty: {pdf_path}")

        soup = BeautifulSoup(html_path.read_text(encoding="utf-8"), "html.parser")
        if soup.html is None or soup.html.get("lang") != "zh-CN":
            raise AssertionError(f"{html_path}: expected <html lang=\"zh-CN\">")
        title = meta["title"]
        if soup.title is None or soup.title.get_text(strip=True) != title:
            raise AssertionError(f"{html_path}: combined title missing from <title>")
        h1 = soup.select_one("h1#article-title")
        if h1 is None or h1.get_text(" ", strip=True) != title:
            raise AssertionError(f"{html_path}: combined title missing from article H1")
        og_title = soup.select_one('meta[property="og:title"]')
        if og_title is None or og_title.get("content") != title:
            raise AssertionError(f"{html_path}: combined Open Graph title missing")
        if _json_ld(soup).get("headline") != title:
            raise AssertionError(f"{html_path}: combined JSON-LD headline missing")
        link = soup.select_one(".article-meta a.pdf-download")
        if link is None or link.get("href") != "post.pdf" or link.get_text(strip=True) != "下载 PDF":
            raise AssertionError(f"{html_path}: localized relative PDF link is missing")

        reader = PdfReader(str(pdf_path))
        if len(reader.pages) < 1:
            raise AssertionError(f"{pdf_path}: PDF has no pages")
        metadata = reader.metadata or {}
        if metadata.get("/Title") != meta.get("pdf-title"):
            raise AssertionError(f"{pdf_path}: PDF title metadata does not match pdf-title")

    for slug in drafts:
        if (public / slug).exists():
            raise AssertionError(f"draft output leaked into public/: {slug}")

    if production:
        if not (public / "feed.xml").is_file() or not (public / "sitemap.xml").is_file():
            raise AssertionError("RSS feed or sitemap is missing")
        for path in (public / "feed.xml", public / "sitemap.xml"):
            text = path.read_text(encoding="utf-8")
            if base_url not in text:
                raise AssertionError(f"{path}: configured base URL is missing")
        pagefind = public / "pagefind"
        if not pagefind.is_dir() or not any(path.is_file() and path.stat().st_size for path in pagefind.rglob("*")):
            raise AssertionError("Pagefind output is missing or empty")

    print(f"Verified {len(published)} published and {len(drafts)} draft posts")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--production", action="store_true")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    verify(args.root.resolve(), args.production)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
