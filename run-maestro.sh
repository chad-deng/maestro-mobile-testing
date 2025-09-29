#!/bin/bash

# Maestro Test Runner Script
# This script helps run Maestro tests in different environments with configurable parameters

set -e  # Exit on any error

# Default values
DEFAULT_ENV="fat"
DEFAULT_APP_ID="com.storehub.pos.test"
DEFAULT_BUSINESS_NAME="mcm"
DEFAULT_EMAIL="chad.deng@storehub.com"
DEFAULT_PASSWORD="1Qaz2wsx"
DEFAULT_REGISTER_ID="19"
DEFAULT_SCENARIO_DIR="scenarios"
DEFAULT_CONFIG_FILE="config.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to load environment file
load_env_file() {
    local env=$1
    local env_file="environments/${env}.env"

    if [ -f "$env_file" ]; then
        print_info "Loading environment configuration from $env_file"
        # Source the environment file
        set -a  # Automatically export all variables
        source "$env_file"
        set +a  # Turn off automatic export
        return 0
    else
        print_warning "Environment file not found: $env_file"
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [SCENARIO_FILE_OR_DIRECTORY]

Run Maestro mobile tests with environment-specific configurations.

OPTIONS:
    -e, --env ENV               Environment (fat|staging|production) [default: $DEFAULT_ENV]
    -a, --app-id APP_ID         App ID to test [default: $DEFAULT_APP_ID]
    -b, --business BUSINESS     Business name [default: $DEFAULT_BUSINESS_NAME]
    -u, --email EMAIL           Login email [default: $DEFAULT_EMAIL]
    -p, --password PASSWORD     Login password [default: $DEFAULT_PASSWORD]
    -r, --register-id ID        Register ID [default: $DEFAULT_REGISTER_ID]
    -c, --config CONFIG_FILE    Config file path [default: $DEFAULT_CONFIG_FILE]
    -d, --device DEVICE_ID      Specific device ID to run tests on
    -f, --format FORMAT         Output format (junit|json) [optional]
    -o, --output OUTPUT_DIR     Output directory for reports [optional]
    --env-file FILE             Load environment variables from specific file
    --dry-run                   Show what would be executed without running
    --list-scenarios            List all available test scenarios
    --list-envs                 List all available environment configurations
    --validate                  Validate configuration and environment
    -h, --help                  Show this help message

EXAMPLES:
    # Run all scenarios in FAT environment (default)
    $0

    # Run specific scenario in staging environment
    $0 -e staging scenarios/0001-Activation.yaml

    # Run with custom business credentials
    $0 -b mystore -u user@example.com -p mypassword

    # Run on specific device with output formatting
    $0 -d emulator-5554 -f junit -o ./test-reports

    # Load custom environment file
    $0 --env-file my-custom.env

    # Validate configuration for production environment
    $0 -e production --validate

SUPPORTED ENVIRONMENTS:
    fat        - Factory Acceptance Testing (test17.shub.us)
    staging    - Staging environment (staging.mymyhub.com)
    production - Production environment (storehubhq.com)

ENVIRONMENT FILES:
    Environment-specific configurations can be stored in environments/ directory.
    Files should be named: {environment}.env (e.g., fat.env, staging.env)

EOF
}

# Function to list available scenarios
list_scenarios() {
    print_info "Available test scenarios:"
    if [ -d "$DEFAULT_SCENARIO_DIR" ]; then
        find "$DEFAULT_SCENARIO_DIR" -name "*.yaml" -type f | sort | while read -r scenario; do
            echo "  - $(basename "$scenario")"
        done
    else
        print_error "Scenarios directory not found: $DEFAULT_SCENARIO_DIR"
        exit 1
    fi
}

# Function to list available environment configurations
list_environments() {
    print_info "Available environment configurations:"
    if [ -d "environments" ]; then
        find environments -name "*.env" -type f | sort | while read -r env_file; do
            local env_name=$(basename "$env_file" .env)
            echo "  - $env_name ($(basename "$env_file"))"
        done
    else
        print_warning "No environments directory found"
        print_info "You can create environment files in environments/ directory"
    fi
}

