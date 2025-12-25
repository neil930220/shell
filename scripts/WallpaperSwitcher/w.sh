#!/bin/bash

# Define variables
hyprdir=$HOME/.config/quickshell/caelestia/scripts/WallpaperSwitcher
wallpaper=$1 # This is passed as an argument to the script
monitor=$2
fps=144
dur=0.8        # seconds
effect="wipe"   # grow | wave | wipe | fade | any …

ensure_swww_daemon() {
    # Prefer a real query over pgrep: it proves the socket is reachable in this environment.
    if swww query >/dev/null 2>&1; then
        return 0
    fi

    # Start daemon (idempotent enough; if it's already running, query above would have succeeded).
    swww-daemon --format xrgb >/dev/null 2>&1 &
    disown || true

    # Give the daemon a moment to create the socket.
    for _ in {1..40}; do
        if swww query >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.05
    done

    echo "Error: swww-daemon is not reachable. Try starting it manually: swww-daemon" >&2
    return 1
}

# Expand the wallpaper path.
# Your config commonly stores wallpaper paths as '\$HOME/...' (escaped), so handle both forms.
wallpaper="${wallpaper//\\\$HOME/$HOME}"
wallpaper="${wallpaper//\$HOME/$HOME}"
wallpaper="${wallpaper/#\~/$HOME}"

# Check if wallpaper file exists
if [ ! -f "$wallpaper" ]; then
    echo "Warning: Wallpaper file not found: $wallpaper"
    exit 1
fi

# Ensure daemon is up before sending the image
ensure_swww_daemon || exit 1

# Set wallpaper using swww
swww img -o "$monitor" "$wallpaper" \
        --transition-type "$effect" \
        --transition-fps  "$fps" \
        --transition-duration "$dur" \
        --transition-pos center \
        --resize crop &

# Set wallpaper theme (only if wal is available)
if command -v wal >/dev/null 2>&1; then
    if [ -x "$hyprdir/wal-theme.sh" ]; then
    "$hyprdir/wal-theme.sh" "$wallpaper"
    else
        echo "Note: wal-theme.sh not found in $hyprdir, skipping theme generation"
    fi
else
    echo "Note: pywal not found, skipping theme generation"
fi