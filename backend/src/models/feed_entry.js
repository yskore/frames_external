const mongoose = require('mongoose');
const user_profile = require('./user_profile');

const feedEntrySchema = new mongoose.Schema({
  // The username this feed entry is for
  for_username: { 
    type: String, 
    required: true,
    index: true 
  },
  
  // The username who performed the action
  from_username: { 
    type: String, 
    required: true,
    index: true 
  },
  
  // Type of action performed
  action_type: {
    type: String,
    required: true,
    enum: [
      'posted_piece',      // User posted a new piece
      'made_piece_live',   // User made a piece live 
      'listed_for_sale',   // User listed a piece for sale
      'made_offer',        // User made an offer on a piece
      'liked_piece',       // User liked a piece
      'subscribed',        // User subscribed to another user
      'sold_piece',        // User sold a piece
      'purchased_piece'    // User purchased a piece
    ],
    index: true
  },
  
  // Reference ID - piece_id, offer_id, etc.
  reference_id: {
    type: String,
    required: false
  },
  
  // Piece title (if applicable)
  piece_title: {
    type: String,
    required: false
  },
  
  // Additional data related to the action (JSON)
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  
  // Has the user read this feed entry?
  read: {
    type: Boolean,
    default: false
  },
  
  // When was this feed entry created
  created_at: {
    type: Date,
    default: Date.now,
    index: true
  }
});

// Create compound index for efficient feed queries
feedEntrySchema.index({ for_username: 1, created_at: -1 });

// Method to mark entry as read
feedEntrySchema.methods.markAsRead = async function() {
  if (!this.read) {
    this.read = true;
    await this.save();
  }
  return this;
};

// Static method to create feed entries for all subscribers of a user
feedEntrySchema.statics.createForSubscribers = async function(actionUser, actionType, referenceId, pieceTitle, metadata = {}) {
  try {
    // Get the user profile to find subscribers
    const UserProfile = mongoose.model('user_profile');
    const userProfile = await UserProfile.findOne({ username: actionUser });
    
    if (!userProfile || !userProfile.mySubscribers || userProfile.mySubscribers.length === 0) {
      return { success: true, count: 0, message: 'No subscribers to create feed entries for', subscribers: [] };
    }
    
    // Create a feed entry for each subscriber
    const feedEntries = userProfile.mySubscribers.map(subscriber => ({
      for_username: subscriber,
    from_username: actionUser,
      action_type: actionType,
      reference_id: referenceId || null,
      piece_title: pieceTitle || null,
      metadata: metadata || {},
      read: false,
      created_at: new Date()
    }));
    
    // Insert many feed entries at once
    const result = await this.insertMany(feedEntries);
    
    return {
      success: true,
      count: result.length,
      message: `Created ${result.length} feed entries for subscribers`,
      subscribers: userProfile.mySubscribers // Return the list of subscribers for notifications
    };
  } catch (error) {
    console.error('Error creating feed entries for subscribers:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

const FeedEntry = mongoose.model('FeedEntry', feedEntrySchema);
module.exports = FeedEntry;
