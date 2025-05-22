const NotificationSettings = require('../models/notification_settings');
const user_profile = require('../models/user_profile');

exports.getNotificationSettings = async (req, res) => {
  try {
    const username = req.user.username;

    const settings = await NotificationSettings.getSettingsWithDefaults(username);

    res.status(200).json({
      success: true,
      message: 'Notification settings retrieved successfully',
      data: { settings }
    });
  } catch (error) {
    console.error('Error getting notification settings:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve notification settings',
      error: error.message
    });
  }
};

exports.updateNotificationSettings = async (req, res) => {
  try {
    const username = req.user.username;
    const { settings } = req.body;

    if (!settings) {
      return res.status(400).json({
        success: false,
        message: 'Settings object is required'
      });
    }

    const validSettings = [
      'user_posted_piece',
      'user_made_piece_live',
      'user_listed_piece_for_sale',
      'user_made_offer',
      'user_liked_piece',
      'user_subscribed'
    ];

    const invalidSettings = Object.keys(settings).filter(key => !validSettings.includes(key));

    if (invalidSettings.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid setting(s): ${invalidSettings.join(', ')}`,
        validSettings
      });
    }

    let userSettings = await NotificationSettings.findOne({ username });

    if (!userSettings) {
      userSettings = new NotificationSettings({
        username,
        settings: {}
      });
    }

    // Update only the provided settings
    for (const [key, value] of Object.entries(settings)) {
      userSettings.settings[key] = Boolean(value);
    }

    await userSettings.save();

    res.status(200).json({
      success: true,
      message: 'Notification settings updated successfully',
      data: { settings: userSettings }
    });
  } catch (error) {
    console.error('Error updating notification settings:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update notification settings',
      error: error.message
    });
  }
};

// Toggle all notification settings
exports.toggleAllNotifications = async (req, res) => {
  try {
    const username = req.user.username;
    const { enabled } = req.body;

    if (typeof enabled !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'Enabled status must be a boolean'
      });
    }

    // Get existing settings or create new ones
    let userSettings = await NotificationSettings.findOne({ username });

    if (!userSettings) {
      userSettings = new NotificationSettings({
        username,
        settings: {}
      });
    }

    // Set all settings to the same value
    userSettings.settings.user_posted_piece = enabled;
    userSettings.settings.user_made_piece_live = enabled;
    userSettings.settings.user_listed_piece_for_sale = enabled;
    userSettings.settings.user_made_offer = enabled;
    userSettings.settings.user_liked_piece = enabled;
    userSettings.settings.user_subscribed = enabled;

    await userSettings.save();

    res.status(200).json({
      success: true,
      message: `All notifications ${enabled ? 'enabled' : 'disabled'} successfully`,
      data: { settings: userSettings }
    });
  } catch (error) {
    console.error('Error toggling all notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle all notifications',
      error: error.message
    });
  }
};

exports.isNotificationEnabled = async (username, notificationType) => {
  try {
    if (!username || !notificationType) {
      return true; // Default to enabled if not specified
    }

    const settings = await NotificationSettings.findOne({ username });

    // If no settings found, use defaults (all enabled)
    if (!settings || !settings.settings) {
      return true;
    }

    //if the notificaiton type does not exist in the settings, return true
    if (!(notificationType in settings.settings)) {
      return true;
    }
    return settings.settings[notificationType] !== false;
  } catch (error) {
    console.error('Error checking notification status:', error);
    return true;
  }
};
