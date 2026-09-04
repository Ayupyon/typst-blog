from __future__ import annotations

import sys
import re
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent
CORE_DIR = ROOT_DIR / "vendor" / "typst-blog-core"
CORE_PACKAGE = CORE_DIR / "typst_blog_core"
ASCII_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


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


def main() -> int:
    arguments = sys.argv[1:]
    if arguments and arguments[0] == "new" and len(arguments) > 1:
        slug = arguments[1]
        if ASCII_SLUG.fullmatch(slug) is None:
            raise SystemExit(
                "post slug must match ^[a-z0-9]+(?:-[a-z0-9]+)*$"
            )
    return _load_core_main()(root_dir=ROOT_DIR)


if __name__ == "__main__":
    raise SystemExit(main())
