#!/bin/bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Kill auto.sh processes
pkill -f "$script_dir/auto.sh"

# Restart swww daemon
swww kill >/dev/null 2>&1 || true
sleep 1

# Load wallpaper
nohup "$script_dir/load.sh" > /dev/null 2>&1 &

echo "Hyprpaper reloaded!"
