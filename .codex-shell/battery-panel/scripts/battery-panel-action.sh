#!/usr/bin/env bash

set -euo pipefail

workspace="/home/Arch/Downloads/vscode/Archthings"
care_toggle="$workspace/.codex-waybar/battery-care-toggle-user.sh"

action="${1:-}"

case "$action" in
  set-profile)
    profile="${2:-balanced}"
    exec powerprofilesctl set "$profile"
    ;;
  toggle-care)
    exec "$care_toggle"
    ;;
  *)
    printf 'unknown action: %s\n' "$action" >&2
    exit 1
    ;;
esac
