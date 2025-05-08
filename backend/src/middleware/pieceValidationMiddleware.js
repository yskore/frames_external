const validatePieceInput = (req, res, next) => {
    console.log("Request body in validation:", JSON.stringify(req.body));
    
    const pieceForSale = req.body.Piece_for_sale;
    const payment_details = req.body.payment_details;
    
    console.log("Piece for sale value:", pieceForSale, "Type:", typeof pieceForSale);
    
    if (pieceForSale === true) {
      console.log("Entering validation for pieces marked for sale");
      const piecePrice = req.body.Piece_price;
      const currency = req.body.currency;
      
      console.log("Piece price:", piecePrice);
      
      if (!piecePrice || piecePrice <= 0) {
        return res.status(400).json({
          success: false,
          message: "A valid price greater than 0 is required for pieces marked for sale",
        });
      }
      
      if (!currency || typeof currency !== "string" || !currency.trim()) {
        return res.status(400).json({
          success: false,
          message: "Currency is required for pieces marked for sale",
        });
      }
  
      if (
        !payment_details ||
        typeof payment_details !== "string" ||
        !payment_details.trim()
      ) {
        return res.status(400).json({
          success: false,
          message: "Payment details are required for pieces marked for sale",
        });
      }
    } else {
      console.log("Piece not for sale, skipping price validation");
    }
  
    next();
  };
  
  const validateSaleToggle = (req, res, next) => {
    console.log("Sale toggle request body:", JSON.stringify(req.body));
    
    const { piece_id, for_sale, price, payment_details } = req.body;
    const currency = req.body.currency;
    
    console.log("For sale value:", for_sale, "Type:", typeof for_sale);
    
    if (!piece_id) {
      return res.status(400).json({
        success: false,
        message: "Piece ID is required",
      });
    }
  
    if (for_sale === true) {
      console.log("Entering validation for piece being put up for sale");
      console.log("Price:", price, "Type:", typeof price);
      
      if (!price || price <= 0) {
        return res.status(400).json({
          success: false,
          message: "A valid price greater than 0 is required",
        });
      }
      
      if (!currency || typeof currency !== "string" || !currency.trim()) {
        return res.status(400).json({
          success: false,
          message: "Currency is required for pieces marked for sale",
        });
      }
  
      if (
        !payment_details ||
        typeof payment_details !== "string" ||
        !payment_details.trim()
      ) {
        return res.status(400).json({
          success: false,
          message: "Payment details are required",
        });
      }
    } else {
      console.log("Piece not being put up for sale, skipping price validation");
    }
  
    next();
  };
  
  module.exports = {
    validatePieceInput,
    validateSaleToggle,
  };
