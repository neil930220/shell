#!/bin/bash

# Directories
default_wallpapers="$HOME/.config/wallpapers/defaults"
custom_wallpapers="$HOME/.config/wallpapers/custom"
all_wallpapers="$HOME/.config/wallpapers/all"
hyprDir="$HOME/.config/hypr"

# Parse arguments
case "$1" in
    --defaults)
        if [ -d "$default_wallpapers" ]; then
            find "$default_wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | jq -R . | jq -s .
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
                find "$custom_wallpapers/$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | jq -R . | jq -s .
            else
                find "$custom_wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | jq -R . | jq -s .
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
        printf '%s\n' "${wallpapers[@]}" | jq -R . | jq -s .
        ;;
    --current)
        # Get current wallpapers for each workspace on specified monitor
        if [ -z "$2" ]; then
            echo "[]"
            exit 1
        fi
        
        monitor="$2"
        monitor_conf="$hyprDir/hyprpaper/config/$monitor/defaults.conf"
        
        # If monitor config doesn't exist, use global defaults
        if [ ! -f "$monitor_conf" ]; then
            monitor_conf="$hyprDir/hyprpaper/config/defaults.conf"
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
        
        printf '%s\n' "${wallpapers[@]}" | jq -R . | jq -s .
        ;;
    *)
        echo "Usage: $0 {--defaults|--custom [--folder <name>]|--all [--folder <name>]|--current <monitor>}"
        exit 1
        ;;
esac

