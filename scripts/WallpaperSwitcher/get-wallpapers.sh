#!/bin/bash

# Directories
default_wallpapers="$HOME/.config/wallpapers/defaults"
custom_wallpapers="$HOME/.config/wallpapers/custom"
all_wallpapers="$HOME/.config/wallpapers/all"
switcher_conf_dir="$HOME/.config/quickshell/caelestia/scripts/WallpaperSwitcher/config"
hyprDir="$HOME/.config/hypr"

to_json_array() {
    # Reads newline-delimited strings from stdin and prints a JSON array.
    if command -v jq >/dev/null 2>&1; then
        jq -R . | jq -s .
    else
        python3 - <<'PY'
import json, sys
items = [line.rstrip("\n") for line in sys.stdin]
print(json.dumps(items))
PY
    fi
}

# Parse arguments
case "$1" in
    --defaults)
        if [ -d "$default_wallpapers" ]; then
            find "$default_wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | to_json_array
        else
            echo "[]"
        fi
        ;;
    --custom)
        folder=""
        # Optional: --folder <name>
        if [ "$2" = "--folder" ] && [ -n "$3" ]; then
            folder="$3"
        fi

        if [ -d "$custom_wallpapers" ]; then
            if [ -n "$folder" ] && [ -d "$custom_wallpapers/$folder" ]; then
                find "$custom_wallpapers/$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | to_json_array
            else
                find "$custom_wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | to_json_array
            fi
        else
            echo "[]"
        fi
        ;;
    --all)
        folder=""
        # Optional: --folder <name>
        if [ "$2" = "--folder" ] && [ -n "$3" ]; then
            folder="$3"
        fi

        wallpapers=()
        if [ -d "$default_wallpapers" ]; then
            while IFS= read -r -d '' file; do
                wallpapers+=("$file")
            done < <(find "$default_wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0)
        fi
        if [ -d "$custom_wallpapers" ]; then
            if [ -n "$folder" ] && [ -d "$custom_wallpapers/$folder" ]; then
                while IFS= read -r -d '' file; do
                    wallpapers+=("$file")
                done < <(find "$custom_wallpapers/$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0)
            else
                while IFS= read -r -d '' file; do
                    wallpapers+=("$file")
                done < <(find "$custom_wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0)
            fi
        fi
        printf '%s\n' "${wallpapers[@]}" | to_json_array
        ;;
    --current)
        # Get current wallpapers for each workspace on specified monitor
        if [ -z "$2" ]; then
            echo "[]"
            exit 1
        fi
        
        monitor="$2"
        # Prefer WallpaperSwitcher config (this repo uses swww + scripts/WallpaperSwitcher/config/*)
        monitor_conf="$switcher_conf_dir/$monitor/defaults.conf"
        
        # Fallback to global defaults if monitor-specific config doesn't exist
        if [ ! -f "$monitor_conf" ]; then
            monitor_conf="$switcher_conf_dir/defaults.conf"
        fi

        # Legacy fallback: older configs used hyprpaper paths
        if [ ! -f "$monitor_conf" ]; then
            monitor_conf="$hyprDir/hyprpaper/config/$monitor/defaults.conf"
        if [ ! -f "$monitor_conf" ]; then
            monitor_conf="$hyprDir/hyprpaper/config/defaults.conf"
            fi
        fi
        
        if [ ! -f "$monitor_conf" ]; then
            echo "[]"
            exit 0
        fi
        
        # Read wallpapers for workspaces 1-10
        wallpapers=()
        for i in {1..10}; do
            wallpaper=$(grep "^w-${i}=" "$monitor_conf" | cut -d'=' -f2)
            # Expand $HOME variable if present
            wallpaper=$(eval echo "$wallpaper")
            wallpapers+=("$wallpaper")
        done
        
        printf '%s\n' "${wallpapers[@]}" | to_json_array
        ;;
    *)
        echo "Usage: $0 {--defaults|--custom [--folder <name>]|--all [--folder <name>]|--current <monitor>}"
        exit 1
        ;;
esac

