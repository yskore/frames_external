const mongoose = require('mongoose');
const Piece = require('../models/pieces');

const migratePiecesFlagFields = async () => {
    try {
        console.log('Starting pieces flag fields migration...');
        
        const result = await Piece.updateMany(
            { flag_status: { $exists: false } },
            { 
                $set: { 
                    flag_status: 'normal'
                }
            }
        );

        console.log(`Migration completed. Updated ${result.modifiedCount} pieces.`);
        return { success: true, modifiedCount: result.modifiedCount };
        
    } catch (error) {
        console.error('Migration failed:', error);
        return { success: false, error: error.message };
    }
};

module.exports = {
    migratePiecesFlagFields
};