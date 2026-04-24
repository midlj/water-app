const Payment = require('../models/Payment');
const Bill = require('../models/Bill');
const { AppError } = require('../middlewares/errorHandler');
const logger = require('../utils/logger');

exports.makePayment = async (req, res, next) => {
  try {
    const { billId, amount, paymentMethod, notes } = req.body;

    const bill = await Bill.findById(billId);
    if (!bill) return next(new AppError('Bill not found.', 404));

    if (bill.status === 'paid') {
      return next(new AppError('This bill has already been paid.', 400));
    }

    if (bill.status === 'cancelled') {
      return next(new AppError('Cannot pay a cancelled bill.', 400));
    }

    // Client can only pay their own bills
    if (req.user.role === 'client' && req.user._id.toString() !== bill.userId.toString()) {
      return next(new AppError('Access denied.', 403));
    }

    if (Math.abs(amount - bill.totalAmount) > 0.01) {
      return next(new AppError(`Payment amount must match bill total: $${bill.totalAmount}`, 400));
    }

    const payment = await Payment.create({
      userId: bill.userId,
      billId,
      amount,
      paymentMethod: paymentMethod || 'online',
      notes,
      processedBy: req.user._id,
    });

    // Mark bill as paid
    bill.status = 'paid';
    bill.paidDate = new Date();
    await bill.save();

    logger.info('Payment recorded', { billId, userId: bill.userId, amount });

    res.status(201).json({
      success: true,
      data: payment,
      message: `Payment of $${amount} recorded successfully. Transaction ID: ${payment.transactionId}`,
    });
  } catch (err) {
    next(err);
  }
};

exports.getPaymentsByUser = async (req, res, next) => {
  try {
    const targetUserId = req.params.userId;

    if (req.user.role === 'client' && req.user._id.toString() !== targetUserId) {
      return next(new AppError('Access denied.', 403));
    }

    const { page = 1, limit = 12 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [payments, total] = await Promise.all([
      Payment.find({ userId: targetUserId })
        .populate('billId', 'billNumber month year totalAmount')
        .sort({ paymentDate: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Payment.countDocuments({ userId: targetUserId }),
    ]);

    res.json({
      success: true,
      data: payments,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getAllPayments = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [payments, total] = await Promise.all([
      Payment.find(filter)
        .populate('userId', 'name email meterNumber')
        .populate('billId', 'billNumber month year totalAmount')
        .sort({ paymentDate: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Payment.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: payments,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getPaymentById = async (req, res, next) => {
  try {
    const payment = await Payment.findById(req.params.id)
      .populate('userId', 'name email meterNumber')
      .populate('billId', 'billNumber month year totalAmount status');

    if (!payment) return next(new AppError('Payment not found.', 404));

    if (req.user.role === 'client' && req.user._id.toString() !== payment.userId._id.toString()) {
      return next(new AppError('Access denied.', 403));
    }

    res.json({ success: true, data: payment });
  } catch (err) {
    next(err);
  }
};
