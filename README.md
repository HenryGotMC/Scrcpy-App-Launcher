
# Scrcpy Manga & Anime Launcher

A tiny menu launcher for [scrcpy](https://github.com/Genymobile/scrcpy) that opens a secondary virtual display on your Android device at a preset resolution and automatically launches a manga or anime app into it.

Pick a mode from a popup menu, built from a `profiles.conf` file you can freely edit — add as many entries as you like, each with its own resolution and app to auto-launch. Ships with two example profiles:

- **Manga** — opens a 720x1440 portrait virtual display and launches YouTube
- **Shows** — opens a 2560x1440 landscape virtual display and launches Netflix

Available for both Linux and Windows 11.

## Requirements

- [scrcpy](https://github.com/Genymobile/scrcpy) v2.4+ (needs `--new-display` and `--start-app` support) and `adb`, both reachable on your `PATH`
- An Android device with USB debugging enabled in Developer Options, connected via a USB **data** cable (not charge-only) or Wi-Fi ADB
- **Linux:** a desktop environment or app launcher that reads `.desktop` files (tested on Hyprland with wofi/fuzzel), plus `zenity`
- **Windows 11:** PowerShell (built in)

## Installation

### Linux

```bash
git clone git@github.com:HenryGotMC/Scrcpy-App-Launcher.git
cd Scrcpy-App-Launcher/linux
./install.sh
```

This checks for `scrcpy`, `adb`, and `zenity`, then creates a "Scrcpy Manga/Shows" entry in your application launcher.

### Windows 11

```powershell
git clone git@github.com:HenryGotMC/Scrcpy-App-Launcher.git
cd Scrcpy-App-Launcher\windows
.\install.ps1
```

If PowerShell blocks the script from running, either run it from a shell started with
`powershell -ExecutionPolicy Bypass` or allow local scripts for your user with
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

This checks for `scrcpy` and `adb` on your `PATH`, then adds a "Scrcpy Manga-Shows" shortcut to your Start Menu (it runs the menu without flashing a console window).

## Configuration

Both platforms read the same `profiles.conf` file at the repo root. Each line is one menu entry:

```
Label|Resolution|Package
```

```
Manga (720x1440 portrait)|720x1440/280|com.google.android.youtube
Shows (2560x1440 landscape)|2560x1440|com.netflix.mediaclient
```

- **Label** — text shown in the menu.
- **Resolution** — passed to `scrcpy --new-display=`, format `WIDTHxHEIGHT[/DPI]` (see `scrcpy --help` under `--new-display`).
- **Package** — the exact Android package name to auto-launch. Leave it blank (`Label|Resolution|`) to just open the display with no app. Find a package name with:
  ```bash
  adb shell pm list packages | grep -i <part of app name>
  ```

Add, remove, or edit lines to add your own apps/resolutions — no script editing required. Lines starting with `#` and blank lines are ignored.

### Adding an app from the menu (Linux)

Instead of editing `profiles.conf` by hand, the Linux menu has a **"+ Add new app..."** entry at the bottom of the list. Picking it will:

1. Scan the connected device for installed apps (via `scrcpy --list-apps`) and show them in a searchable list.
2. Let you pick a resolution from a few common presets, or enter a custom `WIDTHxHEIGHT[/DPI]` value.
3. Ask for a menu label (defaults to the app's name).
4. Append the new profile to `profiles.conf` and return to the menu so you can launch it immediately.

This requires a device connected over ADB at the time (the same requirement as launching a profile).

### Removing an app from the menu (Linux)

The Linux menu also has a **"- Remove app..."** entry. Picking it shows your current profiles, asks you to confirm, then deletes that line from `profiles.conf`.

## Usage

Launch "Scrcpy Manga/Shows" (Linux) or "Scrcpy Manga-Shows" (Windows) from your app launcher / Start Menu, pick Manga or Shows, and scrcpy opens the virtual display with the app already running on it.

## Troubleshooting

- **"Could not find any ADB device"** — run `adb devices -l`. If nothing is listed, check the USB cable (it must support data, not charge-only) and confirm USB debugging is enabled in the phone's Developer Options.
- **Device shows up in `lsusb` (Linux) but not in `adb devices`** — USB debugging isn't enabled/authorized on that device yet. On the device: enable Developer Options → USB debugging, replug the cable, and accept the "Allow USB debugging?" prompt on the device's screen.
- **Windows: nothing happens when launching the shortcut** — run `windows\scrcpy-menu.ps1` directly in a PowerShell window (not via the shortcut) to see any error output.
- **Linux: the menu fails instantly with "This option is not available"** — a label in `profiles.conf` starts with a `-`. Zenity's argument parser can mistake a leading dash for a command-line flag; avoid starting a profile label with `-` (a leading `+` or other characters are fine).

## Uninstall

- **Linux:** `rm ~/.local/share/applications/scrcpy-menu.desktop`
- **Windows:** delete the "Scrcpy Manga-Shows" shortcut from the Start Menu (`shell:programs`)
