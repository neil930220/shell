#!/bin/bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
hyprpaper_conf="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/wallpaper-switcher"
backup="$hyprpaper_conf/defaults.conf"

default_wallpapers=$HOME/.config/wallpapers/defaults # default wallpapers directory
custom_wallpapers=$HOME/.config/wallpapers/custom    # custom wallpapers directory
all_wallpapers=$HOME/.config/wallpapers/all          # all wallpapers directory

#################################################

# overwrite /usr/share/backgrounds with all wallpapers
# rm -rf /usr/share/backgrounds/* && cp -r $all_wallpapers/* /usr/share/backgrounds

# echo "Wallpapers for sddm updated!"

#################################################

monitors=$(hyprctl monitors | awk '/Monitor/ {print $2}')

mkdir -p "$hyprpaper_conf"
if [ ! -f "$backup" ]; then
    if [ -f "$script_dir/config/defaults.conf" ]; then
        cp "$script_dir/config/defaults.conf" "$backup"
    else
        for workspace in {1..10}; do
            printf 'w-%s=\n' "$workspace"
        done > "$backup"
    fi
fi

for monitor in $monitors; do
    monitor_conf=$hyprpaper_conf/$monitor/defaults.conf

    if [ ! -s "$monitor_conf" ]; then
        mkdir -p "$hyprpaper_conf/$monitor"
        if [ -f "$script_dir/config/$monitor/defaults.conf" ]; then
            cp "$script_dir/config/$monitor/defaults.conf" "$monitor_conf"
        else
            cp "$backup" "$monitor_conf"
        fi

        echo "Config file created! for $monitor"
    fi
done

echo "Config files created!"

#################################################

# Ensure swww daemon is running (it does NOT auto-start on first use)
if ! swww query >/dev/null 2>&1; then
    swww-daemon --format xrgb >/dev/null 2>&1 &
    disown || true
fi

#################################################

# Kill any existing auto.sh processes
pkill -f "$script_dir/auto.sh"

# Start auto wallpaper script
"$script_dir/auto.sh" &

echo "Auto wallpaper script started!"
