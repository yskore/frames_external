const user_basic = require('../models/user_basic');
const Followers = require('../models/followers');
const Following = require('../models/following');
const { generateAccessToken } = require('../utils/tokenUtils');
const { hashPassword, comparePassword } = require('../utils/passwordUtils');
const profileController = require('./profileController'); 

// Create new user
exports.createUser = async (req, res) => {
    try {
        const { username, email, password } = req.body;

        // Check if user exists using the existing function
        const existingUserByUsername = await user_basic.findOne({ username });
        if (existingUserByUsername) {
            return res.status(400).json({ success: false, message: 'Username already exists' });
        }

        const existingUserByEmail = await user_basic.findOne({ email });
        if (existingUserByEmail) {
            return res.status(400).json({ success: false, message: 'Email already exists' });
        }

        // Hash password
        const hashedPassword = await hashPassword(password);

        // If user doesn't exist, proceed with user creation
        const newUser = new user_basic({
            ...req.body,
            password: hashedPassword
        });

        const savedUser = await newUser.save();

        // Create followers document
        const newFollowers = new Followers({
            username: savedUser.username,
            chunkIndex: 0,
            followers: []
        });
        await newFollowers.save();

        // Create following document
        const newFollowing = new Following({
            username: savedUser.username,
            chunkIndex: 0,
            following: []
        });
        await newFollowing.save();

        // Remove password from response
        const userResponse = savedUser.toObject();
        delete userResponse.password;

        req.user = { username: savedUser.username };
        await profileController.setProfile(req, { 
            status: (code) => ({ json: (data) => {} }),
        });

        res.status(201).json({ success: true, message: "", data: userResponse });
    } catch (err) {
        console.error('Error adding new user:', err);
        if (process.env.NODE_ENV === 'development') {
            res.status(500).json({ success: false, message: err.message });
        } else {
            res.status(500).json({ success: false, message: 'Internal server error' });
        }
    }
};

// Check if user exists
exports.checkUserExists = async (req, res) => {
    try {
        const { username, email } = req.body;

        const existingUserByUsername = await user_basic.findOne({ username });
        if (existingUserByUsername) {
            return res.status(400).json({
                success: false, message: 'Username already exists', data: {
                    exists: true
                }
            });
        }

        const existingUserByEmail = await user_basic.findOne({ email });
        if (existingUserByEmail) {
            return res.status(400).json({
                success: false, message: 'Email already exists', data: {
                    exists: true
                }
            });
        }

        res.status(200).json({
            success: true, message: 'Username and email are available', data: {
                exists: false
            }
        });
    } catch (err) {
        console.error('Error checking username and email:', err);
        if (process.env.NODE_ENV === 'development') {
            res.status(500).json({
                success: false, message: err.message, data: {
                    exists: false
                }
            });
        } else {
            res.status(500).json({
                success: false, message: 'Internal server error', data: {
                    exists: false
                }
            });
        }
    }
};

// Login user
exports.loginUser = async (req, res) => {
    try {
        const user = await user_basic.findOne({ "username": req.body.username });
        if (!user) return res.status(400).json({ success: false, message: 'Invalid credentials.' });

        const validPassword = await comparePassword(req.body.password, user.password);
        if (!validPassword) {
            return res.status(400).json({ success: false, message: 'Invalid credentials.' });
        }

        const accessToken = generateAccessToken(user);
        res.status(200).json({
            success: true,
            message: 'Logged in successfully',
            data: {
                accessToken: accessToken,
            }
        });
    } catch (err) {
        console.log('Error logging in user:', err);
        
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// Get user info
exports.getUserInfo = async (req, res) => {
    try {
        const { username } = req.query;

        if (!username && !req.user) {
            return res.status(400).json({ success: false, message: 'No username provided' });
        }


        // If no username provided in query, use authenticated user's username
        const queryUsername = username || req.user.username;

        const user = await user_basic.findOne({ username: queryUsername });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Remove sensitive information
        const userResponse = user.toObject();
        delete userResponse.password;


        res.status(200).json({
            success: true,

            data: {

                user: userResponse,
                isOwnProfile: req.user ? (req.user.username === username) : false
            }
        });
    } catch (err) {
        console.error('Error getting user information:', err);
        if (process.env.NODE_ENV === 'development') {
            res.status(500).json({ success: false, message: err.message });
        } else {
            res.status(500).json({ success: false, message: 'Internal server error' });
        }
    }
};

// Protected route handler
exports.protectedRoute = (req, res) => {
    res.json({ message: 'Welcome to the protected route!', user: req.user });
};
