#!/usr/bin/env python3
"""Patch es_extended fxmanifest.lua so client scripts get global `lib` from ox_lib.

Run on your FXServer host (Linux VPS). Requires Python 3.6+ (default on Ubuntu).

Examples:
  python3 patch-es_extended-ox_lib.py --es-extended-root '/path/to/resources/[core]/es_extended'
  python3 patch-es_extended-ox_lib.py --fxmanifest /path/to/es_extended/fxmanifest.lua
  python3 patch-es_extended-ox_lib.py --es-extended-root '...' --what-if
"""

import argparse
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple

INJECT_LINE = "    '@ox_lib/init.lua',\n"


def patch_content(raw: str) -> Tuple[str, Optional[str]]:
    """Return (new_content, error_message). error_message set if patch failed."""
    if "@ox_lib/init.lua" in raw:
        return raw, None

    orig = raw
    new_raw, n = re.subn(
        r"(shared_scripts\s*\{\s*\r?\n)",
        lambda m: m.group(1) + INJECT_LINE,
        raw,
        count=1,
    )
    if n == 0:
        new_raw, n = re.subn(
            r"(shared_scripts\s*\{)",
            lambda m: m.group(1) + "\n" + INJECT_LINE.rstrip("\n"),
            raw,
            count=1,
        )
    raw = new_raw

    if raw == orig:
        return raw, "No usable shared_scripts block. Add @ox_lib/init.lua manually to shared_scripts."

    if not re.search(r"['\"]ox_lib['\"]", raw):
        dep_before = raw
        raw, n = re.subn(
            r"(dependencies\s*\{\s*\r?\n)",
            lambda m: m.group(1) + "    'ox_lib',\n",
            raw,
            count=1,
        )
        if n == 0:
            raw, n = re.subn(
                r"(dependencies\s*\{)",
                lambda m: m.group(1) + "\n    'ox_lib',\n",
                raw,
                count=1,
            )
        if raw == dep_before:
            raw = dep_before.rstrip() + "\n\ndependencies {\n    'ox_lib',\n}\n"

    return raw, None


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument(
        "--es-extended-root",
        default="",
        help="Directory containing es_extended (fxmanifest.lua inside it)",
    )
    p.add_argument(
        "--fxmanifest",
        default="",
        help="Full path to es_extended/fxmanifest.lua",
    )
    p.add_argument(
        "--what-if",
        action="store_true",
        help="Print result only; do not write or backup",
    )
    args = p.parse_args()

    fx_path: Path | None
    if args.fxmanifest:
        fx_path = Path(args.fxmanifest)
    elif args.es_extended_root:
        root = Path(args.es_extended_root.rstrip("/\\"))
        if not root.is_dir():
            print(f"[error] Folder not found: {root}", file=sys.stderr)
            print(
                "Use the path on THIS machine (your VPS), e.g. .../resources/[core]/es_extended",
                file=sys.stderr,
            )
            return 1
        fx_path = root / "fxmanifest.lua"
    else:
        print(
            "Usage:\n"
            "  python3 patch-es_extended-ox_lib.py --es-extended-root '/home/.../resources/[core]/es_extended'\n"
            "  python3 patch-es_extended-ox_lib.py --fxmanifest /home/.../es_extended/fxmanifest.lua",
            file=sys.stderr,
        )
        print(
            "\nQuote paths that contain [core] — in bash use single quotes.",
            file=sys.stderr,
        )
        return 1

    if not fx_path.is_file():
        print(f"[error] File not found: {fx_path}", file=sys.stderr)
        return 1

    raw = fx_path.read_text(encoding="utf-8", errors="replace")
    if "@ox_lib/init.lua" in raw:
        print(f"[ok] Already contains @ox_lib/init.lua : {fx_path}")
        return 0

    new_raw, err = patch_content(raw)
    if err:
        print(f"[error] {err}", file=sys.stderr)
        return 2

    if args.what_if:
        print(new_raw, end="")
        return 0

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    bak = fx_path.with_name(fx_path.name + f".bak-oxlib-{stamp}")
    shutil.copy2(fx_path, bak)
    fx_path.write_text(new_raw, encoding="utf-8", newline="\n")
    print(f"[ok] Patched: {fx_path}")
    print(f"[ok] Backup:  {bak}")
    print("")
    print("In server.cfg start ox_lib BEFORE es_extended (see server-cfg-ox-order-snippet.txt).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
