from __future__ import annotations

import re
import subprocess
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]


def test_published_pdf_is_readable_and_has_metadata() -> None:
    path = ROOT / "public" / "hello-dual-output" / "post.pdf"
    reader = PdfReader(str(path))
    assert len(reader.pages) >= 1
    assert reader.metadata["/Title"] == "第一篇双输出记录"
    assert reader.metadata["/Author"] == "Ayupyon"


def test_draft_pdfs_are_absent() -> None:
    assert not (ROOT / "public" / "feature-matrix" / "post.pdf").exists()
    assert not (ROOT / "public" / "title-fallback" / "post.pdf").exists()


def test_feature_matrix_pdf_validation_and_title_fallback(tmp_path: Path) -> None:
    feature_pdf = tmp_path / "feature-matrix.pdf"
    fallback_pdf = tmp_path / "title-fallback.pdf"
    for source, output in (
        (ROOT / "posts" / "feature-matrix" / "index.typ", feature_pdf),
        (ROOT / "posts" / "title-fallback" / "index.typ", fallback_pdf),
    ):
        subprocess.run(
            ["typst", "compile", "--root", str(ROOT), str(source), str(output)],
            cwd=ROOT,
            check=True,
        )
    feature_text = "\n".join(page.extract_text() or "" for page in PdfReader(str(feature_pdf)).pages)
    assert "Theorem" in feature_text
    assert "Lemma" in feature_text
    assert "Proof." in feature_text
    assert "Diagram 1" in feature_text
    fallback_reader = PdfReader(str(fallback_pdf))
    assert fallback_reader.metadata["/Title"] == "没有课程的文章"


def test_example_post_is_an_english_syntax_fixture(tmp_path: Path) -> None:
    source = ROOT / "example-post" / "index.typ"
    source_text = source.read_text(encoding="utf-8")
    assert re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", source_text) is None

    output = tmp_path / "example-post.pdf"
    subprocess.run(
        ["typst", "compile", "--root", str(ROOT), str(source), str(output)],
        cwd=ROOT,
        check=True,
    )
    text = "\n".join(page.extract_text() or "" for page in PdfReader(str(output)).pages)
    for label in (
        "Definition",
        "Theorem",
        "Lemma",
        "Proof",
        "Note",
        "Tip",
        "Important",
        "Warning",
        "Caution",
    ):
        assert label in text
