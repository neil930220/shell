#!/bin/bash

set -euo pipefail

hyprDir="$HOME/.config/hypr"
theme_script="$hyprDir/theme/scripts/system-theme.sh"

current_wallpaper="${1:-}"

if [ -z "$current_wallpaper" ]; then
    # Fallback: try to read the currently displayed image from swww
    current_wallpaper="$(swww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n 1 || true)"
fi

# Expand common forms ($HOME, \$HOME, ~)
current_wallpaper="${current_wallpaper//\\\$HOME/$HOME}"
current_wallpaper="${current_wallpaper//\$HOME/$HOME}"
current_wallpaper="${current_wallpaper/#\~/$HOME}"

if [ -z "$current_wallpaper" ] || [ ! -f "$current_wallpaper" ]; then
    echo "wal-theme: no valid wallpaper path available, skipping" >&2
    exit 0
fi

# Determine system theme (default to dark if script missing)
current_theme="dark"
if [ -x "$theme_script" ]; then
    current_theme="$(bash "$theme_script" get 2>/dev/null || echo "dark")"
fi

# Stop any running wal instances (ignore if none)
pkill -x wal >/dev/null 2>&1 || true

if [ "$current_theme" = "dark" ]; then

    wal --backend colorthief -e -n -i "$current_wallpaper" >/dev/null 2>&1

elif [ "$current_theme" = "light" ]; then

    wal --backend colorthief -e -n -i "$current_wallpaper" -l >/dev/null 2>&1
fi

# pywalfox update
