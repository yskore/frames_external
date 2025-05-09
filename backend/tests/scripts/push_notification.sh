#!/bin/bash

# NOTE: If you get a "permission denied" error, run this command first:
# chmod +x ./push_notification.sh

# Attempt to make the script executable if it isn't already
if [ -w "$(dirname "$0")" ]; then
  chmod +x "$0" 2>/dev/null || true
fi

# Check if a token was provided
if [ -z "$1" ]; then
  echo "Error: Push token is required."
  echo "Usage: ./push_notification.sh <push_token>"
  exit 1
fi

# Store the token from the first argument
PUSH_TOKEN="$1"

# Execute Node.js script with the token
node -e "
const { initializeFirebaseApp, testPushNotification } = require('../../src/utils/notificationUtils');

// Initialize Firebase if needed
initializeFirebaseApp();

console.log('Sending test notification to token:', '$PUSH_TOKEN');

// Use the testPushNotification function
testPushNotification('$PUSH_TOKEN', {
  title: 'Test Notification from Script',
  body: 'This is a test notification sent from the push_notification.sh script',
  data: {
    testId: 'script-test-' + Date.now(),
    source: 'bash_script'
  }
})
.then((result) => {
  console.log('Test notification result:', JSON.stringify(result));
  if (result.success) {
    console.log('✅ Test notification sent successfully!');
  } else {
    console.error('❌ Failed to send test notification:', result.message || result.error);
    process.exit(1);
  }
})
.catch((error) => {
  console.error('❌ Error during test notification:', error);
  process.exit(1);
});
"

echo "Test notification script executed."
