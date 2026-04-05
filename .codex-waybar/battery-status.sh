#!/usr/bin/env bash

set -euo pipefail

battery_dir="/sys/class/power_supply/BAT0"
limit_file="/sys/devices/platform/lg-laptop/battery_care_limit"

capacity="$(<"$battery_dir/capacity")"
status="$(<"$battery_dir/status")"
limit="100"

if [[ -r "$limit_file" ]]; then
  limit="$(<"$limit_file")"
fi

icons=("󰂎" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
idx=$(( capacity / 10 ))
if (( idx > 9 )); then
  idx=9
fi
icon="${icons[$idx]}"

if [[ "$status" == "Charging" ]]; then
  icon="󰂄"
fi

classes=()
if (( capacity <= 10 )); then
  classes+=(critical)
elif (( capacity <= 20 )); then
  classes+=(warning)
fi

if [[ "$status" == "Charging" ]]; then
  classes+=(charging)
fi

if [[ "$limit" == "80" ]]; then
  classes+=(care-enabled)
fi

tooltip_status="Discharging"
if [[ "$status" == "Charging" ]]; then
  tooltip_status="Charging"
elif [[ "$status" == "Full" ]]; then
  tooltip_status="Full"
fi

class_json="["
for i in "${!classes[@]}"; do
  [[ $i -gt 0 ]] && class_json+=", "
  class_json+="\"${classes[$i]}\""
done
class_json+="]"

printf '{"text":"%s %s%%","tooltip":"%s\\nCharge limit: %s%%","class":%s}\n' \
  "$icon" "$capacity" "$tooltip_status" "$limit" "$class_json"
