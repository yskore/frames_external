const mongoose = require('mongoose');

// Define notification settings schema
const notificationSettingsSchema = new mongoose.Schema({
  username: { 
    type: String, 
    required: true,
    unique: true
  },
  settings: {
    user_posted_piece: { 
      type: Boolean, 
      default: true 
    },
    user_made_piece_live: { 
      type: Boolean, 
      default: true 
    },
    user_listed_piece_for_sale: { 
      type: Boolean, 
      default: true 
    },
    user_made_offer: { 
      type: Boolean, 
      default: true 
    },
    user_liked_piece: { 
      type: Boolean, 
      default: true 
    },
    user_subscribed: { 
      type: Boolean, 
      default: true 
    }
  },
  //TODO: move storing device tokens from user_profile to this model
  device_settings: [{
    device_id: String,
    token: String,
    enabled: { type: Boolean, default: true }
  }],
  created_at: { 
    type: Date, 
    default: Date.now 
  },
  updated_at: { 
    type: Date, 
    default: Date.now 
  }
});

// Update the timestamp before saving
notificationSettingsSchema.pre('save', function(next) {
  this.updated_at = Date.now();
  next();
});

// Define static method to get settings with defaults
notificationSettingsSchema.statics.getSettingsWithDefaults = async function(username) {
  let settings = await this.findOne({ username });
  if (!settings) {
    // Create default settings if none exist
    settings = new this({ 
      username,
      settings: {
        user_posted_piece: true,
        user_made_piece_live: true,
        user_listed_piece_for_sale: true,
        user_made_offer: true,
        user_liked_piece: true,
        user_subscribed: true
      }
    });
    await settings.save();
  }
  return settings;
};

const NotificationSettings = mongoose.model('NotificationSettings', notificationSettingsSchema);
module.exports = NotificationSettings;
