#!/bin/bash

configDir=$HOME/.config/quickshell/caelestia                       # hypr directory
defaults=$configDir/scripts/WallpaperSwitcher/config/defaults.conf # config file

declare -A previous_workspace_ids
declare -A current_wallpapers

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
        local wallpaper=""
        
        if [ -f "$monitor_config" ]; then
            wallpaper=$(awk -F= -v wsid="w-$workspace_id" '$1 == wsid {print $2}' "$monitor_config")
        else
            # Fallback to global defaults if monitor-specific config doesn't exist
            wallpaper=$(awk -F= -v wsid="w-$workspace_id" '$1 == wsid {print $2}' "$defaults")
        fi

        # Check if wallpaper is valid and has changed
        if [ "$wallpaper" ] && [ "$wallpaper" != "${current_wallpapers[$monitor]}" ]; then
            # Run the wallpaper script with the new wallpaper
            $configDir/scripts/WallpaperSwitcher/w.sh "$wallpaper" "$monitor" &

            # Update current wallpaper and workspace ID for this monitor
            current_wallpapers[$monitor]=$wallpaper
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

