const config = require('../config');

const validateApiKey = (req, res, next) => {
    const apiKey = req.header(config.api.header);
    
    if (!apiKey || apiKey !== config.api.key) {
        return res.status(401).json({
            success: false,
            message: 'Unauthorized'
        });
    }
    
    next();
};

module.exports = validateApiKey;
