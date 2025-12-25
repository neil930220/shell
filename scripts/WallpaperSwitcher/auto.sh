#!/bin/bash

configDir=$HOME/.config/quickshell/caelestia                       # hypr directory
defaults=$configDir/scripts/WallpaperSwitcher/config/defaults.conf # config file

declare -A previous_workspace_ids
declare -A current_wallpapers

expand_path() {
    local p="$1"
    p="${p//\\\$HOME/$HOME}"
    p="${p//\$HOME/$HOME}"
    p="${p/#\~/$HOME}"
    printf '%s' "$p"
}

store_home_path() {
    local p="$1"
    if [[ "$p" == "$HOME"* ]]; then
        printf '%s' "\$HOME${p#$HOME}"
    else
        printf '%s' "$p"
    fi
}

resolve_wallpaper() {
    # Tries to turn a config entry into a real existing file path.
    local raw="$1"
    local expanded
    expanded="$(expand_path "$raw")"
    if [ -n "$expanded" ] && [ -f "$expanded" ]; then
        printf '%s' "$expanded"
        return 0
    fi

    # If the configured path is missing, try to find by basename under custom/
    local base
    base="$(basename "$expanded")"
    local found=""
    if [ -n "$base" ]; then
        found="$(find "$HOME/.config/wallpapers/custom" -type f -name "$base" -print -quit 2>/dev/null || true)"
    fi
    if [ -n "$found" ] && [ -f "$found" ]; then
        printf '%s' "$found"
        return 0
    fi

    return 1
}

pick_random_wallpaper() {
    local themes_dir="$HOME/.config/caelestia/themes"
    local active_file="$themes_dir/.active"
    local theme=""

    if [ -f "$active_file" ]; then
        theme="$(tr -d '\n' < "$active_file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    fi

    # Prefer folder that matches the active theme name
    if [ -n "$theme" ] && [ -d "$HOME/.config/wallpapers/custom/$theme" ]; then
        local picked=""
        picked="$(find "$HOME/.config/wallpapers/custom/$theme" -type f 2>/dev/null | shuf -n 1 || true)"
        if [ -n "$picked" ]; then
            printf '%s' "$picked"
            return 0
        fi
    fi

    # Fallback: any custom wallpaper
    find "$HOME/.config/wallpapers/custom" -type f 2>/dev/null | shuf -n 1
}

update_config_wallpaper() {
    local config_file="$1"
    local wsid="$2"
    local path_to_store="$3"

    if grep -q "^w-${wsid}=" "$config_file"; then
        sed -i "s|^w-${wsid}=.*|w-${wsid}=${path_to_store}|" "$config_file"
    else
        echo "w-${wsid}=${path_to_store}" >> "$config_file"
    fi
}

change_wallpaper() {
    # Get all monitors and their active workspaces
    local monitors=$(hyprctl monitors | awk '/Monitor/ {print $2}')

    for monitor in $monitors; do
        local workspace_id=$(hyprctl monitors | awk -v monitor="$monitor" '/Monitor/ {m=$2} /active workspace/ && m == monitor {print $3}')

        # If workspace hasn't changed, skip the rest of the function for this monitor
        if [ "${previous_workspace_ids[$monitor]}" == "$workspace_id" ]; then
            continue
        fi

        # Get the wallpaper from the monitor-specific config file
        local monitor_config="$configDir/scripts/WallpaperSwitcher/config/$monitor/defaults.conf"
        local wallpaper_raw=""
        local wallpaper_resolved=""
        
        if [ -f "$monitor_config" ]; then
            wallpaper_raw=$(awk -F= -v wsid="w-$workspace_id" '$1 == wsid {print $2}' "$monitor_config")
        else
            # Fallback to global defaults if monitor-specific config doesn't exist
            wallpaper_raw=$(awk -F= -v wsid="w-$workspace_id" '$1 == wsid {print $2}' "$defaults")
        fi

        # Resolve (and self-heal) missing wallpaper entries
        if wallpaper_resolved="$(resolve_wallpaper "$wallpaper_raw")"; then
            :
        else
            wallpaper_resolved="$(pick_random_wallpaper)"
            if [ -n "$wallpaper_resolved" ]; then
                update_config_wallpaper "$monitor_config" "$workspace_id" "$(store_home_path "$wallpaper_resolved")"
                echo "Wallpaper missing for $monitor ws $workspace_id; updated config to $(store_home_path "$wallpaper_resolved")"
            fi
        fi

        # Check if wallpaper is valid and has changed (compare resolved paths)
        if [ -n "$wallpaper_resolved" ] && [ "$wallpaper_resolved" != "${current_wallpapers[$monitor]}" ]; then
            # Run the wallpaper script with the new wallpaper
            $configDir/scripts/WallpaperSwitcher/w.sh "$wallpaper_resolved" "$monitor" &

            # Update current wallpaper and workspace ID for this monitor
            current_wallpapers[$monitor]=$wallpaper_resolved
            previous_workspace_ids[$monitor]=$workspace_id
            echo "Wallpaper changed for monitor $monitor to workspace $workspace_id"
        fi
    done
}

# Initial wallpaper setup
change_wallpaper

# Listen to workspace changes via Hyprland socket
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    # Only trigger wallpaper change on workspace events
    if [[ $line == *"workspace>>"* ]]; then
        change_wallpaper
    fi
done

