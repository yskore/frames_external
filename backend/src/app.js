const mongoose = require('mongoose');
const express = require('express');
const connectToDb = require('./config/database');

// Connect to MongoDB
connectToDb();

const app = express();
app.use(express.json());

// Import all models
require('./models');

// Import all routes
const {
    userRoutes,
    pieceRoutes,
    anchorRoutes,
    frameRoutes,
    profileRoutes,
    otpRoutes,
    storageRoutes
} = require('./routes');

app.get('/', (req, res) => {
    res.send('Hello from App Engine!');
});

// Use routes
app.use(userRoutes);
app.use(pieceRoutes);
app.use(anchorRoutes);
app.use(frameRoutes);
app.use(profileRoutes);
app.use(otpRoutes);
app.use(storageRoutes);

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});