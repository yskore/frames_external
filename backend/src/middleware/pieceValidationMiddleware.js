const validatePieceInput = (req, res, next) => {
  const { Piece_for_sale, Piece_price, payment_details } = req.body;

  if (Piece_for_sale) {
    if (!Piece_price || Piece_price <= 0) {
      return res.status(400).json({
        success: false,
        message:
          "A valid price greater than 0 is required for pieces marked for sale",
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
  }

  next();
};

const validateSaleToggle = (req, res, next) => {
  const { piece_id, for_sale, price, payment_details } = req.body;

  if (!piece_id) {
    return res.status(400).json({
      success: false,
      message: "Piece ID is required",
    });
  }

  if (for_sale) {
    if (!price || price <= 0) {
      return res.status(400).json({
        success: false,
        message: "A valid price greater than 0 is required",
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
  }

  next();
};

module.exports = {
  validatePieceInput,
  validateSaleToggle,
};
