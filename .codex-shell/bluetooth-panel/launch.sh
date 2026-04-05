#!/usr/bin/env bash

set -euo pipefail

dir="/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel"
helper="$dir/bin/codex-bt-agentd"

if [[ -x "$helper" ]] && ! pgrep -f "$helper" >/dev/null 2>&1; then
  nohup "$helper" >/dev/null 2>&1 &
  sleep 0.08
fi

if quickshell list --path "$dir" --json 2>/dev/null | grep -q '"pid"'; then
  quickshell ipc -p "$dir" call bluetoothpanel toggle >/dev/null 2>&1 || true
  exit 0
fi

quickshell -p "$dir" -d >/dev/null 2>&1 &
sleep 0.12
quickshell ipc -p "$dir" call bluetoothpanel show >/dev/null 2>&1 || true
