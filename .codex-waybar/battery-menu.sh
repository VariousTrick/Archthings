#!/usr/bin/env bash

set -euo pipefail

theme_file="/home/Arch/Downloads/vscode/Archthings/.codex-waybar/battery-menu.rasi"
capacity_file="/sys/class/power_supply/BAT0/capacity"
status_file="/sys/class/power_supply/BAT0/status"
limit_file="/sys/devices/platform/lg-laptop/battery_care_limit"

capacity="$(<"$capacity_file")"
status="$(<"$status_file")"
limit="unknown"
[[ -r "$limit_file" ]] && limit="$(<"$limit_file")"

status_zh="$status"
case "$status" in
  Charging) status_zh="充电中" ;;
  Discharging) status_zh="放电中" ;;
  Full) status_zh="已充满" ;;
  Not\ charging) status_zh="未充电" ;;
  Unknown) status_zh="未知状态" ;;
esac

profile="unknown"
if command -v powerprofilesctl >/dev/null 2>&1; then
  current_profile="$(powerprofilesctl get 2>/dev/null || true)"
  if [[ -n "$current_profile" ]]; then
    profile="$current_profile"
  fi
fi

profile_zh="未知"
case "$profile" in
  power-saver) profile_zh="节能" ;;
  balanced) profile_zh="平衡" ;;
  performance) profile_zh="性能" ;;
esac

filled=$(( capacity / 10 ))
empty=$(( 10 - filled ))
progress="$(printf '█%.0s' $(seq 1 "$filled" 2>/dev/null))"
progress="${progress}$(printf '░%.0s' $(seq 1 "$empty" 2>/dev/null))"

if [[ "$limit" == "80" ]]; then
  care_line="充电保护：已开启（80%）"
  care_action="󰁪  关闭 80% 充电限制"
else
  care_line="充电保护：已关闭（100%）"
  care_action="󰁪  开启 80% 充电限制"
fi

message="<b>${capacity}%</b>  ${status_zh}\n<span foreground='#a6adc8'>${progress}</span>\n性能模式：${profile_zh}\n${care_line}"

choice="$(
  printf '%s\n' \
    '󰾆  节能模式' \
    '󰾅  平衡模式' \
    '󰓅  性能模式' \
    "${care_action}" \
  | rofi -dmenu -markup-rows -mesg "$message" \
      -theme "$theme_file" \
      -p ""
)"

[[ -n "${choice}" ]] || exit 0

case "${choice}" in
  "󰾆  节能模式")
    if ! powerprofilesctl set power-saver 2>/dev/null; then
      notify-send "Battery" "无法切换到节能模式"
      exit 1
    fi
    notify-send "Battery" "已切换到节能模式"
    ;;
  "󰾅  平衡模式")
    if ! powerprofilesctl set balanced 2>/dev/null; then
      notify-send "Battery" "无法切换到平衡模式"
      exit 1
    fi
    notify-send "Battery" "已切换到平衡模式"
    ;;
  "󰓅  性能模式")
    if ! powerprofilesctl set performance 2>/dev/null; then
      notify-send "Battery" "无法切换到性能模式"
      exit 1
    fi
    notify-send "Battery" "已切换到性能模式"
    ;;
  *)
    exec /home/Arch/Downloads/vscode/Archthings/.codex-waybar/battery-care-toggle-user.sh
    ;;
esac
