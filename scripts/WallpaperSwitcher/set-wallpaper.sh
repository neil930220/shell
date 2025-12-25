#!/bin/bash
configDir=$HOME/.config/quickshell/caelestia 
hyprDir=$HOME/.config/hypr

new_wallpaper=""

#############################################

themesDir="$HOME/.config/caelestia/themes"
activeThemeFile="$themesDir/.active"

pick_random_from_active_theme() {
    local theme=""
    local theme_wall_dir=""

    if [ -f "$activeThemeFile" ]; then
        theme="$(tr -d '\n' < "$activeThemeFile" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    fi
    [ -z "$theme" ] && return 1

    # Strict theme range: only pick from ~/.config/wallpapers/custom/<ThemeName>/
    theme_wall_dir="$HOME/.config/wallpapers/custom/$theme"
    if [ -d "$theme_wall_dir" ]; then
        local picked=""
        picked="$(find "$theme_wall_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1 || true)"
        if [ -n "$picked" ]; then
            printf '%s' "$picked"
            return 0
        fi
    fi

    return 1
}

# check for $1 (workspace_id)
if [ -z "$1" ]; then
    echo "Usage: set-wallpaper.sh <workspace_id> <wallpaper> <monitor>"
    exit 1
else
    echo "Setting random wallpaper for workspace $1"
    workspace_id=$1
fi

# check for $2 (wallpaper)
if [ -z "$2" ]; then
    echo "Setting random wallpaper for workspace $workspace_id"
    if picked="$(pick_random_from_active_theme)"; then
        new_wallpaper=$(echo "$picked" | sed "s|$HOME|\\\$HOME|") # store as \$HOME/...
    else
        new_wallpaper=$(find "$HOME/.config/wallpapers/custom" -type f 2>/dev/null | shuf -n 1 | sed "s|$HOME|\\\$HOME|") # fallback random
    fi
else
    echo "Setting wallpaper $2 for workspace $workspace_id"
    new_wallpaper=$(echo $2 | sed "s|$HOME|\\\$HOME|") # get wallpaper
fi

# check for $3 (monitor)
if [ -z "$3" ]; then
    echo "Usage: set-wallpaper.sh <workspace_id> <wallpaper> <monitor>"
    # monitor=$(hyprctl monitors | awk '/Monitor/ {monitor=$2} /focused: yes/ {print monitor}')
    # echo "Setting wallpaper for monitor $monitor"
    exit 1
else
    monitor=$3
fi

#############################################

current_config=$configDir/scripts/WallpaperSwitcher/config/$monitor/defaults.conf # config file (used by auto.sh)
current_workspace=$(hyprctl monitors | awk -v monitor="$monitor" '/Monitor/ {m=$2} /active workspace/ && m == monitor {print $3}')

#############################################

old_wallpaper=$(grep "^w-${workspace_id}=" "$current_config" | cut -d'=' -f2 | head -n 1)

#check if wallpaper is the same
if [ "$old_wallpaper" = "$new_wallpaper" ]; then
    echo "Wallpaper is already set to $new_wallpaper"
    exit 0
fi

sed -i "s|w-${workspace_id}=.*|w-${workspace_id}=|" $current_config # set wallpaper in config

#############################################

if [ "$workspace_id" = "$current_workspace" ]; then
    $configDir/scripts/WallpaperSwitcher/w.sh "$new_wallpaper" $monitor & # set wallpaper
fi

# #############################################

sed -i "s|w-${workspace_id}=.*|w-${workspace_id}=${new_wallpaper}|" $current_config # set wallpaper in config
