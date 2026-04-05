#!/usr/bin/env bash

set -euo pipefail

json_escape() {
  printf '%s' "$1" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g' \
    -e 's/\t/\\t/g' \
    -e 's/\r/\\r/g' \
    -e ':a;N;$!ba;s/\n/\\n/g'
}

trim() {
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

signal_icon() {
  local signal="${1:-0}"
  if (( signal >= 80 )); then
    printf '󰤨'
  elif (( signal >= 60 )); then
    printf '󰤥'
  elif (( signal >= 40 )); then
    printf '󰤢'
  else
    printf '󰤟'
  fi
}

wifi_enabled=false
if [[ "$(nmcli radio wifi 2>/dev/null | tr '[:upper:]' '[:lower:]' | head -n1)" == "enabled" ]]; then
  wifi_enabled=true
fi

wifi_device="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')"
connected_ssid="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: '$2=="wifi" && $3=="connected"{print $4; exit}')"

declare -A seen
declare -A net_active
declare -A net_signal
declare -A net_security
declare -A net_bars
declare -a order

raw_list="$(nmcli -m multiline -f IN-USE,SSID,SIGNAL,SECURITY,BARS device wifi list --rescan auto 2>/dev/null || true)"

flush_record() {
  local key="${ssid:-}"
  local active_bool=false
  local signal_num="${signal:-0}"
  local security_text="${security:-}"
  local bars_text="${bars:-}"

  key="$(printf '%s' "$key" | trim)"
  security_text="$(printf '%s' "$security_text" | trim)"
  bars_text="$(printf '%s' "$bars_text" | trim)"
  signal_num="$(printf '%s' "$signal_num" | tr -dc '0-9')"
  [[ -n "$signal_num" ]] || signal_num=0

  if [[ -z "$key" ]]; then
    return
  fi

  if [[ "${inuse:-}" == "*" ]]; then
    active_bool=true
  fi

  if [[ -z "${seen[$key]:-}" ]]; then
    order+=("$key")
    seen["$key"]=1
    net_active["$key"]="$active_bool"
    net_signal["$key"]="$signal_num"
    net_security["$key"]="$security_text"
    net_bars["$key"]="$bars_text"
    return
  fi

  if [[ "$active_bool" == true || "${net_active[$key]}" != true ]]; then
    if [[ "$active_bool" == true || "$signal_num" -gt "${net_signal[$key]}" ]]; then
      net_active["$key"]="$active_bool"
      net_signal["$key"]="$signal_num"
      net_security["$key"]="$security_text"
      net_bars["$key"]="$bars_text"
    fi
  fi
}

ssid=""
signal=""
security=""
bars=""
inuse=""
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ -z "$line" ]]; then
    flush_record
    ssid=""
    signal=""
    security=""
    bars=""
    inuse=""
    continue
  fi

  key="${line%%:*}"
  value="${line#*:}"
  value="$(printf '%s' "$value" | trim)"
  case "$key" in
    "IN-USE") inuse="$value" ;;
    "SSID") ssid="$value" ;;
    "SIGNAL") signal="$value" ;;
    "SECURITY") security="$value" ;;
    "BARS") bars="$value" ;;
  esac
done <<< "$raw_list"
flush_record

printf '{'
printf '"wifiEnabled":%s,' "$wifi_enabled"
printf '"wifiDevice":"%s",' "$(json_escape "$wifi_device")"
printf '"connectedSsid":"%s",' "$(json_escape "$connected_ssid")"
printf '"networks":['

first=true
for ssid_key in "${order[@]}"; do
  active="${net_active[$ssid_key]}"
  signal="${net_signal[$ssid_key]}"
  security="${net_security[$ssid_key]}"
  bars="${net_bars[$ssid_key]}"
  secure=false
  if [[ -n "$security" && "$security" != "--" ]]; then
    secure=true
  fi

  details="${signal}% 信号"
  if [[ "$secure" == true ]]; then
    details="${details}，已加密"
  else
    details="${details}，开放网络"
  fi

  if [[ "$active" == true ]]; then
    details="已连接，${details}"
  fi

  if [[ "$first" == true ]]; then
    first=false
  else
    printf ','
  fi

  printf '{'
  printf '"ssid":"%s",' "$(json_escape "$ssid_key")"
  printf '"signal":%s,' "$signal"
  printf '"security":"%s",' "$(json_escape "$security")"
  printf '"bars":"%s",' "$(json_escape "$bars")"
  printf '"active":%s,' "$active"
  printf '"secure":%s,' "$secure"
  printf '"icon":"%s",' "$(signal_icon "$signal")"
  printf '"details":"%s"' "$(json_escape "$details")"
  printf '}'
done

printf ']}'
