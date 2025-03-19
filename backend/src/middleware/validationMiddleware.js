const validateUserCreation = (req, res, next) => {
    const { username, password, email, firstName, lastName } = req.body;

    // Username validation
    if (!username || username.length < 3 || username.length > 30) {
        return res.status(400).json({
            success: false,
            message: 'Username must be between 3 and 30 characters'
        });
    }

    // Password validation - only check for minimum length of 8 characters
    if (!password || password.length < 8) {
        return res.status(400).json({
            success: false,
            message: 'Password must be at least 8 characters long'
        });
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
        return res.status(400).json({
            success: false,
            message: 'Please provide a valid email address'
        });
    }

    // Name validation
    if (!firstName || !lastName || firstName.length < 2 || lastName.length < 2) {
        return res.status(400).json({
            success: false,
            message: 'First and last names must be at least 2 characters long'
        });
    }

    next();
};

module.exports = {
    validateUserCreation
};
