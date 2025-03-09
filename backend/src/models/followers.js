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
  
  connectToDb();

// Define user schema
const followersSchema = new mongoose.Schema({
  username: { type: String, required: true },
  chunkIndex: { type: Number, required: true },
  followers: { type: [String], required: true },
});

// Create User model
const followers = mongoose.model('followers', followersSchema, 'followers');

module.exports = followers; // Export the User model for use in other parts of your application