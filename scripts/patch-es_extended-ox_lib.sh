#!/usr/bin/env bash
# Linux/VPS helper: same patch as patch-es_extended-ox_lib.ps1 (Windows).
# Requires: python3
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/patch-es_extended-ox_lib.py" "$@"