# Function to validate environment and dependencies
validate_environment() {
    local env=$1
    local app_id=$2
    
    print_info "Validating environment and dependencies..."
    
    # Check if Maestro CLI is installed
    if ! command -v maestro &> /dev/null; then
        print_error "Maestro CLI is not installed. Please install it first."
        print_info "Installation: curl -Ls 'https://get.maestro.mobile.dev' | bash"
        exit 1
    fi
    
    # Check if Node.js is available (for scripts)
    if ! command -v node &> /dev/null; then
        print_warning "Node.js is not installed. Some scripts may not work."
    fi
    
    # Validate environment value
    case $env in
        fat|staging|production)
            print_success "Environment '$env' is valid"
            ;;
        *)
            print_error "Invalid environment: $env. Must be one of: fat, staging, production"
            exit 1
            ;;
    esac
    
    # Check if scenarios directory exists
    if [ ! -d "$DEFAULT_SCENARIO_DIR" ]; then
        print_error "Scenarios directory not found: $DEFAULT_SCENARIO_DIR"
        exit 1
    fi
    
    # Check if config file exists
    if [ ! -f "$DEFAULT_CONFIG_FILE" ]; then
        print_error "Config file not found: $DEFAULT_CONFIG_FILE"
        exit 1
    fi
    
    print_success "Environment validation completed"
}

# Function to get app ID based on environment
get_app_id_for_env() {
    local env=$1
    local base_app_id=$2

    case $env in
        fat)
            echo "${base_app_id}"
            ;;
        staging)
            # Only add .staging if it's not already there
            if [[ "$base_app_id" == *.staging ]]; then
                echo "${base_app_id}"
            else
                echo "${base_app_id}.staging"
            fi
            ;;
        production)
            # Remove .test suffix for production, but keep base app ID clean
            if [[ "$base_app_id" == *.test ]]; then
                echo "${base_app_id%.test}"
            else
                echo "${base_app_id}"
            fi
            ;;
        *)
            echo "${base_app_id}"
            ;;
    esac
}

# Function to create temporary config file with environment-specific settings
create_temp_config() {
    local env=$1
    local app_id=$2
    local config_file=$3
    
    local temp_config="/tmp/maestro-config-$$.yaml"
    
    # Copy original config and modify for environment
    cp "$config_file" "$temp_config"
    
    # Update app ID in temp config
    sed -i.bak "s/appId: .*/appId: $app_id/" "$temp_config" 2>/dev/null || \
    sed -i "s/appId: .*/appId: $app_id/" "$temp_config"
    
    # Update environment variable
    sed -i.bak "s/ENV: .*/ENV: '$env'/" "$temp_config" 2>/dev/null || \
    sed -i "s/ENV: .*/ENV: '$env'/" "$temp_config"
    
    echo "$temp_config"
}

# Function to run Maestro tests
run_maestro_tests() {
    local target=$1
    local temp_config=$2
    local device_id=$3
    local output_format=$4
    local output_dir=$5
    local env=$6
    local business_name=$7
    local email=$8
    local password=$9
    local register_id=${10}
    
    print_info "Starting Maestro tests..."
    print_info "Environment: $env"
    print_info "Target: $target"
    print_info "Config: $temp_config"
    
    # Build maestro command
    local maestro_cmd="maestro test"
    
    # Set device environment variable if provided (Maestro uses this for device selection)
    if [ -n "$device_id" ]; then
        export MAESTRO_DEVICE_ID="$device_id"
        print_info "Device specified: $device_id"
    fi
    
    # Add output format if provided
    if [ -n "$output_format" ]; then
        maestro_cmd="$maestro_cmd --format $output_format"
    fi
    
    # Add output directory if provided
    if [ -n "$output_dir" ]; then
        mkdir -p "$output_dir"
        maestro_cmd="$maestro_cmd --output $output_dir"
    fi
    
    # Set environment variables for scripts
    export ENV="$env"
    export myAccount="$business_name"
    export myEmail="$email"
    export myPassword="$password"
    export myRegisterId="$register_id"
    
    # Add config file and target
    maestro_cmd="$maestro_cmd --config $temp_config $target"
    
    print_info "Executing: $maestro_cmd"
    
    # Run the command
    if eval "$maestro_cmd"; then
        print_success "Maestro tests completed successfully!"
        return 0
    else
        print_error "Maestro tests failed!"
        return 1
    fi
}

