from __future__ import annotations

import shutil
import sys
from pathlib import Path

import command


ROOT = Path(__file__).resolve().parents[1]


def test_new_command_writes_explicit_course(tmp_path: Path, monkeypatch) -> None:
    shutil.copy2(ROOT / "site.typ", tmp_path / "site.typ")
    vendor_dir = tmp_path / "vendor"
    vendor_dir.mkdir()
    (vendor_dir / "typst-blog-core").symlink_to(
        ROOT / "vendor" / "typst-blog-core",
        target_is_directory=True,
    )

    monkeypatch.setattr(command, "ROOT_DIR", tmp_path)
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "command.py",
            "new",
            "course-test",
            "--title",
            "Course Test",
            "--description",
            "A post with a course.",
            "--course",
            'Typst "101"',
        ],
    )

    assert command.main() == 0
    source = (tmp_path / "posts" / "course-test" / "index.typ").read_text(
        encoding="utf-8"
    )
    assert 'course: "Typst \\"101\\""' in source
