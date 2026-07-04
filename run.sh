#!/bin/bash

# Find Godot executable
GODOT_PATH=""

if command -v godot &> /dev/null; then
    GODOT_PATH="godot"
elif [ -d "/Applications/Godot.app" ]; then
    GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -d "/Applications/Godot_mono.app" ]; then
    GODOT_PATH="/Applications/Godot_mono.app/Contents/MacOS/Godot"
else
    # Search Downloads and Applications folders for any executable named "Godot"
    echo "Searching for Godot executable..."
    GODOT_PATH=$(find ~/Downloads ~/Applications /Applications -name "Godot" -type f -perm +111 -maxdepth 4 -print -quit 2>/dev/null)
fi

if [ -z "$GODOT_PATH" ]; then
    echo "========================================================================="
    echo "Error: Godot engine was not found on your system."
    echo "Please download Godot 4 from https://godotengine.org/ and:"
    echo "1. Drag it to your /Applications folder, OR"
    echo "2. Keep the extracted app in your Downloads folder."
    echo "========================================================================="
    exit 1
fi

echo "Importing assets (first-time setup)..."
"$GODOT_PATH" --path . --editor --quit --headless

echo "Starting game simulator using: $GODOT_PATH"
"$GODOT_PATH" --path .
