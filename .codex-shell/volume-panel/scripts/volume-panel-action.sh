#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'usage: %s <set-volume|set-mute> <speaker|mic> <value>\n' "$0" >&2
  printf '       %s <set-default> <id>\n' "$0" >&2
  exit 2
}

[[ $# -ge 2 ]] || usage

action="$1"

case "$action" in
  set-default)
    [[ $# -eq 2 ]] || usage
    wpctl set-default "$2"
    ;;
  set-volume)
    [[ $# -eq 3 ]] || usage
    device="$2"
    value="$3"
    case "$device" in
      speaker) target='@DEFAULT_AUDIO_SINK@' ;;
      mic) target='@DEFAULT_AUDIO_SOURCE@' ;;
      *) usage ;;
    esac
    wpctl set-volume "$target" "$value"
    ;;
  set-mute)
    [[ $# -eq 3 ]] || usage
    device="$2"
    value="$3"
    case "$device" in
      speaker) target='@DEFAULT_AUDIO_SINK@' ;;
      mic) target='@DEFAULT_AUDIO_SOURCE@' ;;
      *) usage ;;
    esac
    wpctl set-mute "$target" "$value"
    ;;
  *)
    usage
    ;;
esac
