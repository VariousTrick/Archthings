#!/usr/bin/env bash

set -euo pipefail

theme_file="/home/Arch/Downloads/vscode/Archthings/.codex-waybar/power-menu.rasi"

choice="$(
  printf '%s\n' \
    '󰤄  锁屏' \
    '󰍃  注销' \
    '󰒲  睡眠' \
    '󰜉  重启' \
    '󰐥  关机' \
    '󰤓  休眠' \
  | rofi -dmenu -i \
      -theme "$theme_file" \
      -p ""
)"

[ -n "${choice}" ] || exit 0

case "${choice}" in
  "󰤄  锁屏")
    exit 0
    ;;
  "󰍃  注销")
    exec niri msg action quit
    ;;
  "󰒲  睡眠")
    exit 0
    ;;
  "󰜉  重启")
    exec systemctl reboot
    ;;
  "󰐥  关机")
    exec systemctl poweroff
    ;;
  "󰤓  休眠")
    exit 0
    ;;
esac
