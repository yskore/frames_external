const jwt = require('jsonwebtoken');
const user_basic = require('../models/user_basic');
const config = require('../config');

exports.validateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; 

        if (!token) {
            return res.status(401).json({ message: 'No token provided' });
        }

        const decoded = jwt.verify(token, config.jwt.secretKey);
        const user = await user_basic.findOne({ username: decoded.username });

        if (!user) {
            return res.status(401).json({ message: 'Invalid token - User not found' });
        }

        req.user = user;
        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ message: 'Invalid token' });
        }
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ message: 'Token expired' });
        }
        return res.status(500).json({ message: 'Internal server error' });
    }
};

exports.validateAdminRole = async (req, res, next) => {
    try {
        // Ensure user exists from previous validateToken middleware
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                message: 'Authentication required' 
            });
        }

        // Check if user has admin role
        if (req.user.userType !== 'admin') {
            return res.status(403).json({ 
                success: false,
                message: 'Admin access required. Insufficient permissions.' 
            });
        }

        // User is authenticated and has admin role
        next();
    } catch (error) {
        console.error('Error in admin role validation:', error);
        return res.status(500).json({ 
            success: false,
            message: 'Internal server error during role validation' 
        });
    }
};


// Validate token and set req.user if token is valid
exports.validateTokenOptional = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];

        if(!authHeader){
            next();
            return;
        }
        const token = authHeader && authHeader.split(' ')[1]; 

        if (!token) {
            next();
            return;        }

        const decoded = jwt.verify(token, config.jwt.secretKey);
        const user = await user_basic.findOne({ username: decoded.username });

        if (!user) {
            return res.status(401).json({ message: 'Invalid token - User not found' });
        }

        req.user = user;
        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ message: 'Invalid token' });
        }
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ message: 'Token expired' });
        }
        return res.status(500).json({ message: 'Internal server error' });
    }
};

exports.validateAdminRole = async (req, res, next) => {
    try {
        // Ensure user exists from previous validateToken middleware
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                message: 'Authentication required' 
            });
        }

        // Check if user has admin role
        if (req.user.userType !== 'admin') {
            return res.status(403).json({ 
                success: false,
                message: 'Admin access required. Insufficient permissions.' 
            });
        }

        // User is authenticated and has admin role
        next();
    } catch (error) {
        console.error('Error in admin role validation:', error);
        return res.status(500).json({ 
            success: false,
            message: 'Internal server error during role validation' 
        });
    }
};
