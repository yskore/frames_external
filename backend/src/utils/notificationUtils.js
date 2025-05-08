const admin = require('firebase-admin');
const config = require('../config');
const UserProfile = require('../models/user_profile');
const user_basic = require('../models/user_basic');
const { sendTransactionEmail } = require('./emailUtils');

let firebaseApp;

// Initialize Firebase Admin SDK if not already initialized
const initializeFirebaseApp = () => {
  if (!firebaseApp && config.notifications.enabled && config.notifications.provider === 'firebase') {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(config.notifications.firebase.credentials)
    });
    console.log('Firebase Admin SDK initialized successfully');
  }
  return firebaseApp;
};

/**
 * Helper function to convert all values in a data object to strings
 * for Firebase Cloud Messaging requirements
 */
const stringifyData = (data) => {
  const stringifiedData = {};
  
  if (data && typeof data === 'object') {
    Object.keys(data).forEach(key => {
      if (data[key] !== undefined && data[key] !== null) {
        stringifiedData[key] = String(
          typeof data[key] === 'object' ? JSON.stringify(data[key]) : data[key]
        );
      }
    });
  }
  
  return stringifiedData;
};

/**
 * Send push notification to a user
 * @param {Object} options - Notification options
 * @param {string} options.userId - Username of recipient
 * @param {string} options.title - Notification title
 * @param {string} options.body - Notification body
 * @param {Object} options.data - Additional data for notification (optional)
 * @param {string} options.priority - Notification priority (high, normal) (default: normal)
 * @param {string} options.token - Direct FCM token (optional, overrides userId)
 */
const sendPushNotification = async (options) => {
  try {
    if (!config.notifications.enabled) {
      console.log('Push notifications are disabled in config');
      return { success: false, message: 'Notifications are disabled' };
    }

    const app = initializeFirebaseApp();
    
    let token = options.token;
    if (!token && options.userId) {
      const userProfile = await UserProfile.findOne({ username: options.userId });
      
      if (!userProfile || !userProfile.push_token) {
        return { success: false, message: 'No push token found for user' };
      }
      
      token = userProfile.push_token;
    }

    if (!token) {
      return { success: false, message: 'No push token provided' };
    }

    const stringifiedData = stringifyData(options.data || {});
    
    console.log('Preparing push notification with data:', JSON.stringify(stringifiedData));

    const message = {
      notification: {
        title: options.title || 'Frames App',
        body: options.body,
      },
      data: stringifiedData,
      token: token,
      android: {
        priority: options.priority === 'high' ? 'high' : 'normal',
      },
      apns: {
        headers: {
          'apns-priority': options.priority === 'high' ? '5' : '1',
        }
      }
    };

    const response = await admin.messaging().send(message);
    
    console.log('Push notification sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending push notification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Comprehensive notification service that attempts push notification first,
 * then falls back to email if push notification is not possible
 * 
 * @param {Object} options - Notification options
 * @param {string} options.userId - Username of recipient
 * @param {string} options.notificationType - Type of notification (offer_received, offer_accepted, etc.)
 * @param {Object} options.data - Data relevant to the notification
 * @param {string} options.priority - Priority of the notification (high, normal)
 */
const sendNotification = async (options) => {
  try {
    const userProfile = await UserProfile.findOne({ username: options.userId });
    const userBasic = await user_basic.findOne({ username: options.userId });
    
    if (!userProfile && !userBasic) {
      console.error(`User ${options.userId} not found for notification`);
      return { success: false, message: 'User not found' };
    }
    
    const content = prepareNotificationContent(options.notificationType, options.data);
    
    let pushResult = { success: false };
    
    if (userProfile && userProfile.push_token) {
      pushResult = await sendPushNotification({
        userId: options.userId,
        token: userProfile.push_token,
        title: content.title,
        body: content.body,
        data: options.data,
        priority: options.priority || 'normal'
      });
    }
    
    if (!pushResult.success && userBasic && userBasic.email) {
      const emailResult = await sendTransactionEmail({
        email: userBasic.email,
        subject: content.title,
        message: content.body,
        transaction: options.data
      });
      
      return {
        success: true,
        method: 'email',
        result: emailResult
      };
    }
    
    return {
      success: pushResult.success,
      method: 'push',
      result: pushResult
    };
  } catch (error) {
    console.error('Error in sendNotification:', error);
    return { success: false, error: error.message };
  }
};

const prepareNotificationContent = (type, data) => {
  switch (type) {
    case 'offer_received':
      return {
        title: 'New Offer Received',
        body: `You received a new offer of $${data.amount} for your piece "${data.pieceTitle || 'Untitled'}"!`
      };
      
    case 'offer_accepted':
      return {
        title: 'Offer Accepted',
        body: `Your offer for "${data.pieceTitle || 'Untitled'}" was accepted! Please submit payment within ${data.timeWindow || '30 minutes'}.`
      };
      
    case 'payment_submitted':
      return {
        title: 'Payment Submitted',
        body: `The buyer has submitted payment proof for "${data.pieceTitle || 'Untitled'}". Please review and confirm.`
      };
      
    case 'payment_confirmed':
      return {
        title: 'Payment Confirmed',
        body: `Your payment for "${data.pieceTitle || 'Untitled'}" has been confirmed! The piece is now yours.`
      };
      
    case 'payment_denied':
      return {
        title: 'Payment Denied',
        body: `Your payment for "${data.pieceTitle || 'Untitled'}" was denied. Reason: ${data.reason || 'Not provided'}`
      };
      
    case 'payment_reminder':
      return {
        title: 'Payment Reminder',
        body: `This is a reminder to submit payment for "${data.pieceTitle || 'Untitled'}". Your offer will expire soon!`
      };
      
    case 'confirmation_reminder':
      return {
        title: 'Urgent: Confirmation Needed',
        body: `Please confirm or deny the payment for "${data.pieceTitle || 'Untitled'}" soon, or the system will automatically transfer ownership.`
      };
      
    default:
      return {
        title: 'Frames App Notification',
        body: 'You have a new notification from Frames App'
      };
  }
};

module.exports = {
  initializeFirebaseApp,
  sendPushNotification,
  sendNotification,
  stringifyData
};
