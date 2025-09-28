#!/bin/bash

# Maestro Project Setup Script
# This script helps set up the environment for running Maestro tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup script for Maestro mobile testing project.

OPTIONS:
    --install-maestro    Install Maestro CLI
    --install-deps       Install Node.js dependencies
    --check-env          Check environment and dependencies
    --create-reports     Create reports directory structure
    -h, --help           Show this help message

EXAMPLES:
    # Full setup (recommended for first time)
    $0 --install-maestro --install-deps --create-reports

    # Check current environment
    $0 --check-env

EOF
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Maestro CLI
install_maestro() {
    print_info "Installing Maestro CLI..."
    
    if command_exists maestro; then
        print_warning "Maestro CLI is already installed"
        maestro --version
        return 0
    fi
    
    # Install Maestro CLI
    if command_exists curl; then
        curl -Ls "https://get.maestro.mobile.dev" | bash
        print_success "Maestro CLI installed successfully"
    else
        print_error "curl is required to install Maestro CLI"
        return 1
    fi
}

# Function to install Node.js dependencies
install_node_deps() {
    print_info "Installing Node.js dependencies..."
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in current directory"
        return 1
    fi
    
    if command_exists npm; then
        npm install
        print_success "Node.js dependencies installed successfully"
    elif command_exists yarn; then
        yarn install
        print_success "Node.js dependencies installed successfully (using Yarn)"
    else
        print_error "npm or yarn is required to install Node.js dependencies"
        return 1
    fi
}

# Function to check environment
check_environment() {
    print_info "Checking environment and dependencies..."
    
    local all_good=true
    
    # Check Maestro CLI
    if command_exists maestro; then
        print_success "✓ Maestro CLI is installed"
        maestro --version
    else
        print_error "✗ Maestro CLI is not installed"
        all_good=false
    fi
    
    # Check Node.js
    if command_exists node; then
        print_success "✓ Node.js is installed ($(node --version))"
    else
        print_warning "⚠ Node.js is not installed (required for helper scripts)"
        all_good=false
    fi
    
    # Check npm/yarn
    if command_exists npm; then
        print_success "✓ npm is available ($(npm --version))"
    elif command_exists yarn; then
        print_success "✓ Yarn is available ($(yarn --version))"
    else
        print_warning "⚠ npm or yarn is not available"
    fi
    
    # Check project structure
    if [ -f "config.yaml" ]; then
        print_success "✓ config.yaml found"
    else
        print_error "✗ config.yaml not found"
        all_good=false
    fi
    
    if [ -d "scenarios" ]; then
        local scenario_count=$(find scenarios -name "*.yaml" -type f | wc -l)
        print_success "✓ scenarios directory found ($scenario_count scenarios)"
    else
        print_error "✗ scenarios directory not found"
        all_good=false
    fi
    
    if [ -d "script" ]; then
        print_success "✓ script directory found"
    else
        print_warning "⚠ script directory not found"
    fi
    
    # Check if Node.js dependencies are installed
    if [ -f "package.json" ] && [ -d "node_modules" ]; then
        print_success "✓ Node.js dependencies are installed"
    elif [ -f "package.json" ]; then
        print_warning "⚠ Node.js dependencies not installed (run: npm install)"
    fi
    
    # Check environment files
    if [ -d "environments" ]; then
        print_success "✓ Environment configuration files found"
        ls environments/*.env 2>/dev/null | while read -r env_file; do
            echo "    - $(basename "$env_file")"
        done
    else
        print_warning "⚠ Environment configuration directory not found"
    fi
    
    if [ "$all_good" = true ]; then
        print_success "Environment check completed - all essential components are ready!"
    else
        print_warning "Environment check completed - some issues found"
        print_info "Run setup with appropriate flags to fix issues"
    fi
}

# Function to create reports directory structure
create_reports_structure() {
    print_info "Creating reports directory structure..."
    
    mkdir -p test-reports/{fat,staging,production}
    mkdir -p test-reports/archive
    
    # Create .gitkeep files to preserve directory structure
    touch test-reports/fat/.gitkeep
    touch test-reports/staging/.gitkeep
    touch test-reports/production/.gitkeep
    touch test-reports/archive/.gitkeep
    
    print_success "Reports directory structure created"
}

# Parse command line arguments
INSTALL_MAESTRO=false
INSTALL_DEPS=false
CHECK_ENV=false
CREATE_REPORTS=false

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-maestro)
            INSTALL_MAESTRO=true
            shift
            ;;
        --install-deps)
            INSTALL_DEPS=true
            shift
            ;;
        --check-env)
            CHECK_ENV=true
            shift
            ;;
        --create-reports)
            CREATE_REPORTS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute requested actions
if [ "$INSTALL_MAESTRO" = true ]; then
    install_maestro
fi

if [ "$INSTALL_DEPS" = true ]; then
    install_node_deps
fi

if [ "$CREATE_REPORTS" = true ]; then
    create_reports_structure
fi

if [ "$CHECK_ENV" = true ]; then
    check_environment
fi

print_success "Setup completed!"
print_info "You can now run tests using: ./run-maestro.sh"
print_info "For help: ./run-maestro.sh --help"
