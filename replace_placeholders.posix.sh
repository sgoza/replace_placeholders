#!/bin/sh

set -eu

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

# Check for missing keys:
# Extract all unique keys from the input file.
keys=$(grep -o '<placeholder>[A-Za-z0-9_]\+</placeholder>' "$input_file" \
         | sed 's#<placeholder>\(.*\)</placeholder>#\1#' | sort -u)

missing=0
for key in $keys; do
    # Check if the mapping file contains a line starting with key=
    if ! grep -q "^${key}=" "$mapping_file"; then
        echo "Error: key '$key' not found in mapping file" >&2
        missing=1
    fi
done

if [ "$missing" -eq 1 ]; then
    exit 1
fi

# Build a sed script for substitutions.
sed_script=$(mktemp)
# Set a trap to clean up temporary files on exit.
trap 'rm -f "$sed_script"' EXIT
# For each mapping (key=value), add a substitution command.
# We assume keys consist only of alphanumerics and underscores.
while IFS='=' read -r key value; do
    # Skip empty lines or lines without a key.
    [ -z "$key" ] && continue
    # Write a sed substitution command. Using | as delimiter.
    echo "s|<placeholder>${key}</placeholder>|${value}|g" >> "$sed_script"
done < "$mapping_file"

# Apply the sed script to the input file, writing output to a temporary file.
temp_file=$(mktemp)
# Set a trap to clean up temporary files on exit.
trap 'rm -f "$temp_file"' EXIT
sed -f "$sed_script" "$input_file" > "$temp_file"
rm "$sed_script"

# Overwrite the original input file with the modified file.
mv "$temp_file" "$input_file"
trap - EXIT
