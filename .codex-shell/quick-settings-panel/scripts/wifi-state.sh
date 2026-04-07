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

if [[ -n "$wifi_device" && "$wifi_enabled" == true ]]; then
  nmcli device wifi rescan ifname "$wifi_device" >/dev/null 2>&1 || nmcli device wifi rescan >/dev/null 2>&1 || true
  sleep 1
fi

if [[ -n "$wifi_device" ]]; then
  raw_list="$(nmcli -t --escape no -f IN-USE,SSID,SIGNAL,SECURITY,BARS device wifi list ifname "$wifi_device" 2>/dev/null || true)"
else
  raw_list="$(nmcli -t --escape no -f IN-USE,SSID,SIGNAL,SECURITY,BARS device wifi list 2>/dev/null || true)"
fi

printf '{'
printf '"wifiEnabled":%s,' "$wifi_enabled"
printf '"wifiDevice":"%s",' "$(json_escape "$wifi_device")"
printf '"connectedSsid":"%s",' "$(json_escape "$connected_ssid")"
printf '"networks":['

first=true
while IFS=: read -r inuse ssid_key signal security bars || [[ -n "${inuse}${ssid_key}${signal}${security}${bars}" ]]; do
  ssid_key="$(printf '%s' "$ssid_key" | trim)"
  [[ -n "$ssid_key" ]] || continue

  active=false
  if [[ "$inuse" == "*" ]]; then
    active=true
  fi

  signal="$(printf '%s' "$signal" | tr -dc '0-9')"
  [[ -n "$signal" ]] || signal=0
  secure=false
  if [[ -n "$security" && "$security" != "--" ]]; then
    secure=true
  fi

  details="${signal}% 信号"
  if [[ "$secure" == true ]]; then
    details="${details}，安全"
  else
    details="${details}，开放网络"
  fi

  if [[ "$active" == true ]]; then
    details="已连接，安全"
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
done <<< "$raw_list"

printf ']}'
