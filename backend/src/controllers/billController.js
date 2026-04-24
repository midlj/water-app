const Bill = require('../models/Bill');
const MeterReading = require('../models/MeterReading');
const User = require('../models/User');
const { AppError } = require('../middlewares/errorHandler');
const { calculateBill, getDueDate } = require('../services/billingService');
const logger = require('../utils/logger');

exports.generateBill = async (req, res, next) => {
  try {
    const { userId, month, year, dueDays } = req.body;

    const user = await User.findById(userId);
    if (!user) return next(new AppError('User not found.', 404));

    // Check meter reading exists for this period
    const meterReading = await MeterReading.findOne({ userId, month, year });
    if (!meterReading) {
      return next(new AppError(`No meter reading found for ${month}/${year}. Add reading first.`, 404));
    }

    // Prevent duplicate bills
    const existing = await Bill.findOne({ userId, month, year });
    if (existing) {
      return next(new AppError(`Bill already generated for ${month}/${year}.`, 409));
    }

    const { tariffBreakdown, waterCharges, serviceCharge, taxAmount, totalAmount } =
      calculateBill(meterReading.unitsConsumed);

    const bill = await Bill.create({
      userId,
      meterReadingId: meterReading._id,
      month,
      year,
      previousReading: meterReading.previousReading,
      currentReading: meterReading.reading,
      unitsConsumed: meterReading.unitsConsumed,
      tariffBreakdown,
      waterCharges,
      serviceCharge,
      taxAmount,
      totalAmount,
      dueDate: getDueDate(dueDays || 30),
      generatedBy: req.user._id,
    });

    logger.info('Bill generated', { userId, month, year, billId: bill._id, amount: totalAmount });

    res.status(201).json({
      success: true,
      data: bill,
      message: `Bill generated. Amount due: $${totalAmount}`,
    });
  } catch (err) {
    next(err);
  }
};

exports.getBillsByUser = async (req, res, next) => {
  try {
    const targetUserId = req.params.userId;

    if (req.user.role === 'client' && req.user._id.toString() !== targetUserId) {
      return next(new AppError('Access denied.', 403));
    }

    const { status, year, page = 1, limit = 12 } = req.query;
    const filter = { userId: targetUserId };
    if (status) filter.status = status;
    if (year) filter.year = parseInt(year);

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [bills, total] = await Promise.all([
      Bill.find(filter)
        .populate('userId', 'name email meterNumber')
        .sort({ year: -1, month: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Bill.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: bills,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getAllBills = async (req, res, next) => {
  try {
    const { status, month, year, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (month) filter.month = parseInt(month);
    if (year) filter.year = parseInt(year);

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [bills, total] = await Promise.all([
      Bill.find(filter)
        .populate('userId', 'name email meterNumber address')
        .populate('generatedBy', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Bill.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: bills,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getBillById = async (req, res, next) => {
  try {
    const bill = await Bill.findById(req.params.id)
      .populate('userId', 'name email phone address meterNumber')
      .populate('generatedBy', 'name');

    if (!bill) return next(new AppError('Bill not found.', 404));

    if (req.user.role === 'client' && req.user._id.toString() !== bill.userId._id.toString()) {
      return next(new AppError('Access denied.', 403));
    }

    res.json({ success: true, data: bill });
  } catch (err) {
    next(err);
  }
};

exports.updateBillStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const bill = await Bill.findByIdAndUpdate(req.params.id, { status }, { new: true, runValidators: true });
    if (!bill) return next(new AppError('Bill not found.', 404));
    res.json({ success: true, data: bill, message: 'Bill status updated' });
  } catch (err) {
    next(err);
  }
};
