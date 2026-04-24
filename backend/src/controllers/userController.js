const User = require('../models/User');
const { AppError } = require('../middlewares/errorHandler');
const logger = require('../utils/logger');

exports.getAllUsers = async (req, res, next) => {
  try {
    const { role, isActive, search, page = 1, limit = 20 } = req.query;
    const filter = {};

    if (role) filter.role = role;
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { meterNumber: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [users, total] = await Promise.all([
      User.find(filter).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      User.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: users,
      pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getUserById = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return next(new AppError('User not found.', 404));

    // Client can only view their own profile
    if (req.user.role === 'client' && req.user._id.toString() !== req.params.id) {
      return next(new AppError('Access denied.', 403));
    }

    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
};

exports.createUser = async (req, res, next) => {
  try {
    const user = await User.create(req.body);
    logger.info('User created by admin', { adminId: req.user._id, newUserId: user._id });
    res.status(201).json({ success: true, data: user.toSafeObject(), message: 'User created successfully' });
  } catch (err) {
    next(err);
  }
};

exports.updateUser = async (req, res, next) => {
  try {
    // Client can only update their own profile
    if (req.user.role === 'client' && req.user._id.toString() !== req.params.id) {
      return next(new AppError('Access denied.', 403));
    }

    // Prevent role escalation by clients
    if (req.user.role === 'client') {
      delete req.body.role;
      delete req.body.isActive;
    }

    const user = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!user) return next(new AppError('User not found.', 404));

    res.json({ success: true, data: user, message: 'User updated successfully' });
  } catch (err) {
    next(err);
  }
};

exports.getDashboardStats = async (req, res, next) => {
  try {
    const Bill = require('../models/Bill');
    const Payment = require('../models/Payment');

    const [totalClients, activeClients, totalBills, unpaidBills, totalRevenue] = await Promise.all([
      User.countDocuments({ role: 'client' }),
      User.countDocuments({ role: 'client', isActive: true }),
      Bill.countDocuments(),
      Bill.countDocuments({ status: 'unpaid' }),
      Payment.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
    ]);

    res.json({
      success: true,
      data: {
        totalClients,
        activeClients,
        totalBills,
        unpaidBills,
        totalRevenue: totalRevenue[0]?.total || 0,
      },
    });
  } catch (err) {
    next(err);
  }
};
