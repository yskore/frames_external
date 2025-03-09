const jwt = require('jsonwebtoken');
const config = require('../config');

const generateAccessToken = (user) => {
    return jwt.sign(
        { username: user.username, id: user._id },
        config.jwt.secretKey,
        { expiresIn: config.jwt.expiresIn }
    );
};

const verifyAccessToken = (token) => {
    try {
        return jwt.verify(token, config.jwt.secretKey);
    } catch (error) {
        return null;
    }
};

// const authenticate = (req, res, next) => {
//   const token = req.headers.authorization?.split(' ')[1];
//   if (!token) {
//     return res.status(401).json({ message: 'Authentication required' });
//   }

//   const decoded = verifyAccessToken(token);
//   if (!decoded) {
//     return res.status(401).json({ message: 'Invalid token' });
//   }

//   req.userId = decoded.userId;
//   next();
// };

module.exports = {
  generateAccessToken,
  verifyAccessToken,
  // authenticate
};
