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

const validateFlagInput = (req, res, next) => {
    const { flagType } = req.body;

    // Flag type validation
    if (!flagType || !['IN', 'PI'].includes(flagType)) {
        return res.status(400).json({
            success: false,
            message: 'Flag type is required and must be either "IN" (inappropriate) or "PI" (piracy)'
        });
    }

    next();
};

const validateFlagResponse = (req, res, next) => {
    const { action, evidence, comments } = req.body;

    // Action validation
    if (!action || !['accept', 'dispute'].includes(action)) {
        return res.status(400).json({
            success: false,
            message: 'Action is required and must be either "accept" or "dispute"'
        });
    }

    // If disputing, validate evidence or comments
    if (action === 'dispute') {
        if (!evidence && !comments) {
            return res.status(400).json({
                success: false,
                message: 'When disputing, you must provide either evidence or comments'
            });
        }

        // Validate evidence URL if provided
        if (evidence && typeof evidence !== 'string') {
            return res.status(400).json({
                success: false,
                message: 'Evidence must be a valid URL string'
            });
        }

        // Validate comments if provided
        if (comments && (typeof comments !== 'string' || comments.length > 1000)) {
            return res.status(400).json({
                success: false,
                message: 'Comments must be a string and not exceed 1000 characters'
            });
        }
    }

    next();
};

const validateAdminDispute = (req, res, next) => {
    const { decision } = req.body;

    // Decision validation
    if (!decision || !['accept', 'reject'].includes(decision)) {
        return res.status(400).json({
            success: false,
            message: 'Decision is required and must be either "accept" or "reject"'
        });
    }

    next();
};

const validatePieceId = (req, res, next) => {
    const { piece_id } = req.body;

    // Piece ID validation
    if (!piece_id || typeof piece_id !== 'string') {
        return res.status(400).json({
            success: false,
            message: 'Piece ID is required and must be a valid string'
        });
    }

    next();
};

const validateOwnershipEvidence = (req, res, next) => {
    const { ownership_evidence, comments } = req.body;

    // At least one field is required for dispute
    if (!ownership_evidence && !comments) {
        return res.status(400).json({
            success: false,
            message: 'Either ownership evidence or comments must be provided'
        });
    }

    // Validate ownership evidence URL if provided
    if (ownership_evidence && typeof ownership_evidence !== 'string') {
        return res.status(400).json({
            success: false,
            message: 'Ownership evidence must be a valid URL string'
        });
    }

    // Validate comments if provided
    if (comments && (typeof comments !== 'string' || comments.length > 1000)) {
        return res.status(400).json({
            success: false,
            message: 'Comments must be a string and not exceed 1000 characters'
        });
    }

    next();
};

module.exports = {
    validateUserCreation,
    validateFlagInput,
    validateFlagResponse,
    validateAdminDispute,
    validatePieceId,
    validateOwnershipEvidence
};
