#!/usr/bin/env bash

set -euo pipefail

helper="/usr/local/bin/waybar-battery-care-toggle"

if ! sudo "$helper"; then
  notify-send "Battery care" "Failed to change charge limit"
  exit 1
fi

limit_file="/sys/devices/platform/lg-laptop/battery_care_limit"
if [[ -r "$limit_file" ]]; then
  limit="$(<"$limit_file")"
  if [[ "$limit" == "80" ]]; then
    notify-send "Battery care" "Charge limit set to 80%"
  else
    notify-send "Battery care" "Charge limit set to 100%"
  fi
fi

pkill -RTMIN+8 waybar 2>/dev/null || true
