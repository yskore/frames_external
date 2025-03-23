const OTP = require('../models/otp');
const { sendVerificationEmail } = require('../utils/emailUtils');

// Generate a random 6-digit OTP
const generateOTP = () => {
    let otp = '';
    for (let i = 0; i < 6; i++) {
        otp += Math.floor(Math.random() * 10).toString();
    }
    return otp;
};

// Send OTP to user's email
exports.sendOTP = async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email is required'
            });
        }

        const otp = generateOTP();

        await OTP.deleteMany({ email });
        
        const newOTP = new OTP({
            email,
            otp
        });
        
        await newOTP.save();

        try {
             sendVerificationEmail(email, otp);
            
            return res.status(200).json({
                success: true,
                message: 'OTP sent to your email successfully',
                data: {
                    otp: process.env.NODE_ENV === 'development' ? otp : undefined
                }
            });
        } catch (emailError) {
            console.error('Error sending verification email:', emailError);
            
            // If email fails, delete the OTP from database
            await OTP.deleteOne({ _id: newOTP._id });
            
            return res.status(500).json({
                success: false,
                message: 'Failed to send verification email. Please try again.'
            });
        }
    } catch (error) {
        console.error('Error in sendOTP:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};

// Verify OTP
exports.verifyOTP = async (req, res) => {
    try {
        const { email, otp } = req.body;
        
        if (!email || !otp) {
            return res.status(400).json({
                success: false,
                message: 'Email and OTP are required'
            });
        }

        const otpRecord = await OTP.findOne({ email, otp });
        
        if (!otpRecord) {
            return res.status(400).json({
                success: false,
                message: 'Invalid OTP or OTP expired'
            });
        }

        await OTP.deleteOne({ _id: otpRecord._id });

        return res.status(200).json({
            success: true,
            message: 'OTP verified successfully'
        });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};
