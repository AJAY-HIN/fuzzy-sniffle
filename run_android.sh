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
    echo "Please download Godot 4 from https://godotengine.org/ and install it."
    echo "========================================================================="
    exit 1
fi

# Check if ADB sees any devices/emulators running
if command -v adb &> /dev/null; then
    RUNNING_DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$")
    if [ -z "$RUNNING_DEVICES" ]; then
        echo "Warning: No running Android emulators or connected devices detected."
        echo "Make sure your Android Simulator (AVD) is running before starting."
    fi
else
    echo "Warning: adb command not found. Ensure Android Platform Tools are installed."
fi

echo "Importing assets (first-time setup)..."
"$GODOT_PATH" --path . --editor --quit --headless

echo "Deploying and running on connected Android emulator/device..."
"$GODOT_PATH" --path . --deploy-with-debug --run-android
