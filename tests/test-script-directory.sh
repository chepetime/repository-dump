#!/bin/bash

# Test script to ensure repository analyzer works for a specific directory

# Example repository and directory to test
repo_url="https://github.com/chepetime/repository-dump"
test_directory="tests"

# Navigate to the root of the repository
cd "$(dirname "$0")/.."

# Run the script for a specific directory
./repository-dump.sh "$repo_url" "main" "$test_directory"

# Check if output files are created
output_files=$(ls "$test_directory-dump"/*.txt "$test_directory-dump"/*.txt.gz 2>/dev/null)
if [ -n "$output_files" ]; then
    echo
    echo "[TEST] Test passed: Output files created for directory."
else
    echo
    echo "[TEST] Test failed: Output files for directory not found."
fi
