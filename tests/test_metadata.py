from __future__ import annotations

from pathlib import Path

import pytest

from scripts.build_pdfs import discover, validate_ascii_slug
from typst_blog_core.context import BlogContext


ROOT = Path(__file__).resolve().parents[1]


def test_ascii_slug_validation() -> None:
    for value in ("a", "hello-world", "v1-post"):
        assert validate_ascii_slug(value) == value
    for value in ("", "Hello", "hello_world", "hello--world", "hello/there", "你好"):
        with pytest.raises(ValueError):
            validate_ascii_slug(value)


def test_structured_metadata_and_title_derivation() -> None:
    records = {meta["slug"]: meta for _, meta in discover(BlogContext.create(ROOT))}
    assert records["hello-dual-output"]["title"] == "Typst · 第一篇双输出记录"
    assert records["title-fallback"]["title"] == "没有课程的文章"
    assert records["feature-matrix"]["draft"] is True
    assert records["title-fallback"]["draft"] is True
    assert records["hello-dual-output"]["pdf-title"] == "第一篇双输出记录"


def test_required_metadata_is_present() -> None:
    for source, meta in discover(BlogContext.create(ROOT)):
        assert source.parent.name == meta["slug"]
        assert meta["create"] is not None
        assert meta["description"]
