#!/bin/bash

##############################################################################
# Maestro Test Runner with Failure Callback Handler
# 
# This script runs Maestro tests and handles failures with callbacks
# 
# Usage:
#   ./run-maestro-with-failure-handler.sh [options] [scenario]
#   
# Options:
#   -e, --env ENV              Environment (fat, staging, production)
#   -d, --device DEVICE_ID     Device ID for testing
#   -c, --continue             Continue on failure (default: true)
#   -h, --help                 Show this help message
#
# Examples:
#   ./run-maestro-with-failure-handler.sh kiosk/ph/recycle_order.yaml
#   ./run-maestro-with-failure-handler.sh -e staging scenarios/0001-Activation.yaml
#   ./run-maestro-with-failure-handler.sh -d emulator-5554 -c true kiosk/0001-Activation.yaml
##############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENV="fat"
DEVICE_ID=""
CONTINUE_ON_FAILURE=true
SCENARIO=""
REPORT_DIR="reports"
FAILURE_LOG="${REPORT_DIR}/failures.log"

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

# Show usage
show_usage() {
    cat << EOF
Maestro Test Runner with Failure Callback Handler

Usage: $(basename "$0") [options] [scenario]

Options:
    -e, --env ENV              Environment (fat, staging, production) [default: fat]
    -d, --device DEVICE_ID     Device ID for testing
    -c, --continue             Continue on failure [default: true]
    -h, --help                 Show this help message

Examples:
    $(basename "$0") kiosk/ph/recycle_order.yaml
    $(basename "$0") -e staging scenarios/0001-Activation.yaml
    $(basename "$0") -d emulator-5554 scenarios/0001-Activation.yaml

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE_ID="$2"
            shift 2
            ;;
        -c|--continue)
            CONTINUE_ON_FAILURE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            SCENARIO="$1"
            shift
            ;;
    esac
done

# Validate scenario
if [ -z "$SCENARIO" ]; then
    print_error "No scenario specified"
    show_usage
    exit 1
fi

# Create reports directory
mkdir -p "$REPORT_DIR"

print_info "Starting Maestro test with failure handler"
print_info "Scenario: $SCENARIO"
print_info "Environment: $ENV"
print_info "Continue on failure: $CONTINUE_ON_FAILURE"

if [ -n "$DEVICE_ID" ]; then
    print_info "Device: $DEVICE_ID"
    export MAESTRO_DEVICE_ID="$DEVICE_ID"
fi

# Run the test and capture exit code
TEST_EXIT_CODE=0
TEST_OUTPUT=$(mktemp)

print_info "Running test..."
echo ""

if maestro test "$SCENARIO" 2>&1 | tee "$TEST_OUTPUT"; then
    TEST_EXIT_CODE=0
    print_success "Test passed!"
else
    TEST_EXIT_CODE=$?
    print_error "Test failed with exit code: $TEST_EXIT_CODE"
    
    # Extract failure information
    FAILURE_ERROR=$(tail -20 "$TEST_OUTPUT" | grep -i "error\|failed" | head -1 || echo "Unknown error")
    
    # Call failure handler
    print_warning "Calling failure handler..."
    
    export FAILED_SCENARIO="$SCENARIO"
    export FAILURE_ERROR="$FAILURE_ERROR"
    export ENV="$ENV"
    
    # Log failure
    {
        echo "=========================================="
        echo "Test Failure Report"
        echo "=========================================="
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "Scenario: $SCENARIO"
        echo "Environment: $ENV"
        echo "Device: ${DEVICE_ID:-default}"
        echo "Error: $FAILURE_ERROR"
        echo "Exit Code: $TEST_EXIT_CODE"
        echo "=========================================="
        echo ""
    } >> "$FAILURE_LOG"
    
    print_info "Failure logged to: $FAILURE_LOG"
    
    # Run failure callback script if it exists
    if [ -f "script/on_failure.js" ]; then
        print_info "Running failure callback script..."
        node script/on_failure.js || true
    fi
    
    # Check if we should continue
    if [ "$CONTINUE_ON_FAILURE" != "true" ]; then
        print_error "Stopping due to test failure"
        rm -f "$TEST_OUTPUT"
        exit $TEST_EXIT_CODE
    else
        print_warning "Continuing despite test failure (continueOnFailure=true)"
    fi
fi

# Cleanup
rm -f "$TEST_OUTPUT"

# Print summary
echo ""
print_info "Test execution completed"
print_info "Failure log: $FAILURE_LOG"

exit $TEST_EXIT_CODE

