from __future__ import annotations

from pathlib import Path

from scripts.check_links import check


ROOT = Path(__file__).resolve().parents[1]


def test_all_generated_local_links_resolve() -> None:
    check(ROOT)


def test_project_pages_base_path_is_used() -> None:
    html = (ROOT / "public" / "hello-dual-output" / "index.html").read_text(encoding="utf-8")
    assert 'href="/typst-blog/styles/base.css"' in html
    assert 'href="https://Ayupyon.github.io/typst-blog/hello-dual-output/"' in html
    assert 'href="/"' not in html
