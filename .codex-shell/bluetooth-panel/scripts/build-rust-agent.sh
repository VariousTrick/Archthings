#!/usr/bin/env bash

set -euo pipefail

dir="/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel"
src="$dir/rust-agent"
out="$dir/bin"

mkdir -p "$out"
cd "$src"
cargo build --release --offline
cp "$src/target/release/codex-bt-agentd" "$out/codex-bt-agentd"
chmod +x "$out/codex-bt-agentd"
