const MeterReading = require('../models/MeterReading');
const User = require('../models/User');
const { AppError } = require('../middlewares/errorHandler');
const logger = require('../utils/logger');

exports.addReading = async (req, res, next) => {
  try {
    const { userId, reading, readingDate, month, year, notes } = req.body;

    const user = await User.findById(userId);
    if (!user) return next(new AppError('User not found.', 404));

    // Get previous month's reading for this user
    let prevMonth = month - 1;
    let prevYear = year;
    if (prevMonth === 0) { prevMonth = 12; prevYear -= 1; }

    const previousRecord = await MeterReading.findOne({ userId, month: prevMonth, year: prevYear });
    const previousReading = previousRecord ? previousRecord.reading : 0;

    if (reading < previousReading) {
      return next(new AppError(`Current reading (${reading}) cannot be less than previous reading (${previousReading}) unless meter was reset.`, 400));
    }

    const meterReading = await MeterReading.create({
      userId,
      reading,
      previousReading,
      readingDate: readingDate || new Date(),
      month,
      year,
      notes,
      recordedBy: req.user._id,
    });

    logger.info('Meter reading added', { userId, month, year, reading });

    res.status(201).json({
      success: true,
      data: meterReading,
      message: `Reading recorded. Units consumed: ${meterReading.unitsConsumed}`,
    });
  } catch (err) {
    next(err);
  }
};

exports.getReadings = async (req, res, next) => {
  try {
    const targetUserId = req.params.userId;

    // Client can only view their own readings
    if (req.user.role === 'client' && req.user._id.toString() !== targetUserId) {
      return next(new AppError('Access denied.', 403));
    }

    const { year, page = 1, limit = 12 } = req.query;
    const filter = { userId: targetUserId };
    if (year) filter.year = parseInt(year);

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [readings, total] = await Promise.all([
      MeterReading.find(filter)
        .populate('recordedBy', 'name email')
        .sort({ year: -1, month: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      MeterReading.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: readings,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getAllReadings = async (req, res, next) => {
  try {
    const { month, year, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (month) filter.month = parseInt(month);
    if (year) filter.year = parseInt(year);

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [readings, total] = await Promise.all([
      MeterReading.find(filter)
        .populate('userId', 'name email meterNumber')
        .populate('recordedBy', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      MeterReading.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: readings,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};
