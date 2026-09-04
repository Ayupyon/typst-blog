#!/usr/bin/env python3
"""Compile all posts, including drafts, to a disposable validation tree."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import command


def main() -> int:
    command._load_core_main()
    from typst_blog_core.builder import build

    build(root_dir=ROOT, include_drafts=True)
    print("Validated HTML for published posts and drafts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
