from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator, Sequence


ROOT_DIR = Path(__file__).resolve().parent
CORE_DIR = ROOT_DIR / "vendor" / "typst-blog-core"
CORE_PACKAGE = CORE_DIR / "typst_blog_core"
ASCII_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def _parse_slug(value: str) -> str:
    if ASCII_SLUG.fullmatch(value) is None:
        raise argparse.ArgumentTypeError(
            "post slug must match ^[a-z0-9]+(?:-[a-z0-9]+)*$"
        )
    return value


def _parse_date(value: str) -> dt.date:
    try:
        return dt.date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("date must use YYYY-MM-DD") from exc


def _parse_course(value: str) -> str:
    course = value.strip()
    if not course:
        raise argparse.ArgumentTypeError("course must not be empty")
    return course


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create, build, and preview a Typst blog.",
        allow_abbrev=False,
    )
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("build", help="build the deployable site")
    subparsers.add_parser(
        "preview",
        help="build, serve, watch, and live-reload locally",
    )

    new_parser = subparsers.add_parser("new", help="create a new post")
    new_parser.add_argument(
        "slug",
        type=_parse_slug,
        help="lowercase ASCII URL slug and directory name",
    )
    new_parser.add_argument("--title", required=True, help="post title")
    new_parser.add_argument(
        "--description",
        required=True,
        help="short post description",
    )
    new_parser.add_argument(
        "--course",
        type=_parse_course,
        help="course/category prefix for web titles",
    )
    new_parser.add_argument(
        "--tag",
        action="append",
        default=[],
        help="post tag; repeat this option for multiple tags",
    )
    new_parser.add_argument(
        "--date",
        type=_parse_date,
        help="creation date in YYYY-MM-DD (default: today)",
    )
    new_parser.add_argument(
        "--publish",
        action="store_true",
        help="create as published instead of the safer draft default",
    )
    return parser


def _core_new_arguments(args: argparse.Namespace) -> list[str]:
    arguments = [
        "new",
        args.slug,
        "--title",
        args.title,
        "--description",
        args.description,
    ]
    for tag in args.tag:
        arguments.extend(("--tag", tag))
    if args.date is not None:
        arguments.extend(("--date", args.date.isoformat()))
    if args.publish:
        arguments.append("--publish")
    return arguments


@contextmanager
def _course_post_source(course: str) -> Iterator[None]:
    """Temporarily add course metadata to core-generated post sources."""
    from typst_blog_core import new_post
    from typst_blog_core.metadata import typst_string

    original = new_post._post_source

    def post_source_with_course(*args: object, **kwargs: object) -> str:
        source = original(*args, **kwargs)
        if re.search(r"(?m)^  course:", source):
            return source
        title_line = re.search(r"(?m)^  title: .*\n", source)
        if title_line is None:
            raise RuntimeError("core post template does not expose a title field")
        course_line = f"  course: {typst_string(course)},\n"
        return source[: title_line.end()] + course_line + source[title_line.end() :]

    new_post._post_source = post_source_with_course
    try:
        yield
    finally:
        new_post._post_source = original


def _load_core_main():
    if not CORE_PACKAGE.is_dir():
        raise SystemExit(
            "typst-blog-core submodule is missing. "
            "Run: git submodule update --init --recursive"
        )
    sys.path.insert(0, str(CORE_DIR))
    # Typst 0.15 accepts ISO 639 language codes for `text(lang: ...)`, while
    # the site's HTML locale is the more precise `zh-CN`. User-owned copies of
    # the four page entrypoints use `zh` for typography and still emit
    # `lang="zh-CN"` from the core page layout. Generated tag pages are built
    # by the pinned Python engine, so redirect their imports to those copies.
    from typst_blog_core import builder

    tag_page = builder._tag_page_content
    tags_index = builder._tags_index_content

    def _user_tag_page_content(*args, **kwargs):
        return tag_page(*args, **kwargs).replace(
            '"/vendor/typst-blog-core/typst/core/tag.typ"',
            '"/typst/core/tag.typ"',
        )

    def _user_tags_index_content(*args, **kwargs):
        return tags_index(*args, **kwargs).replace(
            '"/vendor/typst-blog-core/typst/core/tags-index.typ"',
            '"/typst/core/tags-index.typ"',
        )

    builder._tag_page_content = _user_tag_page_content
    builder._tags_index_content = _user_tags_index_content

    from typst_blog_core.cli import main

    return main


def main(
    argv: Sequence[str] | None = None,
    *,
    root_dir: Path | str | None = None,
) -> int:
    args = _parser().parse_args(argv)
    effective_root = ROOT_DIR if root_dir is None else root_dir
    core_main = _load_core_main()

    command = args.command or "build"
    if command == "new":
        delegated_arguments = _core_new_arguments(args)
        if args.course is None:
            return core_main(argv=delegated_arguments, root_dir=effective_root)
        with _course_post_source(args.course):
            return core_main(argv=delegated_arguments, root_dir=effective_root)
    return core_main(argv=[command], root_dir=effective_root)


if __name__ == "__main__":
    raise SystemExit(main())
