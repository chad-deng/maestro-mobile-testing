#!/bin/bash

# Example usage scripts for Maestro testing
# This file demonstrates various ways to run the tests

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_example() {
    echo -e "${BLUE}[EXAMPLE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "=== Maestro Testing Examples ==="
echo

# Example 1: Basic test run
print_example "Running basic test in FAT environment"
echo "Command: ./run-maestro.sh"
echo "This runs all scenarios in the default FAT environment"
echo

# Example 2: Staging environment
print_example "Running tests in staging environment"
echo "Command: ./run-maestro.sh -e staging"
echo "This runs all scenarios in the staging environment"
echo

# Example 3: Specific scenario
print_example "Running a specific test scenario"
echo "Command: ./run-maestro.sh scenarios/0006-Login_success.yaml"
echo "This runs only the login success scenario"
echo

# Example 4: Custom credentials
print_example "Running with custom business credentials"
echo "Command: ./run-maestro.sh -b mystore -u user@example.com -p mypassword"
echo "This runs tests with custom business name, email, and password"
echo

# Example 5: Device-specific testing
print_example "Running on a specific device with formatted output"
echo "Command: ./run-maestro.sh -d emulator-5554 -f junit -o ./test-reports"
echo "This runs tests on a specific device and saves JUnit reports"
echo

# Example 6: Production validation (dry run)
print_example "Validating production configuration (dry run)"
echo "Command: ./run-maestro.sh -e production --dry-run --validate"
echo "This validates production setup without actually running tests"
echo

# Example 7: Custom environment file
print_example "Using a custom environment file"
echo "Command: ./run-maestro.sh --env-file environments/my-custom.env"
echo "This loads configuration from a custom environment file"
echo

# Example 8: List available options
print_example "Listing available scenarios and environments"
echo "Command: ./run-maestro.sh --list-scenarios"
echo "Command: ./run-maestro.sh --list-envs"
echo "These commands show available test scenarios and environment configurations"
echo

print_success "Examples completed! Choose any command above to run tests."

# Interactive example selector
echo
read -p "Would you like to run an interactive example? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Select an example to run:"
    echo "1) Basic FAT test"
    echo "2) Staging environment test"
    echo "3) Login scenario only"
    echo "4) Dry run validation"
    echo "5) List scenarios"
    echo "6) Exit"
    
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            print_example "Running: ./run-maestro.sh"
            ../run-maestro.sh
            ;;
        2)
            print_example "Running: ./run-maestro.sh -e staging"
            ../run-maestro.sh -e staging
            ;;
        3)
            print_example "Running: ./run-maestro.sh scenarios/0006-Login_success.yaml"
            ../run-maestro.sh scenarios/0006-Login_success.yaml
            ;;
        4)
            print_example "Running: ./run-maestro.sh --dry-run --validate"
            ../run-maestro.sh --dry-run --validate
            ;;
        5)
            print_example "Running: ./run-maestro.sh --list-scenarios"
            ../run-maestro.sh --list-scenarios
            ;;
        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
fi
