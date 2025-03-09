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

  // anchor schema
  const AnchorSchema = new mongoose.Schema({
    anchorId: { type: String, required: true },
    pieceId: { type: String, required: true },
    pieceOwner: String,
    frameName: String,
    faceName: String,
    imageUrl: String,
    location: {
      type: { type: String, enum: ['Point'], required: true },
      coordinates: { type: [Number], required: true }
    },
    arPosition: {
      x: Number,
      y: Number,
      z: Number
    },
    arRotation: {
      x: Number,
      y: Number,
      z: Number,
      w: Number
    },
    // Add these new fields:
    localScale: {
      x: Number,
      y: Number,
      z: Number
    },
    heightAboveCamera: Number
  });
  
  AnchorSchema.index({ location: '2dsphere' });

const Anchor = mongoose.model('Anchor', AnchorSchema, 'anchors');

module.exports = Anchor;