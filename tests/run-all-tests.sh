#!/bin/bash

# Description:
# This script runs all the test scripts in the `tests` directory
# and reports whether each test passed or failed.

echo "[START] Running all test scripts..."

# Initialize a counter for passed and failed tests
passed=0
failed=0

# Change to the tests directory
cd tests || { echo "[ERROR] Could not change to tests directory. Exiting."; exit 1; }

# Loop over each test script in the tests directory
for test_script in test-script*.sh; do
    echo
    echo "[RUNNING] $test_script..."

    # Run the test script
    bash "$test_script"

    # Capture the exit status of the test script
    if [ $? -eq 0 ]; then
        echo "[PASSED] $test_script"
        ((passed++))
    else
        echo "[FAILED] $test_script"
        ((failed++))
    fi
done

# Report the results
echo
echo "[RESULTS] $passed tests passed, $failed tests failed."

# Exit with status 0 if all tests passed, otherwise 1
if [ $failed -eq 0 ]; then
    exit 0
else
    exit 1
fi
