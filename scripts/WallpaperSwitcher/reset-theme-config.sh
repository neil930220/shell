#!/bin/bash
set -euo pipefail

# Reset WallpaperSwitcher per-monitor defaults.conf based on an active theme.
#
# Behavior:
# - For each connected monitor, rewrite `scripts/WallpaperSwitcher/config/<monitor>/defaults.conf`
# - For workspaces 1..10:
#   - If theme.json has wallpapers["N"] and the file is under custom/<theme>/, use it
#   - Else pick a random image from custom/<theme>/
# - Stores paths in config as `$HOME/...` (so configs are portable)

configDir="$HOME/.config/quickshell/caelestia"
switcherConfigDir="$configDir/scripts/WallpaperSwitcher/config"

themesDir="$HOME/.config/caelestia/themes"
activeFile="$themesDir/.active"

theme="${1:-}"
if [ -z "$theme" ] && [ -f "$activeFile" ]; then
    theme="$(tr -d '\n' < "$activeFile" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
fi

if [ -z "$theme" ]; then
    echo "reset-theme-config: no active theme (missing $activeFile) and no theme arg provided" >&2
    exit 1
fi

themeDir="$HOME/.config/wallpapers/custom/$theme"
if [ ! -d "$themeDir" ]; then
    echo "reset-theme-config: theme wallpaper dir not found: $themeDir" >&2
    exit 1
fi

themeJson=""
if [ -f "$themesDir/$theme/theme.json" ]; then
    themeJson="$themesDir/$theme/theme.json"
elif [ -f "$themesDir/$theme.json" ]; then
    themeJson="$themesDir/$theme.json"
fi

store_home_path() {
    local p="$1"
    if [[ "$p" == "$HOME"* ]]; then
        printf '%s' "\$HOME${p#$HOME}"
    else
        printf '%s' "$p"
    fi
}

pick_random_from_theme_dir() {
    find "$themeDir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1
}

get_theme_wallpaper_for_ws() {
    local ws="$1"
    [ -z "$themeJson" ] && return 1

    local raw=""
    if command -v jq >/dev/null 2>&1; then
        raw="$(jq -r --arg k "$ws" '.wallpapers[$k] // ""' "$themeJson" 2>/dev/null || true)"
    else
        raw="$(python3 - "$themeJson" "$ws" <<'PY' 2>/dev/null || true
import json, sys
path, k = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    obj = json.load(f)
print((obj.get("wallpapers") or {}).get(k, "") or "")
PY
)"
    fi

    [ -z "$raw" ] && return 1
    raw="${raw//\\\$HOME/$HOME}"
    raw="${raw//\$HOME/$HOME}"
    raw="${raw/#\~/$HOME}"

    # Strict "theme range": only allow files inside custom/<theme>/
    case "$raw" in
        "$themeDir"/*)
            [ -f "$raw" ] && printf '%s' "$raw" && return 0
            ;;
    esac
    return 1
}

monitors="$(hyprctl monitors | awk '/Monitor/ {print $2}')"
if [ -z "$monitors" ]; then
    echo "reset-theme-config: no monitors found (is Hyprland running?)" >&2
    exit 1
fi

for monitor in $monitors; do
    outDir="$switcherConfigDir/$monitor"
    outFile="$outDir/defaults.conf"
    mkdir -p "$outDir"

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    for i in {1..10}; do
        chosen=""
        if chosen="$(get_theme_wallpaper_for_ws "$i")"; then
            :
        else
            chosen="$(pick_random_from_theme_dir || true)"
        fi
        echo "w-$i=$(store_home_path "$chosen")" >> "$tmp"
    done

    mv -f "$tmp" "$outFile"
    trap - EXIT
done

echo "reset-theme-config: updated configs for theme '$theme'"


