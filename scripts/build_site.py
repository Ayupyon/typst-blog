#!/usr/bin/env python3
"""Run the complete reproducible production build for the blog."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from shutil import which


ROOT = Path(__file__).resolve().parents[1]
TYPST_VERSION = "0.15.1"
PAGEFIND_VERSION = "1.5.2"


def run(command: list[str], *, cwd: Path = ROOT) -> None:
    print("+ " + " ".join(command))
    subprocess.run(command, cwd=cwd, check=True)


def require_tools() -> None:
    for name in ("typst", "node", "npx"):
        if which(name) is None:
            raise RuntimeError(f"required tool not found: {name}")
    typst = subprocess.check_output(["typst", "--version"], text=True).strip()
    if not typst.startswith(f"typst {TYPST_VERSION}"):
        raise RuntimeError(f"Typst {TYPST_VERSION} is required, found: {typst}")
    node = subprocess.check_output(["node", "--version"], text=True).strip()
    print(f"Using {typst}; Node {node}; Pagefind {PAGEFIND_VERSION}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-pagefind", action="store_true", help="skip the network-dependent Pagefind step")
    args = parser.parse_args()

    require_tools()
    run([sys.executable, "scripts/validate_html.py"])
    run([sys.executable, "command.py", "build"])
    run([sys.executable, "scripts/build_pdfs.py", "--mode", "production"])
    run([sys.executable, "scripts/inject_pdf_links.py"])
    if not args.skip_pagefind:
        run(["npx", "-y", f"pagefind@{PAGEFIND_VERSION}", "--site", "public"])
    verify_args = [sys.executable, "scripts/verify_outputs.py"]
    if not args.skip_pagefind:
        verify_args.append("--production")
    run(verify_args)
    run([sys.executable, "scripts/check_links.py"])
    print("Production site build passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
