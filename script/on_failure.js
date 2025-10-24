/**
 * Failure Callback Handler for Maestro Tests
 * 
 * This script is called when a test scenario fails.
 * It can be used to:
 * - Log failure details
 * - Send notifications
 * - Perform cleanup
 * - Take screenshots
 * - Generate reports
 */

// Get failure details from environment variables
const failureDetails = {
  scenario: $ENV.FAILED_SCENARIO || 'Unknown',
  error: $ENV.FAILURE_ERROR || 'Unknown error',
  timestamp: new Date().toISOString(),
  device: $ENV.MAESTRO_DEVICE_ID || 'Unknown device',
  environment: $ENV.ENV || 'Unknown environment'
};

console.log('=== TEST FAILURE CALLBACK ===');
console.log(`Scenario: ${failureDetails.scenario}`);
console.log(`Error: ${failureDetails.error}`);
console.log(`Time: ${failureDetails.timestamp}`);
console.log(`Device: ${failureDetails.device}`);
console.log(`Environment: ${failureDetails.environment}`);
console.log('=============================');

// Example: Log to file
try {
  const fs = require('fs');
  const logFile = `reports/failures_${new Date().toISOString().split('T')[0]}.log`;
  const logEntry = `[${failureDetails.timestamp}] ${failureDetails.scenario}: ${failureDetails.error}\n`;
  
  if (!fs.existsSync('reports')) {
    fs.mkdirSync('reports', { recursive: true });
  }
  
  fs.appendFileSync(logFile, logEntry);
  console.log(`Logged to: ${logFile}`);
} catch (e) {
  console.log('Could not write to log file:', e.message);
}

// Return failure details for further processing
output.result = {
  status: 'failure_handled',
  details: failureDetails
};

