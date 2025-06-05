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

/**
 * Send a transaction notification email
 * @param {Object} options - Email options
 * @param {string} options.email - Recipient email
 * @param {string} options.subject - Email subject
 * @param {string} options.message - Main message content
 * @param {Object} options.transaction - Transaction details
 */
const sendTransactionEmail = async (options) => {
  try {
    const transporter = createTransporter();

    const info = await transporter.sendMail({
      from: `"${config.smtp.sender_name}" <${config.smtp.username}>`,
      to: options.email,
      subject: options.subject || 'Transaction Update',
      text: options.message,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">${options.subject || 'Transaction Update'}</h2>
          <p>${options.message}</p>
          
          ${options.transaction ? `
          <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin-top: 20px;">
            <h3 style="margin-top: 0;">Transaction Details</h3>
            <p><strong>ID:</strong> ${options.transaction.id || 'N/A'}</p>
            <p><strong>Amount:</strong> ${options.transaction.amount || 'N/A'}</p>
            <p><strong>Date:</strong> ${options.transaction.date || new Date().toISOString()}</p>
            <p><strong>Status:</strong> ${options.transaction.status || 'Pending'}</p>
          </div>
          ` : ''}
          
          <p style="color: #777; font-size: 12px; margin-top: 30px;">This is an automated message from Frames App. Please do not reply to this email.</p>
        </div>
      `
    });

    console.log('Transaction email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending transaction email:', error);
    throw error;
  }
};

/**
 * Send a regular notification email (not transaction-specific)
 * @param {Object} options - Email options
 * @param {string} options.email - Recipient email
 * @param {string} options.subject - Email subject
 * @param {string} options.message - Main message content
 * @param {Object} options.data - Additional notification data
 */
const sendNotificationEmail = async (options) => {
  try {
    const transporter = createTransporter();

    const info = await transporter.sendMail({
      from: `"${config.smtp.sender_name}" <${config.smtp.username}>`,
      to: options.email,
      subject: options.subject || 'Frames App Notification',
      text: options.message,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">${options.subject || 'Frames App Notification'}</h2>
          <p>${options.message}</p>
          
          ${options.data && options.data.pieceTitle ? `
          <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin-top: 20px;">
            <h3 style="margin-top: 0;">Details</h3>
            <p><strong>Piece:</strong> ${options.data.pieceTitle}</p>
            ${options.data.fromUsername ? `<p><strong>From:</strong> ${options.data.fromUsername}</p>` : ''}
            ${options.data.amount ? `<p><strong>Amount:</strong> $${options.data.amount}</p>` : ''}
            <p><strong>Date:</strong> ${new Date().toLocaleDateString()}</p>
          </div>
          ` : ''}
          
          <p style="color: #777; font-size: 12px; margin-top: 30px;">This is an automated message from Frames App. Please do not reply to this email.</p>
        </div>
      `
    });

    console.log('Notification email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending notification email:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendVerificationEmail,
  sendTransactionEmail,
  sendNotificationEmail,
};
