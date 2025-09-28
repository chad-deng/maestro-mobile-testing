# Maestro Testing Guide

This guide explains how to run the Maestro mobile testing project across different environments.

## Quick Start

1. **Setup the environment:**
   ```bash
   ./setup.sh --install-maestro --install-deps --create-reports
   ```

2. **Run tests in FAT environment (default):**
   ```bash
   ./run-maestro.sh
   ```

3. **Run tests in staging environment:**
   ```bash
   ./run-maestro.sh -e staging
   ```

## Project Structure

```
maestro-mobile-testing/
├── scenarios/              # Test scenarios
├── script/                 # Helper JavaScript scripts
├── subflow/               # Reusable test flows
├── environments/          # Environment configurations
├── test-reports/          # Test output reports
├── config.yaml           # Main Maestro configuration
├── run-maestro.sh        # Main test runner script
├── setup.sh              # Environment setup script
└── TESTING_GUIDE.md      # This guide
```

## Environment Configuration

### Supported Environments

1. **FAT (Factory Acceptance Testing)**
   - App ID: `com.storehub.pos.test`
   - Backend: `*.backoffice.test17.shub.us`
   - Purpose: Development and feature testing

2. **Staging**
   - App ID: `com.storehub.pos.test.staging`
   - Backend: `*.backoffice.staging.mymyhub.com`
   - Purpose: Pre-production testing

3. **Production**
   - App ID: `com.storehub.pos`
   - Backend: `*.storehubhq.com`
   - Purpose: Live environment testing (use with caution!)

### Environment Files

Environment-specific configurations are stored in `environments/` directory:

- `environments/fat.env` - FAT environment settings
- `environments/staging.env` - Staging environment settings
- `environments/production.env` - Production environment settings

You can create custom environment files and load them using `--env-file` option.

## Usage Examples

### Basic Usage

```bash
# Run all scenarios in default environment (FAT)
./run-maestro.sh

# Run specific scenario
./run-maestro.sh scenarios/0001-Activation.yaml

# Run in staging environment
./run-maestro.sh -e staging

# Run with custom credentials
./run-maestro.sh -b mystore -u user@example.com -p mypassword
```

### Advanced Usage

```bash
# Run on specific device with JUnit output
./run-maestro.sh -d emulator-5554 -f junit -o ./test-reports/fat

# Load custom environment file
./run-maestro.sh --env-file my-custom.env

# Dry run to see what would be executed
./run-maestro.sh --dry-run -e production

# Validate environment without running tests
./run-maestro.sh --validate -e staging
```

### Utility Commands

```bash
# List all available scenarios
./run-maestro.sh --list-scenarios

# List all environment configurations
./run-maestro.sh --list-envs

# Check environment and dependencies
./setup.sh --check-env
```

## Test Scenarios

The project includes the following test scenarios:

1. **0001-Activation.yaml** - App activation and register setup
2. **0002-Shift_Management.yaml** - Shift operations and sales reporting
3. **0003-Clock_in_out.yaml** - Employee clock in/out functionality
4. **0004-Basic_Transaction_Processing.yaml** - Basic POS transactions
5. **0005-Enable_Table_layout.yaml** - Table layout and ordering
6. **0006-Login_success.yaml** - Successful login flow
7. **0007-Online_order.yaml** - Online order management
8. **0010-Login_failed.yaml** - Failed login scenarios
9. **0020-Search_product.yaml** - Product search functionality
10. **008-Manage_products.yaml** - Product management operations
11. **0999-Deactivate.yaml** - App deactivation and cleanup

## Configuration Parameters

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-e, --env` | Environment (fat/staging/production) | fat |
| `-a, --app-id` | App ID to test | com.storehub.pos.test |
| `-b, --business` | Business name | mcm |
| `-u, --email` | Login email | chad.deng@storehub.com |
| `-p, --password` | Login password | 1Qaz2wsx |
| `-r, --register-id` | Register ID | 19 |
| `-d, --device` | Device ID | (auto-detect) |
| `-f, --format` | Output format (junit/json) | (default) |
| `-o, --output` | Output directory | (none) |

### Environment Variables

The following environment variables are used by the test scripts:

- `ENV` - Environment identifier
- `myAccount` - Business name
- `myEmail` - Login email
- `myPassword` - Login password
- `myRegisterId` - Register ID

## Troubleshooting

### Common Issues

1. **Maestro CLI not found**
   ```bash
   ./setup.sh --install-maestro
   ```

2. **Node.js dependencies missing**
   ```bash
   ./setup.sh --install-deps
   ```

3. **App not found on device**
   - Ensure the correct app is installed
   - Check app ID matches the environment
   - Verify device is connected and accessible

4. **Authentication failures**
   - Verify credentials are correct for the environment
   - Check if account exists in the target environment
   - Ensure register ID is valid

### Debug Mode

For debugging issues, you can:

1. Use dry-run mode to see what would be executed:
   ```bash
   ./run-maestro.sh --dry-run
   ```

2. Check environment validation:
   ```bash
   ./run-maestro.sh --validate
   ```

3. Run individual scenarios to isolate issues:
   ```bash
   ./run-maestro.sh scenarios/0006-Login_success.yaml
   ```

## Best Practices

1. **Environment Isolation**: Always use appropriate environments for testing
2. **Credential Management**: Store sensitive credentials in environment files, not in scripts
3. **Test Data**: Use dedicated test accounts and data for each environment
4. **Reporting**: Use structured output formats (JUnit/JSON) for CI/CD integration
5. **Device Management**: Use consistent device configurations across test runs

## CI/CD Integration

For continuous integration, you can use the script in automated pipelines:

```bash
# Example CI/CD command
./run-maestro.sh -e staging -f junit -o ./test-reports/staging --validate
```

The script returns appropriate exit codes:
- `0` - Success
- `1` - Test failures or errors
- `2` - Configuration or setup errors

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Validate your environment setup
3. Review test logs in the debug directory
4. Check Maestro documentation: https://maestro.mobile.dev/
