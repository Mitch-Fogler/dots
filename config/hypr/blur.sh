#!/bin/bash

# Get the current wallpaper file path using waypaper --list
current_wallpaper=$(waypaper --list | jq -r '.[0].wallpaper')

# Check if we got a valid wallpaper path
if [ -z "$current_wallpaper" ]; then
  echo "No wallpaper found. Ensure that Waypaper is installed and you have a wallpaper set."
  exit 1
fi

# Extract the filename and extension from the wallpaper path
filename=$(basename "$current_wallpaper")
extension="png"
basename="${filename%.*}"

# Define the output file path
output_path="$HOME/background/blur.$extension"

# Create the ~/background/ directory if it doesn't exist
mkdir -p "$HOME/background"

# Apply the Gaussian blur and save the new image
convert "$current_wallpaper" -filter Gaussian -blur 0x30 "$output_path"

echo "Blurred background saved to $output_path"
