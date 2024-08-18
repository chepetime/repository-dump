#!/bin/bash

# Test script to ensure repository analyzer works for a specific file

# Example repository and file to test
repo_url="https://github.com/chepetime/repository-dump"
test_file="README.md"

# Navigate to the root of the repository
cd "$(dirname "$0")/.."

# Run the script for a specific file
./repository-dump.sh "$repo_url" "main" "$test_file"

# Check if output files are created
output_files=$(ls "$repo_url-dump"/*.txt "$repo_url-dump"/*.txt.gz 2>/dev/null)
if [ -n "$output_files" ]; then
    echo
    echo "[TEST] Test passed: Output files created for file."
else
    echo
    echo "[TEST] Test failed: Output files for file not found."
fi
