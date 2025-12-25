#!/bin/bash

configDir=$HOME/.config/quickshell/caelestia # hypr directory

hyprpaper_conf=$configDir/scripts/WallpaperSwitcher/config       # hyprpaper config
backup=$configDir/scripts/WallpaperSwitcher/config/defaults.conf # backup config

default_wallpapers=$HOME/.config/wallpapers/defaults # default wallpapers directory
custom_wallpapers=$HOME/.config/wallpapers/custom    # custom wallpapers directory
all_wallpapers=$HOME/.config/wallpapers/all          # all wallpapers directory

#################################################

# overwrite /usr/share/backgrounds with all wallpapers
# rm -rf /usr/share/backgrounds/* && cp -r $all_wallpapers/* /usr/share/backgrounds

# echo "Wallpapers for sddm updated!"

#################################################

monitors=$(hyprctl monitors | awk '/Monitor/ {print $2}')

for monitor in $monitors; do
    monitor_conf=$hyprpaper_conf/$monitor/defaults.conf

    if [ ! -s "$monitor_conf" ]; then
        mkdir -p $hyprpaper_conf/$monitor
        cp $backup $monitor_conf

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
pkill -f "auto.sh"

# Start auto wallpaper script
$configDir/scripts/WallpaperSwitcher/auto.sh &

echo "Auto wallpaper script started!"
