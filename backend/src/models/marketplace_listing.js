// const mongoose = require('mongoose');

// const marketplaceListingSchema = new mongoose.Schema({
//     piece_id: { 
//         type: String, 
//         required: true,
//         ref: 'Piece'
//     },
//     seller: {
//         type: String,
//         required: true,
//         ref: 'user_basic'
//     },
//     price: {
//         type: Number,
//         required: true,
//         min: 0
//     },
//     payment_details: {
//         type: String,
//         required: true
//     },
//     status: {
//         type: String,
//         enum: ['active', 'pending', 'sold', 'cancelled'],
//         default: 'active'
//     },
//     created_at: {
//         type: Date,
//         default: Date.now
//     },
//     updated_at: {
//         type: Date,
//         default: Date.now
//     }
// });

// marketplaceListingSchema.index({ piece_id: 1 }, { unique: true });

// const MarketplaceListing = mongoose.model('MarketplaceListing', marketplaceListingSchema);
// module.exports = MarketplaceListing;
