const Followers = require('../models/followers');
const Following = require('../models/following');
const Piece = require('../models/pieces');
const UserProfile = require('../models/user_profile');

exports.getFollowerCount = async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({ success: false, message: 'Username is required' });
        }

        const followerDocs = await Followers.find({ username });
        let totalFollowers = followerDocs.reduce((total, doc) => total + doc.followers.length, 0);

        res.json({
            success: true,
            message: 'Follower count retrieved successfully',
            data: { username, followerCount: totalFollowers }
        });
    } catch (error) {
        console.error('Error in getFollowerCount:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.getFollowingCount = async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({ success: false, message: 'Username is required' });
        }

        const followingDocs = await Following.find({ username });
        let totalFollowing = followingDocs.reduce((total, doc) => total + doc.following.length, 0);

        res.json({
            success: true,
            message: 'Following count retrieved successfully',
            data: { username, followingCount: totalFollowing }
        });
    } catch (error) {
        console.error('Error in getFollowingCount:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.getPieceCount = async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({ success: false, message: 'Username is required' });
        }

        const pieceCount = await Piece.countDocuments({ Piece_owner: username });
        res.json({
            success: true,
            message: 'Piece count retrieved successfully',
            data: { username, pieceCount }
        });
    } catch (error) {
        console.error('Error in getPieceCount:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.getPiecesByOwner = async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({ success: false, message: 'Username is required' });
        }

        const pieces = await Piece.find({ Piece_owner: username });
        const piecesData = pieces.map(piece => ({
            Piece_Object: piece.Piece_Object,
            Piece_id: piece.Piece_id,
            Piece_owner: piece.Piece_owner,
            Piece_title: piece.Piece_title,
            Frame_name: piece.Frame_name,
            live_status: piece.live_status,
            Piece_likes: piece.Piece_likes,
            Piece_location: piece.Piece_location,
            Piece_description: piece.Piece_description,
            Piece_creation_date: piece.Piece_creation_date,
            Piece_display: piece.Piece_display,
            Piece_for_sale: piece.Piece_for_sale,
            Piece_price: piece.Piece_price
        }));

        res.json({
            success: true,
            message: 'Pieces retrieved successfully',
            data: { username, pieces: piecesData }
        });
    } catch (error) {
        console.error('Error in getPiecesByOwner:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.getProfile = async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({ success: false, message: 'Username is required' });
        }

        const userProfile = await UserProfile.findOne({ username });
        if (!userProfile) {
            return res.status(404).json({ success: false, message: 'User profile not found' });
        }

        res.json({
            success: true,
            message: 'Profile retrieved successfully',
            data: { profile: userProfile }
        });
    } catch (error) {
        console.error('Error in getProfile:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.setProfile = async (req, res) => {
    try {
        // Use authenticated user's username
        const username = req.user.username;

        let user = await UserProfile.findOne({ username });

        if (!user) {
            user = new UserProfile({
                username, // Changed from Username to username to match model
                Profile_photo: '',
                User_bio: '',
                Paypal_email: req.body.paypalEmail || '',
                Frame_count: 0,
                Like_count: 0,
                User_followers: [],
                User_following: [],
                Live_pieces: 0,
                Is_premium: false,
            });

            await user.save();
        }

        res.status(200).json({
            success: true,
            message: 'Profile set successfully',
            data: { user }
        });
    } catch (err) {
        console.error('Error setting user profile:', err);
        res.status(500).json({ success: false, message: err.message });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const username = req.user.username;
        const { Bio, imageUrl } = req.body;

        const user = await UserProfile.findOne({ username }); // Changed from Username to username

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Update only allowed fields
        if (Bio !== undefined) user.User_bio = Bio;
        if (imageUrl !== undefined) user.Profile_photo = imageUrl;

        await user.save();

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            data: { profile: user }
        });
    } catch (err) {
        console.error('Error updating user profile:', err);
        res.status(500).json({ success: false, message: err.message });
    }
};
