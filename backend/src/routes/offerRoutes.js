const express = require('express');
const router = express.Router();
const offerController = require('../controllers/offerController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');
const storageController = require('../controllers/storageController');

router.use(validateApiKey);

// Create new offer
router.post('/create-offer', validateToken, offerController.createOffer);
router.get('/piece-offers/:piece_id', validateToken, offerController.getPieceOffers);
router.get('/my-received-offers', validateToken, offerController.getReceivedOffers);
router.get('/my-made-offers', validateToken, offerController.getMadeOffers);
router.post('/accept-offer/:offerId', validateToken, offerController.acceptOffer);
router.post('/submit-payment-proof/:offerId', validateToken, (req, res, next) => {
    req.body.folderName = 'payment_proofs'; 
    next();
}, storageController.uploadImage, offerController.submitPaymentProof);

router.get('/payment-proof/:offerId', validateToken, offerController.getPaymentProof);
router.post('/confirm-payment/:offerId', validateToken, offerController.confirmPayment);
router.post('/deny-payment/:offerId', validateToken, offerController.denyPayment);

module.exports = router;
