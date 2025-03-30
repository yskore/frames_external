const multer = require('multer');
const { Storage } = require('@google-cloud/storage');
const path = require('path');
const fs = require('fs');
const config = require('../config');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(os.tmpdir(), 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter to accept only images
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB max file size
  }
});

// Helper function to properly format the private key
const formatPrivateKey = (privateKey) => {
  // If it's already a properly formatted key, return it
  if (privateKey.includes('-----BEGIN PRIVATE KEY-----') && 
      privateKey.includes('-----END PRIVATE KEY-----') && 
      privateKey.includes('\n')) {
    return privateKey;
  }
  
  // Clean up the key by removing any formatting
  let cleanKey = privateKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\\n/g, '')
    .replace(/\n/g, '')
    .trim();
  
  // Re-format with proper line breaks
  return '-----BEGIN PRIVATE KEY-----\n' + 
         cleanKey.match(/.{1,64}/g).join('\n') + 
         '\n-----END PRIVATE KEY-----\n';
};

// Initialize Google Cloud Storage with properly formatted credentials
const getGCSClient = () => {
  try {
    // Clone the credentials to avoid modifying the original config
    const credentials = JSON.parse(JSON.stringify(config.storage.credentials));
    
    // Format the private key correctly
    credentials.private_key = formatPrivateKey(credentials.private_key);
    
    return new Storage({ credentials });
  } catch (error) {
    console.error('Error initializing Google Cloud Storage client:', error);
    throw new Error('Failed to initialize storage service: ' + error.message);
  }
};

const bucketName = 'x-fabric-419423.appspot.com';

// In-memory storage for tracking previous images (in production, this should be in a database)
const userImageMap = new Map();

exports.uploadImage = [
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file uploaded'
        });
      }

      // Get folder name from request or use default
      const folderName = req.body.folderName || 'default';
      // Get resource ID from request (e.g., piece_id, user_id, etc.)
      const resourceId = req.body.resourceId || req.user.username;
      const resourceType = req.body.resourceType || 'default';
      
      // Create a key for the user's image
      const imageKey = `${resourceType}_${resourceId}`;
      
      // Upload file to Google Cloud Storage
      const gcs = getGCSClient();
      const bucket = gcs.bucket(bucketName);
      const gcsFileName = `${folderName}/${Date.now()}_${path.basename(req.file.path)}`;
      
      // Check if there's a previous image to delete
      if (userImageMap.has(imageKey)) {
        const oldFileName = userImageMap.get(imageKey);
        try {
          // Delete the old file from Google Cloud Storage
          await bucket.file(oldFileName).delete();
          console.log(`Successfully deleted old image: ${oldFileName}`);
        } catch (deleteError) {
          console.error(`Error deleting old image ${oldFileName}:`, deleteError);
          // Continue with upload even if delete fails
        }
      }
      
      await bucket.upload(req.file.path, {
        destination: gcsFileName,
        metadata: {
          contentType: req.file.mimetype,
        },
      });

      // Make the file publicly accessible
      await bucket.file(gcsFileName).makePublic();

      // Generate public URL
      const imageUrl = `https://storage.googleapis.com/${bucketName}/${gcsFileName}`;

      // Save the new filename for this user/resource
      userImageMap.set(imageKey, gcsFileName);

      // Clean up local file
      fs.unlinkSync(req.file.path);

      res.status(200).json({
        success: true,
        message: 'Image uploaded successfully',
        data: {
          imageUrl: imageUrl,
          fileName: gcsFileName,
          resourceId: resourceId,
          resourceType: resourceType
        }
      });
    } catch (error) {
      console.error('Error uploading file:', error);
      // Clean up local file if exists
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to upload image',
        error: error.message
      });
    }
  }
];

exports.deleteImage = async (req, res) => {
  try {
    const { fileName, resourceId, resourceType } = req.body;
    
    if (!fileName && !(resourceId && resourceType)) {
      return res.status(400).json({
        success: false,
        message: 'Either fileName or both resourceId and resourceType are required'
      });
    }

    const gcs = getGCSClient();
    const bucket = gcs.bucket(bucketName);
    
    // If we have a direct fileName, delete it
    if (fileName) {
      await bucket.file(fileName).delete();
      
      // Also remove from our tracking if it exists
      for (const [key, value] of userImageMap.entries()) {
        if (value === fileName) {
          userImageMap.delete(key);
          break;
        }
      }
    } 
    // Otherwise use the resource tracking
    else {
      const imageKey = `${resourceType}_${resourceId}`;
      if (userImageMap.has(imageKey)) {
        const oldFileName = userImageMap.get(imageKey);
        await bucket.file(oldFileName).delete();
        userImageMap.delete(imageKey);
      } else {
        return res.status(404).json({
          success: false,
          message: 'No image found for this resource'
        });
      }
    }

    res.status(200).json({
      success: true,
      message: 'Image deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting file:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete image',
      error: error.message
    });
  }
};

// Set current image for a resource (without uploading a new one)
exports.setCurrentImage = async (req, res) => {
  try {
    const { fileName, resourceId, resourceType } = req.body;
    
    if (!fileName || !resourceId || !resourceType) {
      return res.status(400).json({
        success: false,
        message: 'fileName, resourceId, and resourceType are all required'
      });
    }
    
    // Create a key for the resource's image
    const imageKey = `${resourceType}_${resourceId}`;
    
    // Check if the file exists in the bucket
    const gcs = getGCSClient();
    const bucket = gcs.bucket(bucketName);
    const [exists] = await bucket.file(fileName).exists();
    
    if (!exists) {
      return res.status(404).json({
        success: false,
        message: 'File does not exist in storage'
      });
    }
    
    // Check if there's a previous image to delete
    if (userImageMap.has(imageKey) && req.body.deleteOld) {
      const oldFileName = userImageMap.get(imageKey);
      try {
        // Don't delete if it's the same file
        if (oldFileName !== fileName) {
          await bucket.file(oldFileName).delete();
          console.log(`Successfully deleted old image: ${oldFileName}`);
        }
      } catch (deleteError) {
        console.error(`Error deleting old image ${oldFileName}:`, deleteError);
      }
    }
    
    // Save the filename for this resource
    userImageMap.set(imageKey, fileName);
    
    res.status(200).json({
      success: true,
      message: 'Current image set successfully',
      data: {
        fileName: fileName,
        resourceId: resourceId,
        resourceType: resourceType
      }
    });
  } catch (error) {
    console.error('Error setting current image:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to set current image',
      error: error.message
    });
  }
};

// Get current image for a resource
exports.getCurrentImage = async (req, res) => {
  try {
    const { resourceId, resourceType } = req.query;
    
    if (!resourceId || !resourceType) {
      return res.status(400).json({
        success: false,
        message: 'resourceId and resourceType are required'
      });
    }
    
    const imageKey = `${resourceType}_${resourceId}`;
    
    if (!userImageMap.has(imageKey)) {
      return res.status(404).json({
        success: false,
        message: 'No image found for this resource'
      });
    }
    
    const fileName = userImageMap.get(imageKey);
    const imageUrl = `https://storage.googleapis.com/${bucketName}/${fileName}`;
    
    res.status(200).json({
      success: true,
      message: 'Current image retrieved successfully',
      data: {
        imageUrl: imageUrl,
        fileName: fileName
      }
    });
  } catch (error) {
    console.error('Error getting current image:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get current image',
      error: error.message
    });
  }
};
