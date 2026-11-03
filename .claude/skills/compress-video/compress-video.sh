#!/bin/bash

# Simple script to run ffmpeg with default options and create output file
# in the same directory with the same name and correct extension
#
# Usage: compress-video [additional ffmpeg options] input_file [input_file...]
# Example: compress-video video.mov               # keeps audio by default
# Example: compress-video -f mp4 video.mov        # convert container to mp4
# Example: compress-video -an -b:v 3000k video.mp4 # drop audio, override bitrate
# Example: compress-video part1.mov part2.mov     # concatenate then compress
#          (multiple inputs must share codec parameters, e.g. same recording setup)

set -e

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [additional ffmpeg options] input_file"
    echo "Example: $0 video.mov"
    echo "Example: $0 -f mp4 video.mov   # convert container to mp4"
    echo "Example: $0 -an -b:v 3000k video.mp4   # drop audio, override bitrate"
    exit 1
fi

# Default ffmpeg options
# Input/global options (before -i)
INPUT_OPTS=(-y)
# Output options (after -i)
OUTPUT_OPTS=(-vf "scale=-2:1080" -r 24 -c:v libx264 -b:v 2500k -preset medium -c:a aac -b:a 192k)

# Collect input files (trailing arguments that are existing files) and
# user options (everything before them). Multiple inputs are concatenated.
args=("$@")
input_files=()
while [ ${#args[@]} -gt 0 ]; do
    last="${args[@]: -1}"
    [ -f "$last" ] || break
    input_files=("$last" "${input_files[@]}")
    args=("${args[@]:0:$((${#args[@]}-1))}")
done
user_opts=("${args[@]}")

if [ ${#input_files[@]} -eq 0 ]; then
    echo "Error: Input file not found: ${@: -1}"
    exit 1
fi

# First input drives the output name and extension
input_file="${input_files[0]}"

# Get directory and filename components
input_dir=$(dirname "$input_file")
input_basename=$(basename "$input_file")
input_name="${input_basename%.*}"
input_ext="${input_basename##*.}"

if [ ${#input_files[@]} -gt 1 ]; then
    input_name="${input_name} combined"
fi

# Determine output extension
# Check if output format is specified in user options (e.g., -f mp4)
output_ext="$input_ext"  # Default to same extension as input
for i in "${!user_opts[@]}"; do
    if [ "${user_opts[$i]}" = "-f" ] && [ $((i+1)) -lt ${#user_opts[@]} ]; then
        output_ext="${user_opts[$((i+1))]}"
        break
    fi
done

# Construct output file path
output_file="${input_dir}/${input_name}.${output_ext}"

# If output file already exists, add a number suffix
counter=1
while [ -f "$output_file" ]; do
    output_file="${input_dir}/${input_name}_${counter}.${output_ext}"
    counter=$((counter + 1))
done

# Build ffmpeg command with correct option order:
# 1. Input/global options (before -i)
# 2. Input file (-i)
# 3. Output options (after -i)
# 4. Output file
ffmpeg_args=("${INPUT_OPTS[@]}")
if [ ${#input_files[@]} -gt 1 ]; then
    # Concatenate via the concat demuxer (requires matching codec parameters)
    concat_list=$(mktemp)
    trap 'rm -f "$concat_list"' EXIT
    for f in "${input_files[@]}"; do
        abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
        printf "file '%s'\n" "${abs//\'/\'\\\'\'}" >> "$concat_list"
    done
    ffmpeg_args+=(-f concat -safe 0 -i "$concat_list")
else
    ffmpeg_args+=(-i "$input_file")
fi
ffmpeg_args+=("${OUTPUT_OPTS[@]}")
ffmpeg_args+=("${user_opts[@]}")
ffmpeg_args+=("$output_file")

# Run ffmpeg
for f in "${input_files[@]}"; do
    echo "Processing: $(basename "$f")"
done
echo "Output: $(basename "$output_file")"
echo ""
ffmpeg "${ffmpeg_args[@]}"

echo ""
echo "✅ Complete! Output saved to: $output_file"
