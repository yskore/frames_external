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

// Define Piece schema
const PieceSchema = new mongoose.Schema({
  Piece_id: { type: String, required: true },
  Piece_Object: { type: String },
  Piece_owner: { type: String, required: true },
  Piece_title: { type: String, required: true },
  Frame_name: { type: String, required: true },
  live_status: { type: Boolean, default: false },
  Piece_likes: { type: Number, default: 0 },
  Piece_impressions: { type: Number, default: 0 },
  Piece_location: {
    type: {
      type: String,
      enum: ['Point'],
      required: false
    },
    coordinates: {
      type: [Number],
      required: false
    }
  },
  Piece_description: { type: String, required: false },
  Piece_creation_date: { type: Date, default: Date.now },
  Piece_display: { type: String, required: false },
  Piece_for_sale: { type: Boolean, default: false },
  Piece_price: { type: Number, default: 0.0 },
  currency: { type: String, default: 'USD' },
  payment_details: { type: String },
  ownership: { 
    type: String, 
    enum: ['00', '01', '10', '11'], 
    default: '00',
    required: true
  },
  temporary_status: {
    type: String,
    enum: ['normal', 'platform_hold', 'transfer_pending'],
    default: 'normal'
  },
  pending_owner: {
    type: String,
    ref: 'user_basic'
  },
  // NEW HIDDEN FEATURE FIELDS
  isHidden: { 
    type: Boolean, 
    default: false 
  },
  showRadius: { 
    type: Number, 
    default: 0,
    min: 0,
    max: 500
  },
  flag_status: {
    type: String,
    enum: ['normal', 'pending_action', 'disputed', 'resolved', 'deleted'],
    default: 'normal'
  },
  flag_type: {
    type: String,
    enum: ['IN', 'PI'], // IN: inappropriate, PI: piracy
    required: false
  },
  flag_expiration: {
    type: Date,
    required: false
  },
  dispute_id: {
    type: String,
    ref: 'Dispute',
    required: false
  },
  deleted_at: {
    type: Date,
    required: false
  },
  dispute_resolution: {
    status: {
      type: String,
      enum: ['accepted', 'rejected'],
      required: false
    },
    resolved_at: {
      type: Date,
      required: false
    },
    acknowledged_by_owner: {
      type: Boolean,
      default: false
    }
  }
});

const Piece = mongoose.model('Piece', PieceSchema, 'pieces');

module.exports = Piece;