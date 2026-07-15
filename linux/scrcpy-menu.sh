#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_FILE="$SCRIPT_DIR/../profiles.conf"
ADD_APP_LABEL="+ Add new app..."
REMOVE_APP_LABEL="- Remove app..."

RESOLUTION_PRESETS=(
  "Portrait phone (720x1440/280)|720x1440/280"
  "Landscape phone (1440x720)|1440x720"
  "Portrait phone HD (1080x1920/420)|1080x1920/420"
  "Landscape phone HD (1920x1080)|1920x1080"
  "Landscape 2K (2560x1440)|2560x1440"
  "Custom...|"
)

add_app() {
  local tmp_apps
  tmp_apps="$(mktemp)"
  trap 'rm -f "$tmp_apps"' RETURN

  if ! adb get-state >/dev/null 2>&1; then
    zenity --error --text="No ADB device connected. Connect your phone (with USB debugging enabled) and try again."
    return
  fi

  (scrcpy --list-apps > "$tmp_apps" 2>&1) &
  local scan_pid=$!
  ( while kill -0 "$scan_pid" 2>/dev/null; do echo; sleep 0.5; done ) \
    | zenity --progress --pulsate --no-cancel --auto-close \
      --title="scrcpy Launcher" --text="Scanning apps on device..."
  wait "$scan_pid"

  local app_rows=()
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*[*-][[:space:]] ]] || continue
    local rest="${line#*[*-] }"
    local pkg="${rest##* }"
    local label="${rest% *}"
    label="$(printf '%s' "$label" | sed -E 's/[[:space:]]+$//')"
    [[ "$pkg" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]] || continue
    app_rows+=("$label" "$pkg")
  done < "$tmp_apps"

  if [ ${#app_rows[@]} -eq 0 ]; then
    zenity --error --text="Could not read the app list from the device.\n\n$(cat "$tmp_apps")"
    return
  fi

  local picked
  picked=$(zenity --list --title="scrcpy Launcher" --text="Select an app to auto-launch:" \
    --column="App Name" --column="Package" --print-column=ALL \
    --height=450 --width=500 \
    -- "${app_rows[@]}")
  [ -z "$picked" ] && return

  local app_label="${picked%%|*}"
  local app_pkg="${picked##*|}"

  local preset_labels=()
  local entry
  for entry in "${RESOLUTION_PRESETS[@]}"; do
    preset_labels+=("${entry%%|*}")
  done

  local res_choice
  res_choice=$(zenity --list --title="scrcpy Launcher" --text="Choose a resolution for $app_label:" \
    --column="Resolution" --height=280 --width=350 \
    -- "${preset_labels[@]}")
  [ -z "$res_choice" ] && return

  local resolution=""
  for entry in "${RESOLUTION_PRESETS[@]}"; do
    if [ "${entry%%|*}" = "$res_choice" ]; then
      resolution="${entry##*|}"
      break
    fi
  done

  if [ -z "$resolution" ]; then
    resolution=$(zenity --entry --title="scrcpy Launcher" \
      --text="Enter a custom resolution (WIDTHxHEIGHT[/DPI]):" --entry-text="1080x1920/320")
    [ -z "$resolution" ] && return
  fi

  local final_label
  final_label=$(zenity --entry --title="scrcpy Launcher" \
    --text="Menu label for this profile:" --entry-text="$app_label")
  [ -z "$final_label" ] && return

  printf '%s|%s|%s\n' "$final_label" "$resolution" "$app_pkg" >> "$PROFILES_FILE"
  zenity --info --text="Added \"$final_label\" to profiles.conf."
}

remove_app() {
  if [ ${#labels[@]} -eq 0 ]; then
    zenity --error --text="No profiles to remove."
    return
  fi

  local choice
  choice=$(zenity --list --title="scrcpy Launcher" --text="Select a profile to remove:" \
    --column="Mode" --height=$((100 + 30 * ${#labels[@]})) --width=350 \
    -- "${labels[@]}")
  [ -z "$choice" ] && return

  local i
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$choice" ]; then
      zenity --question --title="scrcpy Launcher" \
        --text="Remove \"$choice\" from profiles.conf?" || return
      local tmp_profiles
      tmp_profiles="$(mktemp)"
      grep -vFx -- "${raw_lines[$i]}" "$PROFILES_FILE" > "$tmp_profiles"
      mv "$tmp_profiles" "$PROFILES_FILE"
      zenity --info --text="Removed \"$choice\"."
      return
    fi
  done
}

if [ ! -f "$PROFILES_FILE" ]; then
  zenity --error --text="Profiles file not found:\n$PROFILES_FILE"
  exit 1
fi

while true; do
  labels=()
  resolutions=()
  apps=()
  raw_lines=()

  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line="${raw_line%$'\r'}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    IFS='|' read -r label resolution app <<< "$line"
    labels+=("$label")
    resolutions+=("$resolution")
    apps+=("$app")
    raw_lines+=("$raw_line")
  done < "$PROFILES_FILE"

  CHOICE=$(zenity --list \
    --title="scrcpy Launcher" \
    --text="Choose a mode:" \
    --column="Mode" \
    --height=$((100 + 30 * (${#labels[@]} + 2))) --width=350 \
    -- "${labels[@]}" "$ADD_APP_LABEL" "$REMOVE_APP_LABEL")

  [ -z "$CHOICE" ] && exit 0

  if [ "$CHOICE" = "$ADD_APP_LABEL" ]; then
    add_app
    continue
  fi

  if [ "$CHOICE" = "$REMOVE_APP_LABEL" ]; then
    remove_app
    continue
  fi

  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$CHOICE" ]; then
      resolution="${resolutions[$i]}"
      app="${apps[$i]}"
      if [ -n "$app" ]; then
        scrcpy --new-display="$resolution" --start-app=+"$app" --mouse-bind=+hsn
      else
        scrcpy --new-display="$resolution" --mouse-bind=+hsn
      fi
      exit 0
    fi
  done
done
