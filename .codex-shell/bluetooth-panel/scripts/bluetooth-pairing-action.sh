#!/usr/bin/env bash

set -euo pipefail

dir="/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel"
helper="$dir/bin/codex-bt-agentd"

if [[ ! -x "$helper" ]]; then
  exit 1
fi

action="${1:-}"

case "$action" in
  pair)
    "$helper" ctl pair "${2:-}"
    ;;
  accept)
    "$helper" ctl accept "${2:-}" "${3:-}" "${4:-}"
    ;;
  reject)
    "$helper" ctl reject "${2:-}" "${3:-}" "${4:-}"
    ;;
  *)
    exit 2
    ;;
esac
