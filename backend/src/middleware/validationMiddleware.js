const validateUserCreation = (req, res, next) => {
    const { username, password, email, firstName, lastName } = req.body;

    // Username validation
    if (!username || username.length < 3 || username.length > 30) {
        return res.status(400).json({
            success: false,
            message: 'Username must be between 3 and 30 characters'
        });
    }

    // Password validation
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!password || !passwordRegex.test(password)) {
        return res.status(400).json({
            success: false,
            message: 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character'
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
