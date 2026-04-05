#!/usr/bin/env bash

set -eu

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

prettify_label() {
  local raw="$1"
  local label="$1"

  label="$(printf '%s' "$label" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /g')"

  if printf '%s' "$label" | grep -Eq 'HDMI / DisplayPort [0-9]+ Output'; then
    printf '%s' "$label" | sed 's/.*HDMI \/ DisplayPort \([0-9]\+\) Output/HDMI\/显示器音频 \1/'
    return
  fi

  if printf '%s' "$label" | grep -Eq 'HDMI / DisplayPort .*Output|DisplayPort .*Output'; then
    printf '显示器音频'
    return
  fi

  case "$label" in
    *"Speaker"*)
      printf '扬声器'
      return
      ;;
    *"Headset"*|*"Headphone"*|*"Headphones"*)
      printf '耳机'
      return
      ;;
    *"Digital Microphone"*)
      printf '数字麦克风'
      return
      ;;
    *"Stereo Microphone"*)
      printf '立体声麦克风'
      return
      ;;
    *"Microphone"*|*"Mic"*)
      printf '麦克风'
      return
      ;;
    *"Line Out"*)
      printf '线路输出'
      return
      ;;
    *"Line In"*)
      printf '线路输入'
      return
      ;;
    *"Monitor of "*)
      printf '监听设备'
      return
      ;;
    *)
      ;;
  esac

  label="$(printf '%s' "$label" | sed \
    -e 's/^.* Audio Controller //' \
    -e 's/^.* USB Audio Device //' \
    -e 's/^.* Analog Stereo //' \
    -e 's/^.* Pro //' \
    -e 's/^Built-in Audio //' \
    -e 's/^Family 17h (Models 10h-1fh) HD Audio Controller //' \
    -e 's/^Family 17h\/19h HD Audio Controller //')"

  if [[ -n "$label" && "$label" != "$raw" ]]; then
    printf '%s' "$label"
  else
    printf '%s' "$raw"
  fi
}

get_default_id() {
  local target="$1"
  wpctl inspect "$target" 2>/dev/null | awk 'NR == 1 { gsub(",", "", $2); print $2; exit }'
}

get_default_label() {
  local target="$1"
  wpctl inspect "$target" 2>/dev/null | awk -F'"' '
    /node.nick = / { print $2; found = 1; exit }
    /device.profile.description = / && !found { fallback = $2 }
    END {
      if (!found && length(fallback) > 0)
        print fallback;
    }
  '
}

get_volume_json() {
  local target="$1"
  local label="$2"
  local icon="$3"
  local id raw vol muted percent safe_label display_label

  id="$(get_default_id "$target")"
  raw="$(wpctl get-volume "$target" 2>/dev/null || printf 'Volume: 0.00')"
  vol="$(printf '%s\n' "$raw" | awk '{print $2}' | tr -d '\n')"
  muted=false
  if printf '%s\n' "$raw" | grep -q '\[MUTED\]'; then
    muted=true
  fi
  percent="$(awk -v v="${vol:-0}" 'BEGIN { p = int((v * 100) + 0.5); if (p < 0) p = 0; if (p > 100) p = 100; print p }')"
  display_label="$(prettify_label "$label")"
  safe_label="$(json_escape "$display_label")"

  printf '{"id":%s,"label":"%s","detail":"","icon":"%s","volume":%s,"muted":%s}' \
    "${id:-0}" "$safe_label" "$icon" "$percent" "$muted"
}

status_raw="$(wpctl status 2>/dev/null || true)"
audio_section="$(printf '%s\n' "$status_raw" | sed -n '/^Audio$/,/^Video$/p')"

parse_devices_json() {
  local start="$1"
  local stop="$2"
  local entries
  entries="$(printf '%s\n' "$audio_section" | awk -v start="$start" -v stop="$stop" '
    BEGIN {
      in_section = 0;
    }
    $0 ~ start {
      in_section = 1;
      next;
    }
    $0 ~ stop {
      in_section = 0;
    }
    in_section && /\[vol:/ {
      line = $0;
      sub(/^[^0-9]*\*?[[:space:]]*/, "", line);
      if (line ~ /^[0-9]+\./) {
        id = line;
        sub(/\..*$/, "", id);
        sub(/^[0-9]+\.[[:space:]]*/, "", line);
        sub(/[[:space:]]*\[vol:.*$/, "", line);
        print id "\t" line;
      }
    }
  ')"

  printf '['
  local prefix='' id label pretty
  while IFS=$'\t' read -r id label; do
    [[ -n "${id:-}" ]] || continue
    pretty="$(prettify_label "$label")"
    pretty="$(json_escape "$pretty")"
    printf '%s{"id":%s,"label":"%s","detail":""}' "$prefix" "$id" "$pretty"
    prefix=','
  done <<< "$entries"
  printf ']'
}

speaker_label="$(get_default_label '@DEFAULT_AUDIO_SINK@')"
mic_label="$(get_default_label '@DEFAULT_AUDIO_SOURCE@')"
speaker_json="$(get_volume_json '@DEFAULT_AUDIO_SINK@' "${speaker_label:-扬声器}" '󰕾')"
mic_json="$(get_volume_json '@DEFAULT_AUDIO_SOURCE@' "${mic_label:-麦克风}" '󰍬')"
sinks_json="$(parse_devices_json '├─ Sinks:' '├─ Sources:')"
sources_json="$(parse_devices_json '├─ Sources:' '├─ Filters:')"

printf '{'
printf '"speaker":%s,' "$speaker_json"
printf '"mic":%s,' "$mic_json"
printf '"sinks":%s,' "$sinks_json"
printf '"sources":%s' "$sources_json"
printf '}\n'
