const FeedEntry = require('../models/feed_entry');
const mongoose = require('mongoose');
const { sendFeedNotification } = require('../utils/notificationUtils');

exports.getFeed = async (req, res) => {
    try {
        const username = req.user.username;
        const { limit = 20, offset = 0, filter, unreadOnly } = req.query;

        const query = { for_username: username };

        if (filter) {
            const filterTypes = filter.split(',');
            if (filterTypes.length > 0) {
                query.action_type = { $in: filterTypes };
            }
        }

        // Filter by unread status if requested
        if (unreadOnly === 'true' || unreadOnly === '1') {
            query.read = false;
        }

        const totalCount = await FeedEntry.countDocuments(query);

        const feedEntries = await FeedEntry.find(query)
            .sort({ created_at: -1 })
            .skip(Number(offset))
            .limit(Number(limit));

        const unreadCount = await FeedEntry.countDocuments({
            for_username: username,
            read: false
        });

        res.status(200).json({
            success: true,
            data: {
                feed: feedEntries,
                pagination: {
                    total: totalCount,
                    unread: unreadCount,
                    offset: Number(offset),
                    limit: Number(limit)
                }
            }
        });
    } catch (error) {
        console.error('Error fetching feed:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching feed',
            error: error.message
        });
    }
};

exports.markAsRead = async (req, res) => {
    try {
        const username = req.user.username;
        const { entryIds } = req.body;

        if (!entryIds || !Array.isArray(entryIds) || entryIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Entry IDs array is required'
            });
        }

        const result = await FeedEntry.updateMany(
            {
                _id: { $in: entryIds },
                for_username: username
            },
            { read: true }
        );

        res.status(200).json({
            success: true,
            message: 'Feed entries marked as read',
            data: {
                modified: result.modifiedCount,
                total: entryIds.length
            }
        });
    } catch (error) {
        console.error('Error marking entries as read:', error);
        res.status(500).json({
            success: false,
            message: 'Error marking entries as read',
            error: error.message
        });
    }
};

exports.markAllAsRead = async (req, res) => {
    try {
        const username = req.user.username;

        const result = await FeedEntry.updateMany(
            {
                for_username: username,
                read: false
            },
            { read: true }
        );

        res.status(200).json({
            success: true,
            message: 'All feed entries marked as read',
            data: {
                modified: result.modifiedCount
            }
        });
    } catch (error) {
        console.error('Error marking all entries as read:', error);
        res.status(500).json({
            success: false,
            message: 'Error marking all entries as read',
            error: error.message
        });
    }
};

exports.getUnreadCount = async (req, res) => {
    try {
        const username = req.user.username;

        const unreadCount = await FeedEntry.countDocuments({
            for_username: username,
            read: false
        });

        res.status(200).json({
            success: true,
            data: { unreadCount }
        });
    } catch (error) {
        console.error('Error getting unread count:', error);
        res.status(500).json({
            success: false,
            message: 'Error getting unread count',
            error: error.message
        });
    }
};

exports.deleteFeedEntry = async (req, res) => {
    try {
        const username = req.user.username;
        const { entryId } = req.params;

        // Delete the entry
        const result = await FeedEntry.deleteOne({
            _id: entryId,
            for_username: username
        });

        if (result.deletedCount === 0) {
            return res.status(404).json({
                success: false,
                message: 'Feed entry not found or not owned by you'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Feed entry deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting feed entry:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting feed entry',
            error: error.message
        });
    }
};

exports.createFeedEntry = async (forUsername, fromUsername, actionType, referenceId, pieceTitle, metadata = {}) => {
    try {
        const feedEntry = new FeedEntry({
            for_username: forUsername,
            from_username: fromUsername,
            action_type: actionType,
            reference_id: referenceId,
            piece_title: pieceTitle,
            metadata: metadata || {},
            read: false
        });

        await feedEntry.save();

        const notificationTypeMap = {
            'posted_piece': 'new_piece',
            'made_piece_live': 'piece_live',
            'listed_for_sale': 'piece_for_sale',
            'made_offer': 'new_offer',
            'liked_piece': 'piece_liked',
            'subscribed': 'new_subscriber',
            'sold_piece': 'offer_accepted',
            'purchased_piece': 'payment_confirmed'
        };

        const notificationType = notificationTypeMap[actionType] || actionType;

        // Send notification to the recipient if the entry is created for a specific user
        if (forUsername !== fromUsername) {
            sendFeedNotification({
                userId: forUsername,
                notificationType: notificationType,
                data: {
                    fromUsername: fromUsername,
                    pieceId: referenceId,
                    pieceTitle: pieceTitle,
                    actionType: actionType,
                    ...metadata
                }
            }).catch(err => {
                console.error(`Error sending notification to ${forUsername}:`, err);
            });
        }

        return { success: true, feedEntry };
    } catch (error) {
        console.error('Error creating feed entry:', error);
        return { success: false, error: error.message };
    }
};

// Helper function to create feed entries for all subscribers
exports.createFeedEntryForSubscribers = async (fromUsername, actionType, referenceId, pieceTitle, metadata = {}) => {
    try {
        const result = await FeedEntry.createForSubscribers(
            fromUsername,
            actionType,
            referenceId,
            pieceTitle,
            metadata
        );

        // If feed entries were created successfully, also send notifications to subscribers
        if (result.success && result.subscribers && result.subscribers.length > 0) {
            const notificationTypeMap = {
                'posted_piece': 'new_piece',
                'made_piece_live': 'piece_live',
                'listed_for_sale': 'piece_for_sale',
                'made_offer': 'new_offer',
                'liked_piece': 'piece_liked',
                'subscribed': 'new_subscriber',
                'sold_piece': 'offer_accepted',
                'purchased_piece': 'payment_confirmed'
            };

            const notificationType = notificationTypeMap[actionType] || actionType;

            for (const subscriber of result.subscribers) {
                sendFeedNotification({
                    userId: subscriber,
                    notificationType: notificationType,
                    data: {
                        fromUsername: fromUsername,
                        pieceId: referenceId,
                        pieceTitle: pieceTitle,
                        actionType: actionType,
                        ...metadata
                    }
                }).catch(err => {
                    console.error(`Error sending notification to ${subscriber}:`, err);
                });
            }
        }

        return result;
    } catch (error) {
        console.error('Error creating feed entries for subscribers:', error);
        return { success: false, error: error.message };
    }
};

module.exports = {
    getFeed: exports.getFeed,
    markAsRead: exports.markAsRead,
    markAllAsRead: exports.markAllAsRead,
    getUnreadCount: exports.getUnreadCount,
    deleteFeedEntry: exports.deleteFeedEntry,
    createFeedEntry: exports.createFeedEntry,
    createFeedEntryForSubscribers: exports.createFeedEntryForSubscribers
};
