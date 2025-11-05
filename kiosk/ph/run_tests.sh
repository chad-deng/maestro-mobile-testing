#!/bin/bash

# Script to run kiosk tests in the correct order
# This is a workaround for Maestro's executionOrder not being respected

set -e

echo "Running kiosk tests in order..."

# Array of test files in the correct order
tests=(
    "0001-Activation.yaml"
    "0002-Open_shift.yaml"
    "0003-Settings_check.yaml"
    "0999-Deactivate.yaml"
)

# Run each test
for test in "${tests[@]}"; do
    echo ""
    echo "=========================================="
    echo "Running: $test"
    echo "=========================================="
    maestro -p=Android test "$test"
    if [ $? -ne 0 ]; then
        echo "Test $test failed!"
        # Continue to next test instead of stopping
    fi
done

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="

