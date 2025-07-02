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
    storageRoutes,
    adminRoutes,
    offerRoutes,
    likeRoutes,
    impressionRoutes,
    notificationSettingsRoutes,
    feedRoutes,
} = require('./routes');

const { initializeFirebaseApp } = require('./utils/notificationUtils');
const { initCronJobs } = require('./utils/cronJobs');
const { runMigrations } = require('./utils/migrations');

try {
  initializeFirebaseApp();
  console.log('Firebase initialized for push notifications');
} catch (error) {
  console.error('Failed to initialize Firebase:', error);
}

// Run migrations on startup
runMigrations().catch(error => {
  console.error('Failed to run migrations:', error);
});

try {
  initCronJobs();
} catch (error) {
  console.error('Failed to initialize cron jobs:', error);
}

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
app.use(adminRoutes);
app.use(offerRoutes);
app.use(likeRoutes);
app.use(impressionRoutes);
app.use(notificationSettingsRoutes);
app.use(feedRoutes);

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
