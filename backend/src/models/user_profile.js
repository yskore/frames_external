const mongoose = require('mongoose');

// Connect to MongoDB
const connectToDb = async () => {
    try {
      // Check if a connection already exists
      if (mongoose.connection.readyState === 0) {
        await mongoose.connect('mongodb+srv://frames_editor:korecool@frames1.zwwpxow.mongodb.net/frames_storage?retryWrites=true&w=majority&appName=Frames1');
        console.log('Successfully connected to MongoDB');
      }
    } catch (err) {
      console.log('Failed to connect to MongoDB:', err);
    }
  };
  
// Define user_profile schema
const user_profileSchema = new mongoose.Schema({
    username: { type: String, required: true },
    Profile_photo: { type: String }, // store image as a URL or file path
    User_bio: { type: String },
    Paypal_email: { type: String }, // nullable
    Frame_count: { type: Number },
    Like_count: { type: Number },
    User_followers: { type: [String] }, // nullable
    User_following: { type: [String] }, // nullable
    Live_pieces: { type: Number, default: 0 },
    Is_premium: { type: Boolean, default: false },
  });

// Create User model
const user_profile = mongoose.model('user_profile', user_profileSchema, 'user_profile');
module.exports = user_profile;
