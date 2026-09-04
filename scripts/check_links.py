#!/usr/bin/env python3
"""Check local HTML/CSS asset links against the generated public tree."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit

from bs4 import BeautifulSoup

ROOT_DIR = Path(__file__).resolve().parents[1]
CORE_DIR = ROOT_DIR / "vendor" / "typst-blog-core"
if str(CORE_DIR) not in sys.path:
    sys.path.insert(0, str(CORE_DIR))
from typst_blog_core.context import BlogContext
from typst_blog_core.metadata import load_site_config


def _target(public: Path, source: Path, value: str, base_path: str) -> Path | None:
    value = value.strip()
    if not value or value.startswith(("#", "mailto:", "tel:", "data:", "javascript:")):
        return None
    parsed = urlsplit(value)
    if parsed.scheme or parsed.netloc:
        return None
    path = parsed.path
    if base_path and path.startswith(base_path):
        path = path[len(base_path):]
    if path.startswith("/"):
        candidate = public / path.lstrip("/")
    else:
        candidate = source.parent / path
    if candidate.is_dir():
        candidate = candidate / "index.html"
    return candidate


def check(root: Path) -> None:
    public = root / "public"
    if not public.is_dir():
        raise AssertionError("public/ does not exist")
    site = load_site_config(BlogContext.create(root))
    base_path = urlsplit(site["base_url"]).path.rstrip("/")
    missing: list[str] = []
    for html_path in public.rglob("*.html"):
        soup = BeautifulSoup(html_path.read_text(encoding="utf-8"), "html.parser")
        for element in soup.find_all(("a", "link", "img", "script")):
            attribute = "src" if element.name in ("img", "script") else "href"
            value = element.get(attribute)
            if not value:
                continue
            candidate = _target(public, html_path, value, base_path)
            if candidate is not None and not candidate.is_file():
                missing.append(f"{html_path.relative_to(public)} -> {value}")
    for css_path in public.rglob("*.css"):
        for raw in re.findall(r"url\((?:\"|')?([^\"')]+)", css_path.read_text(encoding="utf-8")):
            candidate = _target(public, css_path, raw, base_path)
            if candidate is not None and not candidate.is_file():
                missing.append(f"{css_path.relative_to(public)} -> {raw}")
    if missing:
        raise AssertionError("Broken local links:\n" + "\n".join(missing))
    print("All generated local links resolve")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    check(args.root.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
