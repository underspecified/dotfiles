#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fonttools"]
# ///
"""Patch iMWriting Quattro Nerd Font Bold metadata.

The Nerd-Fonts patched iA Writer Quattro Bold and BoldItalic .ttf files ship
with usWeightClass=400 (Regular) instead of 700 (Bold). Fontdb-based apps such
as Zed read OS/2 directly and end up serving the bold-glyph file when an app
asks for Regular -- the "stuck in bold" symptom on Linux.

This script rewrites usWeightClass to 700 on the four affected files.
Idempotent: files already at 700 are skipped.

Usage: uv run ~/.config/lnk/installers/linux/fix_imwriting_quat_weights.py [font_dir]
       (default font_dir: ~/.local/share/fonts)
Output: JSON list of {file, old, new, action} to stdout.
"""

import json
import logging
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stderr)
log = logging.getLogger("fix-quat")

TARGETS = (
    "iMWritingQuatNerdFont-Bold.ttf",
    "iMWritingQuatNerdFont-BoldItalic.ttf",
    "iMWritingQuatNerdFontPropo-Bold.ttf",
    "iMWritingQuatNerdFontPropo-BoldItalic.ttf",
)
BOLD_WEIGHT = 700


def patch_one(path: Path) -> dict[str, object]:
    with TTFont(str(path)) as font:
        os2 = font["OS/2"]
        old = os2.usWeightClass
        if old == BOLD_WEIGHT:
            log.info("already correct: %s", path.name)
            return {"file": path.name, "old": old, "new": old, "action": "already_correct"}
        os2.usWeightClass = BOLD_WEIGHT
        font.save(str(path))
        log.info("fixed: %s (%d -> %d)", path.name, old, BOLD_WEIGHT)
        return {"file": path.name, "old": old, "new": BOLD_WEIGHT, "action": "fixed"}


def main() -> int:
    font_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".local/share/fonts"
    if not font_dir.is_dir():
        log.error("font directory not found: %s", font_dir)
        return 1

    results: list[dict[str, object]] = []
    for name in TARGETS:
        path = font_dir / name
        if not path.exists():
            log.warning("missing (skipped): %s", path)
            results.append({"file": name, "action": "missing"})
            continue
        results.append(patch_one(path))

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
