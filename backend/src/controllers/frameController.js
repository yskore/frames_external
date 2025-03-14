const Frame = require('../models/frames');
const mongoose = require('mongoose');

exports.getAllFrames = async (req, res) => {
    try {
        const frames = await Frame.find();
        res.status(200).json({
            success: true,
            message: 'Frames fetched successfully',
            data: { frames }
        });
    } catch (error) {
        console.error('Error fetching frames:', error);
        res.status(500).json({ success: false, message: 'Error fetching frames' });
    }
};

exports.createFrame = async (req, res) => {
    const {
        Frame_object,
        Frame_owner,
        Frame_display,
        Frame_collaborators,
        Frame_title,
        Frame_description,
        Frame_creation_date,
        Frame_for_sale,
        Frame_price,
        Face_name
    } = req.body;

    try {
        const newFrame = new Frame({
            Frame_object,
            Frame_owner,
            Frame_display,
            Frame_collaborators,
            Frame_title,
            Frame_description,
            Frame_creation_date,
            Frame_for_sale,
            Frame_price,
            Face_name
        });

        await newFrame.save();
        res.status(201).json({
            success: true,
            message: 'New frame created successfully',
            data: { frame: newFrame }
        });
    } catch (err) {
        console.error('Error creating new frame:', err);
        res.status(500).json({ success: false, message: 'Failed to create new frame.' });
    }
};

exports.updateFrame = async (req, res) => {
    try {
        const { frameId } = req.params;
        const updates = req.body;

        const frame = await Frame.findByIdAndUpdate(
            frameId,
            updates,
            { new: true, runValidators: true }
        );

        if (!frame) {
            return res.status(404).json({
                success: false,
                message: 'Frame not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Frame updated successfully',
            data: { frame }
        });
    } catch (error) {
        console.error('Error updating frame:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update frame',
            error: error.message
        });
    }
};

exports.deleteFrame = async (req, res) => {
    try {
        const { frameId } = req.params;

        const frame = await Frame.findByIdAndDelete(frameId);

        if (!frame) {
            return res.status(404).json({
                success: false,
                message: 'Frame not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Frame deleted successfully',
            data: null
        });
    } catch (error) {
        console.error('Error deleting frame:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete frame',
            error: error.message
        });
    }
};
