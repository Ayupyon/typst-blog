from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


@pytest.fixture(scope="session", autouse=True)
def production_site() -> None:
    """Make `uv run pytest` useful from a clean clone as well as CI."""
    marker = ROOT / "public" / "pagefind" / "pagefind-entry.json"
    if not marker.is_file():
        subprocess.run([sys.executable, "scripts/build_site.py"], cwd=ROOT, check=True)
