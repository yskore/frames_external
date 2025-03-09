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
  

  const FrameSchema = new mongoose.Schema({
    Frame_object: { type: String },
    Frame_owner: { type: String, required: true },
    Frame_display: { type: String, required: true },
    Frame_collaborators: { type: [String], default: [] },
    Frame_title: { type: String, required: true },
    Frame_description: { type: String, required: true },
    Frame_creation_date: { type: Date, default: Date.now },
    Frame_for_sale: { type: Boolean, default: false },
    Frame_price: { type: Number, default: 0.0 },
    Face_name: { type: String, required: true }
  });
  
  const Frame = mongoose.model('Frame', FrameSchema, 'frames');
  
  module.exports = Frame;


  