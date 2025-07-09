const admin = require('firebase-admin');
const config = require('../config');
const UserProfile = require('../models/user_profile');
const user_basic = require('../models/user_basic');
const { sendTransactionEmail, sendNotificationEmail } = require('./emailUtils');
const { isNotificationEnabled } = require('../controllers/notificationSettingsController');

let firebaseApp;

// Map notification types to settings keys
const notificationTypeMap = {
  'new_piece': 'user_posted_piece',
  'piece_live': 'user_made_piece_live',
  'piece_for_sale': 'user_listed_piece_for_sale',
  'new_offer': 'user_made_offer',
  'offer_received': 'user_made_offer',
  'offer_accepted': 'user_made_offer',
  'payment_submitted': 'user_made_offer',
  'payment_confirmed': 'user_made_offer',
  'payment_denied': 'user_made_offer',
  'payment_reminder': 'user_made_offer',
  'confirmation_reminder': 'user_made_offer',
  'piece_liked': 'user_liked_piece',
  'new_subscriber': 'user_subscribed',

  'posted_piece': 'user_posted_piece',
  'made_piece_live': 'user_made_piece_live',
  'listed_for_sale': 'user_listed_piece_for_sale',
  'made_offer': 'user_made_offer',
  'liked_piece': 'user_liked_piece',
  'subscribed': 'user_subscribed',
  'sold_piece': 'user_made_offer',
  'purchased_piece': 'user_made_offer',

  // Flag-related notifications - these should use general notification settings
  'piece_flagged_inappropriate': 'general_notifications',
  'piece_flagged_piracy': 'general_notifications',
  'dispute_accepted': 'general_notifications',
  'dispute_rejected': 'general_notifications',
  'dispute_resolution_reminder': 'general_notifications',
  'piece_deleted_flag': 'general_notifications'
};

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
          'apns-priority': options.priority === 'high' ? '10' : '5',
        },
        payload: {
          aps: {
            contentAvailable: true
          }
        }
      }
    };

    const response = await admin.messaging().send(message);

    console.log('Push notification sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending push notification:', error);

    // Handle invalid/expired tokens
    if (error.errorInfo && error.errorInfo.code === 'messaging/registration-token-not-registered') {
      console.log(`Invalid token detected for user ${options.userId}, cleaning up...`);

      if (options.userId) {
        try {
          await UserProfile.findOneAndUpdate(
            { username: options.userId },
            { $unset: { push_token: "" } }
          );
          console.log(`Removed invalid push token for user ${options.userId}`);
        } catch (cleanupError) {
          console.error('Error cleaning up invalid token:', cleanupError);
        }
      }

      return {
        success: false,
        error: 'Invalid or expired push token',
        tokenInvalid: true
      };
    }

    return { success: false, error: error.message };
  }
};

/**
 * Send a test push notification to a specific device token
 * @param {string} token - FCM device token to send the notification to
 * @param {Object} testParams - Optional test parameters
 * @param {string} testParams.title - Custom test title (default: 'Test Notification')
 * @param {string} testParams.body - Custom test message (default: 'This is a test notification')
 * @param {Object} testParams.data - Custom test data (will be merged with default test data)
 * @returns {Promise<Object>} - Result of the push notification attempt
 */