# Parse command line arguments
ENV="$DEFAULT_ENV"
APP_ID="$DEFAULT_APP_ID"
BUSINESS_NAME="$DEFAULT_BUSINESS_NAME"
EMAIL="$DEFAULT_EMAIL"
PASSWORD="$DEFAULT_PASSWORD"
REGISTER_ID="$DEFAULT_REGISTER_ID"
CONFIG_FILE="$DEFAULT_CONFIG_FILE"
DEVICE_ID=""
OUTPUT_FORMAT=""
OUTPUT_DIR=""
ENV_FILE=""
DRY_RUN=false
LIST_SCENARIOS=false
LIST_ENVS=false
VALIDATE_ONLY=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV="$2"
            shift 2
            ;;
        -a|--app-id)
            APP_ID="$2"
            shift 2
            ;;
        -b|--business)
            BUSINESS_NAME="$2"
            shift 2
            ;;
        -u|--email)
            EMAIL="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -r|--register-id)
            REGISTER_ID="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE_ID="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list-scenarios)
            LIST_SCENARIOS=true
            shift
            ;;
        --list-envs)
            LIST_ENVS=true
            shift
            ;;
        --validate)
            VALIDATE_ONLY=true
            shift
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
            TARGET="$1"
            shift
            ;;
    esac
done

# Handle special commands
if [ "$LIST_SCENARIOS" = true ]; then
    list_scenarios
    exit 0
fi

if [ "$LIST_ENVS" = true ]; then
    list_environments
    exit 0
fi

# Load environment file if specified or try to load default for environment
if [ -n "$ENV_FILE" ]; then
    if [ -f "$ENV_FILE" ]; then
        print_info "Loading custom environment file: $ENV_FILE"
        set -a
        source "$ENV_FILE"
        set +a
    else
        print_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
else
    # Try to load default environment file
    load_env_file "$ENV" || true  # Don't fail if env file doesn't exist
fi

# Override with any command line parameters (command line takes precedence)
if [ -n "$BUSINESS_NAME" ] && [ "$BUSINESS_NAME" != "$DEFAULT_BUSINESS_NAME" ]; then
    export myAccount="$BUSINESS_NAME"
fi
if [ -n "$EMAIL" ] && [ "$EMAIL" != "$DEFAULT_EMAIL" ]; then
    export myEmail="$EMAIL"
fi
if [ -n "$PASSWORD" ] && [ "$PASSWORD" != "$DEFAULT_PASSWORD" ]; then
    export myPassword="$PASSWORD"
fi
if [ -n "$REGISTER_ID" ] && [ "$REGISTER_ID" != "$DEFAULT_REGISTER_ID" ]; then
    export myRegisterId="$REGISTER_ID"
fi

# Set default target if not provided
if [ -z "$TARGET" ]; then
    TARGET="$DEFAULT_SCENARIO_DIR"
fi

# Get environment-specific app ID
FINAL_APP_ID=$(get_app_id_for_env "$ENV" "$APP_ID")

# Validate environment
validate_environment "$ENV" "$FINAL_APP_ID"

if [ "$VALIDATE_ONLY" = true ]; then
    print_success "Validation completed successfully!"
    exit 0
fi

# Create temporary config file
TEMP_CONFIG=$(create_temp_config "$ENV" "$FINAL_APP_ID" "$CONFIG_FILE")

# Cleanup function
cleanup() {
    if [ -f "$TEMP_CONFIG" ]; then
        rm -f "$TEMP_CONFIG" "${TEMP_CONFIG}.bak"
    fi
}
trap cleanup EXIT

if [ "$DRY_RUN" = true ]; then
    print_info "DRY RUN - Would execute the following:"
    print_info "Environment: $ENV"
    print_info "App ID: $FINAL_APP_ID"
    print_info "Business: $BUSINESS_NAME"
    print_info "Email: $EMAIL"
    print_info "Register ID: $REGISTER_ID"
    print_info "Target: $TARGET"
    print_info "Config: $TEMP_CONFIG"
    if [ -n "$DEVICE_ID" ]; then
        print_info "Device: $DEVICE_ID"
    fi
    if [ -n "$OUTPUT_FORMAT" ]; then
        print_info "Output Format: $OUTPUT_FORMAT"
    fi
    if [ -n "$OUTPUT_DIR" ]; then
        print_info "Output Directory: $OUTPUT_DIR"
    fi
    exit 0
fi

# Run the tests
run_maestro_tests "$TARGET" "$TEMP_CONFIG" "$DEVICE_ID" "$OUTPUT_FORMAT" "$OUTPUT_DIR" "$ENV" "$BUSINESS_NAME" "$EMAIL" "$PASSWORD" "$REGISTER_ID"
