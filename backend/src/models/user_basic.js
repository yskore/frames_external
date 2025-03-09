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
const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  password: { type: String, required: true },
  firstName: String,
  lastName: String,
  dateOfBirth: Date,
  country: String,
  email: { type: String, required: true },
  phoneNumber: String,
  userType: String,
});

// Create User model
const user_basic = mongoose.model('user_basic', userSchema, 'user_basic');

module.exports = user_basic; // Export the User model for use in other parts of your application