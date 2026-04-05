#!/usr/bin/env bash

set -euo pipefail

bat_dir="/sys/class/power_supply/BAT0"
limit_file="/sys/devices/platform/lg-laptop/battery_care_limit"
threshold_file="$bat_dir/charge_control_end_threshold"

read_file() {
  local path="$1"
  local fallback="${2:-}"
  if [[ -r "$path" ]]; then
    tr -d '\n' < "$path"
  else
    printf '%s' "$fallback"
  fi
}

capacity="$(read_file "$bat_dir/capacity" "0")"
status_raw="$(read_file "$bat_dir/status" "Unknown")"
energy_now="$(read_file "$bat_dir/energy_now" "0")"
energy_full="$(read_file "$bat_dir/energy_full" "0")"
power_now="$(read_file "$bat_dir/power_now" "0")"
care_limit="$(read_file "$limit_file" "")"

if [[ -z "$care_limit" ]]; then
  care_limit="$(read_file "$threshold_file" "100")"
fi

profile="$(/usr/bin/powerprofilesctl get 2>/dev/null || printf 'balanced')"

case "$status_raw" in
  Charging) status_text="正在充电" ;;
  Discharging) status_text="正在耗电" ;;
  Full|Not\ charging) status_text="已接通电源" ;;
  *) status_text="状态未知" ;;
esac

case "$profile" in
  power-saver) profile_text="节能" ;;
  performance) profile_text="性能" ;;
  *) profile="balanced"; profile_text="平衡" ;;
esac

time_text="--:--"
if [[ "$power_now" =~ ^[0-9]+$ ]] && (( power_now > 0 )); then
  if [[ "$status_raw" == "Charging" ]]; then
    remaining_wh=$(( energy_full - energy_now ))
  else
    remaining_wh=$energy_now
  fi

  if (( remaining_wh > 0 )); then
    time_text="$(awk -v e="$remaining_wh" -v p="$power_now" '
      BEGIN {
        h = e / p;
        if (h <= 0) {
          print "--:--";
          exit;
        }
        total = int(h * 60 + 0.5);
        hh = int(total / 60);
        mm = total % 60;
        printf "%d:%02d", hh, mm;
      }
    ')"
  fi
fi

care_enabled="false"
if [[ "$care_limit" == "80" ]]; then
  care_enabled="true"
fi

printf '{'
printf '"capacity":%s,' "$capacity"
printf '"status":"%s",' "$status_raw"
printf '"status_text":"%s",' "$status_text"
printf '"time_text":"%s",' "$time_text"
printf '"care_enabled":%s,' "$care_enabled"
printf '"care_limit":%s,' "${care_limit:-100}"
printf '"profile":"%s",' "$profile"
printf '"profile_text":"%s"' "$profile_text"
printf '}\n'
