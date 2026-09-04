#!/usr/bin/env python3
"""Compile every post to PDF and publish only non-draft PDFs."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
CORE_DIR = ROOT_DIR / "vendor" / "typst-blog-core"
if str(CORE_DIR) not in sys.path:
    sys.path.insert(0, str(CORE_DIR))

from typst_blog_core.context import BlogContext
from typst_blog_core.metadata import (
    POST_METADATA_LABEL,
    discover_post_files,
    eval_metadata_values,
    load_site_config,
    parse_calver,
    resolve_posts_dir,
    validate_post_slug,
)


ASCII_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def validate_ascii_slug(slug: object) -> str:
    if not isinstance(slug, str) or ASCII_SLUG.fullmatch(slug) is None:
        raise ValueError(f"slug must match {ASCII_SLUG.pattern}")
    return slug


def _metadata(context: BlogContext, source: Path) -> dict:
    values = eval_metadata_values(
        context,
        str(source.relative_to(context.root_dir)),
        POST_METADATA_LABEL,
    )
    if len(values) != 1:
        raise ValueError(f"{source}: expected exactly one <post-meta> value")
    value = values[0]
    if not isinstance(value, dict):
        raise ValueError(f"{source}: post metadata must be a dictionary")
    return value


def discover(context: BlogContext) -> list[tuple[Path, dict]]:
    site = load_site_config(context)
    posts_dir = resolve_posts_dir(context, site)
    records: list[tuple[Path, dict]] = []
    seen: set[str] = set()
    for source in discover_post_files(context, posts_dir):
        meta = _metadata(context, source)
        slug = meta.get("slug")
        try:
            validate_post_slug(slug)
        except ValueError as exc:
            raise ValueError(f"{source}: {exc}") from exc
        try:
            validate_ascii_slug(slug)
        except ValueError as exc:
            raise ValueError(f"{source}: {exc}") from exc
        if source.parent.name != slug:
            raise ValueError(f"{source}: directory name must equal slug {slug!r}")
        if slug in seen:
            raise ValueError(f"duplicate post slug: {slug}")
        seen.add(slug)
        if not meta.get("title") or not meta.get("pdf-title"):
            raise ValueError(f"{source}: title and pdf-title are required")
        if parse_calver(meta.get("create")) is None:
            raise ValueError(f"{source}: create is required")
        if not meta.get("description"):
            raise ValueError(f"{source}: description is required")
        if not isinstance(meta.get("draft", True), bool):
            raise ValueError(f"{source}: draft must be true or false")
        authors = meta.get("authors", ())
        if not isinstance(authors, (list, tuple)) or not authors:
            raise ValueError(f"{source}: authors must contain at least one author")
        records.append((source, meta))
    return records


def _compile(source: Path, destination: Path, root: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "typst",
            "compile",
            "--root",
            str(root),
            str(source.relative_to(root)),
            str(destination),
        ],
        cwd=root,
        check=True,
    )


def build(root: Path, mode: str) -> list[str]:
    context = BlogContext.create(root)
    records = discover(context)
    published: list[str] = []
    with tempfile.TemporaryDirectory(prefix="rin-blog-pdf-") as temporary:
        temporary_root = Path(temporary)
        for source, meta in records:
            slug = meta["slug"]
            validation_pdf = temporary_root / slug / "post.pdf"
            _compile(source, validation_pdf, root)
            if mode == "production" and not meta.get("draft", True):
                output = root / "public" / slug / "post.pdf"
                output.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(validation_pdf, output)
                published.append(slug)

    if mode == "production":
        for source, meta in records:
            output = root / "public" / meta["slug"] / "post.pdf"
            if meta.get("draft", True):
                if output.exists():
                    raise ValueError(f"draft PDF exists under public: {output}")
            elif not output.is_file() or output.stat().st_size == 0:
                raise ValueError(f"published PDF is missing or empty: {output}")
    return published


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("validation", "production"), default="validation")
    parser.add_argument("--root", type=Path, default=ROOT_DIR)
    args = parser.parse_args()
    published = build(args.root.resolve(), args.mode)
    print(f"Compiled PDFs for {len(published) if args.mode == 'production' else 'all'} posts ({args.mode})")
    if args.mode == "production":
        print("Published PDFs: " + (", ".join(published) if published else "none"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
