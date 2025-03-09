const mongoose = require('mongoose');
const config = require('../config');

const connectToDb = async () => {
  try {
    const connection = await mongoose.connect(config.mongodb.uri);
    console.log('Successfully connected to MongoDB');
    return connection;
  } catch (err) {
    console.error('Failed to connect to MongoDB:', err);
    process.exit(1);
  }
};

module.exports = connectToDb;
