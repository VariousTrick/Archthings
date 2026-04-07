#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

wifi_device() {
  nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'
}

case "$action" in
  toggle)
    state="${2:-}"
    if [[ "$state" == "on" ]]; then
      nmcli radio wifi on >/dev/null
    else
      nmcli radio wifi off >/dev/null
    fi
    ;;
  disconnect)
    device="$(wifi_device)"
    if [[ -n "$device" ]]; then
      nmcli device disconnect "$device" >/dev/null
    fi
    ;;
  connect-open)
    ssid="${2:-}"
    [[ -n "$ssid" ]] || exit 1
    nmcli device wifi connect "$ssid" >/dev/null
    ;;
  connect-secure)
    ssid="${2:-}"
    password="${3:-}"
    [[ -n "$ssid" && -n "$password" ]] || exit 1
    nmcli device wifi connect "$ssid" password "$password" >/dev/null
    ;;
  refresh)
    device="$(wifi_device)"
    if [[ -n "$device" ]]; then
      nmcli device wifi rescan ifname "$device" >/dev/null || nmcli device wifi rescan >/dev/null
    else
      nmcli device wifi rescan >/dev/null
    fi
    ;;
  *)
    exit 1
    ;;
esac
