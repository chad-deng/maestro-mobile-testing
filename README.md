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

1. Install Maestro CLI
2. Install Node.js dependencies:
   ```bash
   npm install
   ```
3. Run tests:
   ```bash
   maestro test scenarios/
   ```

## Requirements

- Maestro CLI
- Node.js
- Mobile device or emulator with the target app installed

## Scripts

The `script/` directory contains helper JavaScript files for:
- Product management operations
- Deactivation procedures
- Register management
