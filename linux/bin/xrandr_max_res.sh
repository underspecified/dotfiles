#!/bin/bash

# Script to set the highest available resolution for connected displays

set -euo pipefail

# Function to get the highest resolution for a given output
get_max_resolution() {
    local output="$1"
    
    # Get all resolutions for this output, extract resolution part, sort by pixels
    xrandr --query | \
    awk -v output="$output" '
    # Found the output section
    /^[A-Za-z]/ { current_output = $1; next }
    
    # If we are in the right output section and line contains resolution
    current_output == output && /^[[:space:]]+[0-9]+x[0-9]+/ {
        # Extract resolution (first field after whitespace)
        split($1, res, "x")
        width = res[1]
        height = res[2]
        pixels = width * height
        
        # Store resolution with pixel count for sorting
        print pixels " " $1
    }' | \
    sort -rn | \
    head -1 | \
    cut -d' ' -f2
}

# Function to check if output is connected
is_connected() {
    local output="$1"
    xrandr --query | grep "^$output connected" > /dev/null
}

# Get all connected outputs
connected_outputs=$(xrandr --query | grep " connected" | cut -d' ' -f1)

if [[ -z "$connected_outputs" ]]; then
    echo "Error: No connected displays found"
    exit 1
fi

echo "Connected displays found:"
echo "$connected_outputs"
echo

# Process each connected output
for output in $connected_outputs; do
    echo "Processing $output..."
    
    if ! is_connected "$output"; then
        echo "  Skipping $output (not connected)"
        continue
    fi
    
    max_res=$(get_max_resolution "$output")
    
    if [[ -z "$max_res" ]]; then
        echo "  Warning: Could not determine maximum resolution for $output"
        continue
    fi
    
    echo "  Current maximum resolution: $max_res"
    
    # Check if this resolution is already active
    current_res=$(xrandr --query | grep "^$output" | grep -o '[0-9]\+x[0-9]\+' | head -1)
    
    if [[ "$current_res" == "$max_res" ]]; then
        echo "  $output is already at maximum resolution ($max_res)"
    else
        echo "  Setting $output to $max_res..."
        
        if xrandr --output "$output" --mode "$max_res"; then
            echo "  ✓ Successfully set $output to $max_res"
        else
            echo "  ✗ Failed to set $output to $max_res"
        fi
    fi
    
    echo
done

echo "Done!"
