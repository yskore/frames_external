const nodemailer = require('nodemailer');
const config = require('../config');

// Create reusable transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    host: config.smtp.server,
    port: 587,
    secure: false,
    auth: {
      user: config.smtp.username,
      pass: config.smtp.password,
    },
  });
};

// Send verification code email
const sendVerificationEmail = async (email, verificationCode) => {
  try {
    const transporter = createTransporter();
    
    const info = await transporter.sendMail({
      from: `"${config.smtp.sender_name}" <${config.smtp.username}>`,
      to: email,
      subject: `Verification Code :: ${new Date().toISOString()}`,
      text: `Your verification code is: ${verificationCode}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Verification Code</h2>
          <p>Please use the following code to verify your account:</p>
          <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; text-align: center; font-size: 24px; letter-spacing: 5px; font-weight: bold;">
            ${verificationCode}
          </div>
          <p style="margin-top: 20px;">This code will expire in 5 minutes.</p>
          <p style="color: #777; font-size: 12px; margin-top: 30px;">If you didn't request this verification, please ignore this email.</p>
        </div>
      `
    });

    console.log('Email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
};

module.exports = {
  sendVerificationEmail
};
