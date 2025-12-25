#!/bin/bash
configDir=$HOME/.config/quickshell/caelestia  # hypr directory

# Kill auto.sh processes
pkill -f "auto.sh"

# Restart swww daemon
swww kill >/dev/null 2>&1 || true
sleep 1

# Load wallpaper
nohup $configDir/scripts/WallpaperSwitcher/load.sh > /dev/null 2>&1 &

echo "Hyprpaper reloaded!"
