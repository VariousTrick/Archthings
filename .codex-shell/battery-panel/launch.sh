#!/usr/bin/env bash

set -euo pipefail

dir="/home/Arch/Downloads/vscode/Archthings/.codex-shell/battery-panel"
state_script="$dir/scripts/battery-panel-state.sh"

if quickshell list --path "$dir" --json 2>/dev/null | grep -q '"pid"'; then
  quickshell ipc -p "$dir" call batterypanel toggle >/dev/null 2>&1 || true
  exit 0
fi

initial_state="$("$state_script" 2>/dev/null || printf '')"

env QS_BATTERY_STATE_INITIAL="$initial_state" quickshell -p "$dir" -d >/dev/null 2>&1 &
sleep 0.12
quickshell ipc -p "$dir" call batterypanel show >/dev/null 2>&1 || true
