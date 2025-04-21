const cron = require('node-cron');
const offerController = require('../controllers/offerController');

// Initialize cron jobs
const initCronJobs = () => {
  console.log('Initializing cron jobs...');
  
  // Check expired confirmations every 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    console.log('Running expired confirmations check...');
    try {
      const result = await offerController.handleExpiredConfirmations();
      console.log('Expired confirmations check result:', result);
    } catch (error) {
      console.error('Error in expired confirmations check:', error);
    }
  });
  
  // Send payment reminders every 3 minutes
  cron.schedule('*/3 * * * *', async () => {
    console.log('Sending payment reminders...');
    try {
      const result = await offerController.sendPaymentReminders();
      console.log('Payment reminders result:', result);
    } catch (error) {
      console.error('Error sending payment reminders:', error);
    }
  });
  
  // Send confirmation reminders every 3 minutes
  cron.schedule('*/3 * * * *', async () => {
    console.log('Sending confirmation reminders...');
    try {
      const result = await offerController.sendConfirmationReminders();
      console.log('Confirmation reminders result:', result);
    } catch (error) {
      console.error('Error sending confirmation reminders:', error);
    }
  });
  
  console.log('Cron jobs initialized successfully');
};

module.exports = { initCronJobs };
