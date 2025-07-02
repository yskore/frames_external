const cron = require('node-cron');
const flagController = require('../controllers/flagController');

// Run every hour to check for expired flags
const scheduleExpiredFlagCheck = () => {
    cron.schedule('0 * * * *', async () => {
        console.log('Checking for expired flags...');
        try {
            const result = await flagController.handleExpiredFlags();
            if (result.success) {
                console.log(`Expired flag check completed. Deleted ${result.deletedCount} pieces.`);
            } else {
                console.error('Expired flag check failed:', result.error);
            }
        } catch (error) {
            console.error('Error in scheduled expired flag check:', error);
        }
    });
};

module.exports = {
    scheduleExpiredFlagCheck
};