const testPushNotification = async (token, testParams = {}) => {
  if (!token || typeof token !== 'string') {
    console.error('Invalid token provided for test push notification');
    return { success: false, message: 'Valid token is required' };
  }

  try {
    const defaultData = {
      id: 'test-' + Date.now(),
      pieceId: 'test-piece-123',
      pieceTitle: 'Test Artwork',
      amount: '100',
      buyerUsername: 'testbuyer',
      sellerUsername: 'testseller',
      date: new Date().toISOString(),
      status: 'test',
      testing: true
    };

    const testData = {
      ...defaultData,
      ...(testParams.data || {})
    };

    return await sendPushNotification({
      token: token,
      title: testParams.title || 'Test Notification',
      body: testParams.body || 'This is a test notification from Frames App',
      data: testData,
      priority: testParams.priority || 'high'
    });
  } catch (error) {
    console.error('Error sending test push notification:', error);
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
 * @param {boolean} options.sendEmail - send Email if push failes
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

    const settingKey = notificationTypeMap[options.notificationType] || options.notificationType;

    const isEnabled = await isNotificationEnabled(options.userId, settingKey);

    if (!isEnabled) {
      console.log(`Notification ${options.notificationType} disabled for user ${options.userId}`);
      return { success: false, message: 'Notification type disabled for user' };
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

    if (!pushResult.success && userBasic && userBasic.email && options.sendEmail) {
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

    case 'new_piece':
      return {
        title: 'New Artwork Posted',
        body: `${data.ownerUsername || 'An artist'} just posted a new piece titled "${data.pieceTitle || 'Untitled'}"`
      };

    case 'piece_live':
      return {
        title: 'Piece Now Live',
        body: `${data.ownerUsername || 'An artist'}'s piece "${data.pieceTitle || 'Untitled'}" is now live`
      };

    case 'piece_for_sale':
      return {
        title: 'Artwork For Sale',
        body: `${data.ownerUsername || 'An artist'} just listed "${data.pieceTitle || 'Untitled'}" for sale at $${data.price || '0'}`
      };

    case 'piece_liked':
      return {
        title: 'Your Artwork Was Liked',
        body: `${data.username || 'Someone'} liked your piece "${data.pieceTitle || 'Untitled'}"`
      };

    case 'new_subscriber':
      return {
        title: 'New Subscriber',
        body: `${data.subscriberUsername || 'Someone'} just subscribed to your profile`
      };

    // Additional cases for feed entry notifications
    case 'posted_piece':
      return {
        title: 'New Artwork Posted',
        body: `${data.fromUsername || 'An artist'} just posted a new piece titled "${data.pieceTitle || 'Untitled'}"`
      };

    case 'made_piece_live':
      return {
        title: 'Piece Now Live',
        body: `${data.fromUsername || 'An artist'}'s piece "${data.pieceTitle || 'Untitled'}" is now live`
      };

    case 'listed_for_sale':
      return {
        title: 'Artwork For Sale',
        body: `${data.fromUsername || 'An artist'} just listed "${data.pieceTitle || 'Untitled'}" for sale at $${data.price || '0'}`
      };

    case 'made_offer':
      return {
        title: 'New Offer Made',
        body: `${data.fromUsername || 'Someone'} made an offer on "${data.pieceTitle || 'Untitled'}"`
      };

    case 'liked_piece':
      return {
        title: 'Artwork Liked',
        body: `${data.fromUsername || 'Someone'} liked the piece "${data.pieceTitle || 'Untitled'}"`
      };

    case 'subscribed':
      return {
        title: 'New Subscription',
        body: `${data.fromUsername || 'Someone'} subscribed to ${data.toUsername || 'an artist'}`
      };

    case 'sold_piece':
      return {
        title: 'Piece Sold',
        body: `${data.fromUsername || 'An artist'} sold their piece "${data.pieceTitle || 'Untitled'}"`
      };

    case 'purchased_piece':
      return {
        title: 'Piece Purchased',
        body: `${data.fromUsername || 'Someone'} purchased the piece "${data.pieceTitle || 'Untitled'}"`
      };

    case 'dispute_accepted':
      return {
        title: 'Dispute Accepted',
        body: `Your dispute for "${data.pieceTitle || 'Untitled'}" has been accepted by administration. Your piece remains active.`
      };

    case 'dispute_rejected':
      return {
        title: 'Dispute Rejected',
        body: `Your dispute for "${data.pieceTitle || 'Untitled'}" has been rejected. The piece has been removed due to ${data.flagType === 'IN' ? 'inappropriate content' : 'copyright violation'}.`
      };

    case 'piece_flagged_inappropriate':
      return {
        title: 'Piece Flagged - Action Required',
        body: `Your piece "${data.pieceTitle || 'Untitled'}" has been flagged for inappropriate content. You have 48 hours to respond or it will be automatically removed.`
      };

    case 'piece_flagged_piracy':
      return {
        title: 'Piece Flagged - Action Required',
        body: `Your piece "${data.pieceTitle || 'Untitled'}" has been flagged for copyright violation. Please respond with evidence of ownership.`
      };

    case 'dispute_resolution_reminder':
      return {
        title: 'Dispute Resolution - Action Required',
        body: `The dispute for your piece "${data.pieceTitle || 'Untitled'}" has been ${data.resolutionStatus}. Please review and acknowledge the decision.`
      };

    default:
      return {
        title: 'Frames App Notification',
        body: 'You have a new notification from Frames App'
      };
  }
};

/**
 * Sends both push notification AND email simultaneously, regardless of push notification success
 * 
 * @param {Object} options - Notification options
 * @param {string} options.userId - Username of recipient
 * @param {string} options.notificationType - Type of notification
 * @param {Object} options.data - Data relevant to the notification
 * @param {string} options.priority - Priority of the notification (high, normal)
 * @returns {Promise<Object>} - Results of both notification attempts
 */
const sendBothNotifications = async (options) => {
  try {
    const userProfile = await UserProfile.findOne({ username: options.userId });
    const userBasic = await user_basic.findOne({ username: options.userId });

    if (!userProfile && !userBasic) {
      console.error(`User ${options.userId} not found for notification`);
      return { success: false, message: 'User not found' };
    }

    const settingKey = notificationTypeMap[options.notificationType] || options.notificationType;

    const isEnabled = await isNotificationEnabled(options.userId, settingKey);

    if (!isEnabled) {
      console.log(`Notification ${options.notificationType} disabled for user ${options.userId}`);
      return { success: false, message: 'Notification type disabled for user' };
    }

    const content = prepareNotificationContent(options.notificationType, options.data);

    const results = {
      push: { attempted: false, success: false },
      email: { attempted: false, success: false }
    };

    if (userProfile && userProfile.push_token) {
      results.push.attempted = true;
      const pushResult = await sendPushNotification({
        userId: options.userId,
        token: userProfile.push_token,
        title: content.title,
        body: content.body,
        data: options.data,
        priority: options.priority || 'normal'
      });

      results.push.success = pushResult.success;
      results.push.result = pushResult;
    }

    if (userBasic && userBasic.email) {
      results.email.attempted = true;
      const emailResult = await sendTransactionEmail({
        email: userBasic.email,
        subject: content.title,
        message: content.body,
        transaction: options.data
      });

      results.email.success = emailResult.success;
      results.email.result = emailResult;
    }

    const overallSuccess = results.push.success || results.email.success;

    return {
      success: overallSuccess,
      results
    };
  } catch (error) {
    console.error('Error in sendBothNotifications:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send notification specifically for feed entries - uses regular notification email instead of transaction email
 * 
 * @param {Object} options - Notification options
 * @param {string} options.userId - Username of recipient
 * @param {string} options.notificationType - Type of notification
 * @param {Object} options.data - Data relevant to the notification
 * @param {string} options.priority - Priority of the notification (high, normal)
 * @returns {Promise<Object>} - Results of notification attempt
 */
const sendFeedNotification = async (options) => {
  try {
    const userProfile = await UserProfile.findOne({ username: options.userId });
    const userBasic = await user_basic.findOne({ username: options.userId });

    if (!userProfile && !userBasic) {
      console.error(`User ${options.userId} not found for notification`);
      return { success: false, message: 'User not found' };
    }

    const settingKey = notificationTypeMap[options.notificationType] || options.notificationType;

    const isEnabled = await isNotificationEnabled(options.userId, settingKey);

    if (!isEnabled) {
      console.log(`Notification ${options.notificationType} disabled for user ${options.userId}`);
      return { success: false, message: 'Notification type disabled for user' };
    }

    const content = prepareNotificationContent(options.notificationType, options.data);

    let pushResult = { success: false };

    // Try push notification first
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

    // If push notification fails, send regular notification email (not transaction email)
    if (!pushResult.success && userBasic && userBasic.email) {
      const emailResult = await sendNotificationEmail({
        email: userBasic.email,
        subject: content.title,
        message: content.body,
        data: options.data
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
    console.error('Error in sendFeedNotification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send notification for flag-related events - always uses regular notification email
 * 
 * @param {Object} options - Notification options
 * @param {string} options.userId - Username of recipient
 * @param {string} options.notificationType - Type of notification
 * @param {Object} options.data - Data relevant to the notification
 * @param {string} options.priority - Priority of the notification (high, normal)
 * @returns {Promise<Object>} - Results of notification attempt
 */
const sendFlagNotification = async (options) => {
  try {
    const userProfile = await UserProfile.findOne({ username: options.userId });
    const userBasic = await user_basic.findOne({ username: options.userId });

    if (!userProfile && !userBasic) {
      console.error(`User ${options.userId} not found for notification`);
      return { success: false, message: 'User not found' };
    }


    const content = prepareNotificationContent(options.notificationType, options.data);

    let pushResult = { success: false };

    // Try push notification first
    if (userProfile && userProfile.push_token) {
      pushResult = await sendPushNotification({
        userId: options.userId,
        token: userProfile.push_token,
        title: content.title,
        body: content.body,
        data: options.data,
        priority: options.priority || 'high' 
      });
    }

    if (userBasic && userBasic.email) {
      const emailResult = await sendNotificationEmail({
        email: userBasic.email,
        subject: content.title,
        message: content.body,
        data: options.data
      });

      return {
        success: true,
        method: pushResult.success ? 'both' : 'email',
        results: {
          push: pushResult,
          email: emailResult
        }
      };
    }

    return {
      success: pushResult.success,
      method: 'push',
      result: pushResult
    };
  } catch (error) {
    console.error('Error in sendFlagNotification:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  initializeFirebaseApp,
  sendPushNotification,
  sendNotification,
  sendBothNotifications,
  sendFeedNotification,
  sendFlagNotification,
  stringifyData,
  testPushNotification
};
