#!/usr/bin/env bash

set -euo pipefail

dir="/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel"
helper="$dir/bin/codex-bt-agentd"

if [[ -x "$helper" ]]; then
  "$helper" ctl state 2>/dev/null || printf '{"helperReady":false,"request":{},"status":{}}'
else
  printf '{"helperReady":false,"request":{},"status":{}}'
fi
