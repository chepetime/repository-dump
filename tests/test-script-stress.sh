#!/bin/bash

# Test script to ensure repository analyzer works as expected

# Example repository to test
repo_url="https://github.com/facebook/react"

# Navigate to the root of the repository
cd "$(dirname "$0")/.."

# Run the script
./repository-dump.sh "$repo_url"

# Check if output files are created
output_files=$(ls output/*.txt output/*.txt.gz 2>/dev/null)
if [ -n "$output_files" ]; then
    echo
    echo "[TEST] Test passed: Output files created."
else
    echo
    echo "[TEST] Test failed: Output files not found."
fi
