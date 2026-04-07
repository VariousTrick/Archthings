#!/usr/bin/env bash

set -euo pipefail

dir="/home/Arch/Downloads/vscode/Archthings/.codex-shell/quick-settings-panel"
bt_helper="/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel/bin/codex-bt-agentd"

if [[ -x "$bt_helper" ]] && ! pgrep -f "$bt_helper" >/dev/null 2>&1; then
  nohup "$bt_helper" >/dev/null 2>&1 &
  sleep 0.08
fi

if quickshell list --path "$dir" --json 2>/dev/null | grep -q '"pid"'; then
  quickshell ipc -p "$dir" call quicksettingspanel toggle >/dev/null 2>&1 || true
  exit 0
fi

quickshell -p "$dir" -d >/dev/null 2>&1 &
sleep 0.12
quickshell ipc -p "$dir" call quicksettingspanel show >/dev/null 2>&1 || true
