from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from bs4 import BeautifulSoup


ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "public" / "hello-dual-output" / "index.html"


def soup() -> BeautifulSoup:
    return BeautifulSoup(HTML.read_text(encoding="utf-8"), "html.parser")


def test_semantic_article_and_combined_title() -> None:
    page = soup()
    title = "Typst · 第一篇双输出记录"
    assert page.html["lang"] == "zh-CN"
    assert page.title.get_text(strip=True) == title
    assert page.select_one("h1#article-title").get_text(" ", strip=True) == title
    assert page.select_one('meta[property="og:title"]')["content"] == title
    ld = json.loads(page.select_one('script[type="application/ld+json"]').string)
    assert ld["headline"] == title
    assert page.select_one("article[data-pagefind-body]") is not None


def test_rin_block_anchor_reference_and_pdf_link() -> None:
    page = soup()
    block = page.select_one("figure#dual-output-theorem .rin-block--theorem")
    assert block is not None
    assert "Theorem" in block.get_text(" ", strip=True)
    assert page.select_one('a[href="#dual-output-theorem"]') is not None
    link = page.select_one(".article-meta a.pdf-download")
    assert link is not None
    assert link["href"] == "post.pdf"
    assert link.get_text(strip=True) == "下载 PDF"


def test_drafts_are_not_in_production_tree() -> None:
    assert not (ROOT / "public" / "feature-matrix").exists()
    assert not (ROOT / "public" / "title-fallback").exists()


def test_feature_matrix_preview_has_accessible_diagram() -> None:
    # The production tree intentionally excludes drafts. Build a temporary
    # draft-inclusive tree, inspect it, and restore production output for the
    # remaining tests.
    subprocess.run(
        [
            sys.executable,
            "-c",
            "import command; command._load_core_main(); from typst_blog_core.builder import build; build(root_dir='.', include_drafts=True)",
        ],
        cwd=ROOT,
        check=True,
    )
    try:
        page = BeautifulSoup(
            (ROOT / "public" / "feature-matrix" / "index.html").read_text(encoding="utf-8"),
            "html.parser",
        )
        diagram = page.select_one("figure.rin-diagram")
        assert diagram is not None
        assert diagram.get("role") == "img"
        assert diagram.get("aria-label", "").startswith("箭头从对象 A")
        assert diagram.select_one("svg") is not None
        assert diagram.select_one("figcaption") is not None
        assert page.select_one("#later-theorem") is not None
        assert page.select_one('a[href="#later-theorem"]') is not None
        for kind, label in (
            ("definition", "Definition"),
            ("theorem", "Theorem"),
            ("lemma", "Lemma"),
        ):
            heading = page.select_one(f".rin-block--{kind} .rin-block__heading")
            assert heading is not None
            assert label in heading.get_text(" ", strip=True)
        proof_heading = page.select_one(".rin-proof .rin-block__heading")
        assert proof_heading is not None
        assert "Proof." in proof_heading.get_text(" ", strip=True)
        for kind, label in (
            ("note", "Note"),
            ("tip", "Tip"),
            ("important", "Important"),
            ("warning", "Warning"),
            ("caution", "Caution"),
        ):
            heading = page.select_one(f".markdown-alert-{kind} .markdown-alert-title")
            assert heading is not None
            assert label in heading.get_text(" ", strip=True)
    finally:
        subprocess.run([sys.executable, "scripts/build_site.py"], cwd=ROOT, check=True)
