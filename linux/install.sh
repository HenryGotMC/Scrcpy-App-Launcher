#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER_SCRIPT="$SCRIPT_DIR/scrcpy-menu.sh"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/scrcpy-menu.desktop"

echo "Checking dependencies..."
missing=()
for cmd in scrcpy adb zenity; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ ${#missing[@]} -ne 0 ]; then
  echo "Missing required commands: ${missing[*]}"
  echo "Install them with your distro's package manager, then re-run this script."
  exit 1
fi

chmod +x "$LAUNCHER_SCRIPT"

mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Scrcpy App Launcher
Comment=Launch scrcpy for manga reading or show watching
Exec="$LAUNCHER_SCRIPT"
Icon=scrcpy
Terminal=false
Type=Application
Categories=Utility;
EOF

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR"

echo "Installed. Look for 'Scrcpy App Launcher' in your application launcher."
echo "Edit $SCRIPT_DIR/../profiles.conf to add your own resolutions and app package names."
