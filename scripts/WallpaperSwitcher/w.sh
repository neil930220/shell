#!/bin/bash

# Define variables
hyprdir=$HOME/.config/quickshell/caelestia/scripts/WallpaperSwitcher
wallpaper=$1 # This is passed as an argument to the script
monitor=$2
fps=144
dur=0.8        # seconds
effect="wipe"   # grow | wave | wipe | fade | any …

# Expand the wallpaper path if it contains $HOME
wallpaper=$(eval echo "$wallpaper")

# Check if wallpaper file exists
if [ ! -f "$wallpaper" ]; then
    echo "Warning: Wallpaper file not found: $wallpaper"
    exit 1
fi

# Set wallpaper using swww
swww img -o "$monitor" "$wallpaper" \
        --transition-type "$effect" \
        --transition-fps  "$fps" \
        --transition-duration "$dur" \
        --transition-pos center \
        --resize crop &

# Set wallpaper theme (only if wal is available)
if command -v wal >/dev/null 2>&1; then
    "$hyprdir/wal-theme.sh" "$wallpaper"
else
    echo "Note: pywal not found, skipping theme generation"
fi