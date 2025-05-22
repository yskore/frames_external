const Followers = require('../models/followers');
const Following = require('../models/following');
const Piece = require('../models/pieces');
const UserProfile = require('../models/user_profile');
const user_basic = require('../models/user_basic');
const { createFeedEntryForSubscribers } = require('./feedController');

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


exports.getProfile = async (req, res) => {
    try {
        // Get username from token instead of params
        const username = req.user.username;
        
        // Get user profile
        const userProfile = await UserProfile.findOne({ username });
        if (!userProfile) {
            return res.status(404).json({ 
                success: false, 
                message: 'User profile not found' 
            });
        }

        const userPieces = await Piece.find({ Piece_owner: username });
    
        
        // Calculate counts
        const subscriberCount = userProfile.mySubscribers ? userProfile.mySubscribers.length : 0;
        const subscriptionCount = userProfile.mySubscriptions ? userProfile.mySubscriptions.length : 0;
        const totalImpressions = userPieces.reduce((sum, piece) => sum + (piece.Piece_impressions || 0), 0);

        const profileWithCounts = userProfile.toObject();
        profileWithCounts.subscriberCount = subscriberCount;
        profileWithCounts.subscriptionCount = subscriptionCount;
        profileWithCounts.totalImpressions = totalImpressions;
        profileWithCounts.pieceCount = userPieces.length;
        
        // Remove array fields from response
        delete profileWithCounts.mySubscribers;
        delete profileWithCounts.mySubscriptions;
        delete profileWithCounts.User_followers;
        delete profileWithCounts.User_following;

        res.json({
            success: true,
            message: 'Profile retrieved successfully',
            data: { profile: profileWithCounts }
        });
    } catch (error) {
        console.error('Error in getProfile:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.setProfile = async (req, res) => {
    try {
        const username = req.user.username;

        let user = await UserProfile.findOne({ username });

        if (!user) {
            user = new UserProfile({
                username,
                Profile_photo: '',
                User_bio: '',
                Paypal_email: req.body.paypalEmail || '',
                Frame_count: 0,
                Like_count: 0,
                mySubscribers: [],
                mySubscriptions: [],
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

        try {
            await user.save();
        } catch (saveError) {
            console.error('Error saving user:', saveError);
            return res.status(500).json({ success: false, message: 'Failed to save user data' });
        }

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

// Search users by username
exports.searchUsersByUsername = async (req, res) => {
    try {
        const { query } = req.body;

        if (!query) {
            return res.status(400).json({
                success: false,
                message: 'Search query is required'
            });
        }

        const searchPattern = new RegExp(query, 'i');

        const basicUsers = await user_basic.find(
            { username: searchPattern },
            { username: 1, firstName: 1, lastName: 1, _id: 0 }
        ).limit(20);
        
        const enhancedUsers = await Promise.all(
            basicUsers.map(async (user) => {
                const userProfile = await UserProfile.findOne({ username: user.username });
                const subscriberCount = userProfile?.mySubscribers?.length || 0;
                const livePiecesCount = userProfile?.Live_pieces || 0;
                
                return {
                    ...user.toObject(),
                    subscriberCount,
                    livePiecesCount
                };
            })
        );

        res.json({
            success: true,
            message: 'Users retrieved successfully',
            data: { users: enhancedUsers }
        });
    } catch (error) {
        console.error('Error in searchUsersByUsername:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

exports.getPiecesByOwner = async (req, res) => {
    try {
        const username = req.user.username;
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
            Piece_impressions: piece.Piece_impressions,
            Piece_location: piece.Piece_location,
            Piece_description: piece.Piece_description,
            Piece_creation_date: piece.Piece_creation_date,
            Piece_display: piece.Piece_display,
            Piece_for_sale: piece.Piece_for_sale,
            Piece_price: piece.Piece_price,
            ownership: piece.ownership,
            currency: piece.currency,
            payment_details: piece.payment_details,
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
}

// Get user profile with pieces
exports.getProfileWithPieces = async (req, res) => {
    try {
        const username = req.params.username;
        // Get the authenticated user's username (if logged in)
        const currentUser = req.user ? req.user.username : null;

        if (!username) {
            return res.status(400).json({
                success: false,
                message: 'Username is required'
            });
        }

        // Get user profile
        const userProfile = await UserProfile.findOne({ username });

        if (!userProfile) {
            return res.status(404).json({
                success: false,
                message: 'User profile not found'
            });
        }

        // Get user's pieces
        const pieces = await Piece.find({ Piece_owner: username });


            // Calculate counts
        const subscriberCount = userProfile.mySubscribers ? userProfile.mySubscribers.length : 0;
        const subscriptionCount = userProfile.mySubscriptions ? userProfile.mySubscriptions.length : 0;
        const totalImpressions = pieces.reduce((sum, piece) => sum + (piece.Piece_impressions || 0), 0);

        const profileWithCounts = userProfile.toObject();
        profileWithCounts.subscriberCount = subscriberCount;
        profileWithCounts.subscriptionCount = subscriptionCount;
        profileWithCounts.totalImpressions = totalImpressions;
        profileWithCounts.pieceCount = pieces.length;
        
        let isSubscribed = false;
        if (currentUser && currentUser !== username) {
            const followingDoc = await Following.findOne({ 
                username: currentUser,
                chunkIndex: 0 
            });
            
            isSubscribed = followingDoc ? 
                followingDoc.following.includes(username) : 
                false;
        }
        
        
        // Remove array fields from response
        delete profileWithCounts.mySubscribers;
        delete profileWithCounts.mySubscriptions;
        delete profileWithCounts.User_followers;
        delete profileWithCounts.User_following;

        // Format piece data
        const piecesData = pieces.map(piece => ({
            Piece_Object: piece.Piece_Object,
            Piece_id: piece.Piece_id,
            Piece_owner: piece.Piece_owner,
            Piece_title: piece.Piece_title,
            Frame_name: piece.Frame_name,
            live_status: piece.live_status,
            Piece_likes: piece.Piece_likes,
            Piece_impressions: piece.Piece_impressions,
            Piece_location: piece.Piece_location,
            Piece_description: piece.Piece_description,
            Piece_creation_date: piece.Piece_creation_date,
            Piece_display: piece.Piece_display,
            Piece_for_sale: piece.Piece_for_sale,
            currency: piece.currency,
            payment_details: piece.payment_details,
            Piece_price: piece.Piece_price,
            ownership: piece.ownership,
        }));
        

        res.json({
            success: true,
            message: 'Profile and pieces retrieved successfully',
            data: {
                profile: profileWithCounts,
                pieces: piecesData,
                isSubscribed
            }
        });
    } catch (error) {
        console.error('Error in getProfileWithPieces:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Subscribe to a user
exports.subscribeToUser = async (req, res) => {
    try {
        const subscriber = req.user.username; // The authenticated user who wants to subscribe
        const { targetUsername } = req.body; // The user to subscribe to

        if (!targetUsername) {
            return res.status(400).json({
                success: false,
                message: 'Target username is required'
            });
        }

        // Check if target user exists
        const targetUser = await user_basic.findOne({ username: targetUsername });
        if (!targetUser) {
            return res.status(404).json({
                success: false,
                message: 'Target user not found'
            });
        }

        // Check if user is trying to subscribe to themselves
        if (subscriber === targetUsername) {
            return res.status(400).json({
                success: false,
                message: 'You cannot subscribe to yourself'
            });
        }

        // Add target user to subscriber's following list
        let followingDoc = await Following.findOne({ 
            username: subscriber,
            chunkIndex: 0 
        });

        if (!followingDoc) {
            followingDoc = new Following({
                username: subscriber,
                chunkIndex: 0,
                following: [targetUsername]
            });
        } else if (!followingDoc.following.includes(targetUsername)) {
            followingDoc.following.push(targetUsername);
        } else {
            return res.status(400).json({
                success: false,
                message: 'You are already subscribed to this user'
            });
        }
        await followingDoc.save();

        // Add subscriber to target user's followers list
        let followersDoc = await Followers.findOne({ 
            username: targetUsername,
            chunkIndex: 0 
        });

        if (!followersDoc) {
            followersDoc = new Followers({
                username: targetUsername,
                chunkIndex: 0,
                followers: [subscriber]
            });
        } else if (!followersDoc.followers.includes(subscriber)) {
            followersDoc.followers.push(subscriber);
        }
        await followersDoc.save();

        // Update subscription counts in user profiles
        await UserProfile.findOneAndUpdate(
            { username: subscriber },
            { $addToSet: { mySubscriptions: targetUsername } }
        );

        await UserProfile.findOneAndUpdate(
            { username: targetUsername },
            { $addToSet: { mySubscribers: subscriber } }
        );

        // Create feed entries for all subscribers of the user who just subscribed
        await createFeedEntryForSubscribers(
            subscriber,
            'subscribed',
            targetUsername,  
            null,            
            { 
                subscriberUsername: subscriber,
                subscriberName: `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim(),
                targetUsername: targetUsername,
                targetName: `${targetUser.firstName || ''} ${targetUser.lastName || ''}`.trim()
            }
        );

        res.status(200).json({
            success: true,
            message: `Successfully subscribed to ${targetUsername}`,
            data: { targetUsername }
        });
    } catch (error) {
        console.error('Error in subscribeToUser:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Unsubscribe from a user
exports.unsubscribeFromUser = async (req, res) => {
    try {
        const subscriber = req.user.username;
        const { targetUsername } = req.body;

        if (!targetUsername) {
            return res.status(400).json({
                success: false,
                message: 'Target username is required'
            });
        }

        // Remove target from subscriber's following list
        const followingDoc = await Following.findOne({ 
            username: subscriber,
            chunkIndex: 0 
        });

        if (!followingDoc || !followingDoc.following.includes(targetUsername)) {
            return res.status(400).json({
                success: false,
                message: 'You are not subscribed to this user'
            });
        }

        followingDoc.following = followingDoc.following.filter(username => username !== targetUsername);
        await followingDoc.save();

        // Remove subscriber from target's followers list
        const followersDoc = await Followers.findOne({ 
            username: targetUsername,
            chunkIndex: 0 
        });

        if (followersDoc && followersDoc.followers.includes(subscriber)) {
            followersDoc.followers = followersDoc.followers.filter(username => username !== subscriber);
            await followersDoc.save();
        }
        
        // Update subscription counts in user profiles
        await UserProfile.findOneAndUpdate(
            { username: subscriber },
            { $pull: { mySubscriptions: targetUsername } }
        );

        await UserProfile.findOneAndUpdate(
            { username: targetUsername },
            { $pull: { mySubscribers: subscriber } }
        );

        res.status(200).json({
            success: true,
            message: `Successfully unsubscribed from ${targetUsername}`,
            data: { targetUsername }
        });
    } catch (error) {
        console.error('Error in unsubscribeFromUser:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get my subscribers (people who subscribed to me)
exports.getMySubscribers = async (req, res) => {
    try {
        const username = req.user.username;
        
        const followerDocs = await Followers.find({ username });
        
        const subscriberUsernames = [];
        followerDocs.forEach(doc => {
            subscriberUsernames.push(...doc.followers);
        });

        const subscribersWithDetails = await user_basic.find(
            { username: { $in: subscriberUsernames } },
            { username: 1, firstName: 1, lastName: 1, _id: 0 }
        );

        res.status(200).json({
            success: true,
            message: 'Subscribers retrieved successfully',
            data: { 
                subscribers: subscribersWithDetails, 
                count: subscribersWithDetails.length 
            }
        });
    } catch (error) {
        console.error('Error in getMySubscribers:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get my subscriptions (people I'm subscribed to)
exports.getMySubscriptions = async (req, res) => {
    try {
        const username = req.user.username;
        
        const followingDocs = await Following.find({ username });
        
        const subscriptionUsernames = [];
        followingDocs.forEach(doc => {
            subscriptionUsernames.push(...doc.following);
        });

        const subscriptionsWithDetails = await user_basic.find(
            { username: { $in: subscriptionUsernames } },
            { username: 1, firstName: 1, lastName: 1, _id: 0 }
        );

        res.status(200).json({
            success: true,
            message: 'Subscriptions retrieved successfully',
            data: { 
                subscriptions: subscriptionsWithDetails, 
                count: subscriptionsWithDetails.length 
            }
        });
    } catch (error) {
        console.error('Error in getMySubscriptions:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Check if user is subscribed to target
exports.checkSubscriptionStatus = async (req, res) => {
    try {
        const subscriber = req.user.username;
        const { targetUsername } = req.body;

        if (!targetUsername) {
            return res.status(400).json({
                success: false,
                message: 'Target username is required'
            });
        }

        const followingDoc = await Following.findOne({ 
            username: subscriber,
            chunkIndex: 0 
        });

        const isSubscribed = followingDoc ? 
            followingDoc.following.includes(targetUsername) : 
            false;

        res.status(200).json({
            success: true,
            data: { isSubscribed, targetUsername }
        });
    } catch (error) {
        console.error('Error in checkSubscriptionStatus:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get subscribers by username
exports.getSubscribersByUsername = async (req, res) => {
    try {
        const { username } = req.params;
        
        if (!username) {
            return res.status(400).json({
                success: false,
                message: 'Username is required'
            });
        }
        
        // Check if user exists
        const userExists = await user_basic.findOne({ username });
        if (!userExists) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }
        
        const followerDocs = await Followers.find({ username });
        
        const subscriberUsernames = [];
        followerDocs.forEach(doc => {
            subscriberUsernames.push(...doc.followers);
        });

        const subscribersWithDetails = await user_basic.find(
            { username: { $in: subscriberUsernames } },
            { username: 1, firstName: 1, lastName: 1, _id: 0 }
        );

        res.status(200).json({
            success: true,
            message: 'Subscribers retrieved successfully',
            data: { 
                subscribers: subscribersWithDetails, 
                count: subscribersWithDetails.length 
            }
        });
    } catch (error) {
        console.error('Error in getSubscribersByUsername:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
