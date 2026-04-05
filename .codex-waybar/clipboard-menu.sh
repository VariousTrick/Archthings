#!/usr/bin/env bash

set -euo pipefail

theme_file="/home/Arch/Downloads/vscode/Archthings/.codex-waybar/clipboard-hyde.rasi"

if ! command -v cliphist >/dev/null 2>&1; then
  notify-send "Clipboard" "cliphist is not installed"
  exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
  notify-send "Clipboard" "rofi is not installed"
  exit 1
fi

if ! cliphist list >/dev/null 2>&1; then
  notify-send "Clipboard" "Clipboard history is empty"
  exit 0
fi

selection="$(
  cliphist list | rofi -dmenu -i \
    -theme "$theme_file" \
    -click-to-exit \
    -no-custom \
    -theme-str 'entry { placeholder: "Search clipboard"; }' \
    -p "Clipboard"
)"

[ -n "${selection}" ] || exit 0

cliphist decode <<<"$selection" | wl-copy
