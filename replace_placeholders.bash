#!/bin/bash

set -euf -o pipefail

VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")

# Display version if requested
if [ "$#" -eq 1 ] && { [ "$1" = "--version" ] || [ "$1" = "-V" ]; }; then
  echo "$SCRIPT_NAME version $VERSION"
  exit 0
fi
# Display help message if requested
if [ "$#" -eq 1 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ]; }; then
  cat << EOF
Usage: $SCRIPT_NAME mapping_file input_file

Replace placeholders in the input file with values from the mapping file.

Mapping file:
  Each line should be in the format: key=value

Input file:
  Should contain placeholders in the format:
  <placeholder>key</placeholder>

Options:
  -h, --help       Display this help and exit.
  -V, --version    Output version information and exit.
EOF
  exit 0
fi

# Check for the correct number of arguments.
if [ "$#" -ne 2 ]; then
  echo "Error: Incorrect number of arguments." >&2
  echo "Usage: $SCRIPT_NAME mapping_file input_file" >&2
  echo "Try '$SCRIPT_NAME --help' for more information." >&2
  exit 1
fi

mapping_file="$1"
input_file="$2"

# Read the mapping file into an associative array.
declare -A map=()
while IFS='=' read -r key value; do
    # Skip empty lines or lines without both key and value.
    [[ -z "$key" || -z "$value" ]] && continue
    map["$key"]="$value"
done < "$mapping_file"

# First pass: scan the input file for placeholders and record any missing keys.
declare -A missing_keys=()
while IFS= read -r line; do
    tmp="$line"
    # Match the <placeholder>key</placeholder> pattern.
    while [[ $tmp =~ \<placeholder\>([A-Za-z0-9_]+)\</placeholder\> ]]; do
        key="${BASH_REMATCH[1]}"
        if [[ -z "${map[$key]:-}" ]]; then
            missing_keys["$key"]=1
        fi
        # Remove the processed portion of the line.
        tmp="${tmp#*<placeholder>"${key}"</placeholder>}"
    done
done < "$input_file"

# If any placeholders are missing a mapping, report them and exit with a nonzero status.
if (( ${#missing_keys[@]} > 0 )); then
    echo "Error: The following placeholder keys were not found in the mapping file:" >&2
    for k in "${!missing_keys[@]}"; do
       echo "  $k" >&2
    done
    exit 1
fi

# Second pass: process the input file, perform the replacements, and write to a temporary file.
temp_file=$(mktemp)
# Set a trap to clean up temporary files on exit.
trap 'rm -f "$temp_file"' EXIT

while IFS= read -r line; do
    # Match and replace each placeholder.
    while [[ $line =~ (\<placeholder\>([A-Za-z0-9_]+)\</placeholder\>) ]]; do
        full="${BASH_REMATCH[1]}"
        key="${BASH_REMATCH[2]}"
        replacement="${map[$key]}"
        line="${line//$full/$replacement}"
    done
    echo "$line" >> "$temp_file"
done < "$input_file"

# Replace the original input file with the updated file.
mv "$temp_file" "$input_file"

# Clear trap
trap - EXIT
