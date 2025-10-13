#!/bin/bash

# Get list of subfolders in custom wallpapers directory
custom_wallpapers="$HOME/.config/wallpapers/custom"

if [ ! -d "$custom_wallpapers" ]; then
    echo "[]"
    exit 0
fi

# Find all subdirectories (depth 1 only)
folders=()
while IFS= read -r -d '' dir; do
    # Get just the folder name (basename)
    folder_name=$(basename "$dir")
    folders+=("$folder_name")
done < <(find "$custom_wallpapers" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

# Convert to JSON array
printf '%s\n' "${folders[@]}" | jq -R . | jq -s .

