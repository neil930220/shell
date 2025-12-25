#!/bin/bash

# Get list of subfolders in custom wallpapers directory
custom_wallpapers="$HOME/.config/wallpapers/custom"

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
printf '%s\n' "${folders[@]}" | to_json_array

