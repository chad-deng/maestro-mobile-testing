# Maestro Mobile Testing Project

This project contains automated mobile testing scenarios using Maestro, a mobile UI testing framework.

## Project Structure

- `scenarios/` - Contains Maestro test scenarios in YAML format
- `script/` - JavaScript helper scripts for test automation
- `subflow/` - Reusable test flows
- `config.yaml` - Maestro configuration file
- `package.json` - Node.js dependencies

## Test Scenarios

The project includes the following test scenarios:

1. **0001-Activation.yaml** - App activation flow
2. **0002-Shift_Management.yaml** - Shift management functionality
3. **0003-Clock_in_out.yaml** - Clock in/out operations
4. **0004-Basic_Transaction_Processing.yaml** - Basic transaction processing
5. **0005-Enable_Table_layout.yaml** - Table layout configuration
6. **0006-Login_success.yaml** - Successful login flow
7. **0007-Online_order.yaml** - Online order processing
8. **0010-Login_failed.yaml** - Failed login scenarios
9. **0020-Search_product.yaml** - Product search functionality
10. **008-Manage_products.yaml** - Product management
11. **0999-Deactivate.yaml** - App deactivation flow

## Configuration

The app is configured to test: `com.storehub.pos.test`

Environment: FAT (Factory Acceptance Testing)

## Getting Started

### Quick Setup

1. **Initial setup (first time only):**
   ```bash
   ./setup.sh --install-maestro --install-deps --create-reports
   ```

2. **Run tests in FAT environment:**
   ```bash
   ./run-maestro.sh
   ```

3. **Run tests in staging environment:**
   ```bash
   ./run-maestro.sh -e staging
   ```

### Manual Setup

1. Install Maestro CLI:
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```

2. Install Node.js dependencies:
   ```bash
   npm install
   ```

3. Run tests using the runner script:
   ```bash
   ./run-maestro.sh --help
   ```

## Requirements

- Maestro CLI
- Node.js
- Mobile device or emulator with the target app installed

## Scripts and Tools

### Test Runner Scripts

- **`run-maestro.sh`** - Main test runner with environment support
- **`setup.sh`** - Environment setup and dependency installation
- **`examples/run-examples.sh`** - Interactive examples and usage demonstrations

### Helper Scripts

The `script/` directory contains JavaScript helper files for:
- Product management operations
- Deactivation procedures
- Register management

### Environment Configuration

The `environments/` directory contains environment-specific configurations:
- `fat.env` - Factory Acceptance Testing environment
- `staging.env` - Staging environment
- `production.env` - Production environment

## Usage Examples

```bash
# Run all tests in FAT environment (default)
./run-maestro.sh

# Run specific scenario in staging
./run-maestro.sh -e staging scenarios/0001-Activation.yaml

# Run with custom credentials
./run-maestro.sh -b mystore -u user@example.com -p mypassword

# Run on specific device with JUnit output
./run-maestro.sh -d emulator-5554 -f junit -o ./test-reports

# Validate configuration without running tests
./run-maestro.sh --validate -e production

# List available scenarios and environments
./run-maestro.sh --list-scenarios
./run-maestro.sh --list-envs
```

For more detailed usage instructions, see [TESTING_GUIDE.md](TESTING_GUIDE.md).
