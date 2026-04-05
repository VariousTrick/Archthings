#!/usr/bin/env bash

set -euo pipefail

panel="/home/Arch/Downloads/vscode/Archthings/.codex-waybar/battery-panel.py"

if pgrep -f "$panel" >/dev/null 2>&1; then
  pkill -f "$panel" || true
  exit 0
fi

exec python3 "$panel" >/dev/null 2>&1 &
