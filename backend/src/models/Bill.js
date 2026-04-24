const mongoose = require('mongoose');

const billSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    meterReadingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MeterReading',
      required: true,
    },
    billNumber: {
      type: String,
      unique: true,
      required: true,
    },
    month: {
      type: Number,
      required: true,
      min: 1,
      max: 12,
    },
    year: {
      type: Number,
      required: true,
    },
    previousReading: {
      type: Number,
      required: true,
    },
    currentReading: {
      type: Number,
      required: true,
    },
    unitsConsumed: {
      type: Number,
      required: true,
    },
    // Tariff breakdown
    tariffBreakdown: [
      {
        tier: String,
        units: Number,
        rate: Number,
        amount: Number,
      },
    ],
    waterCharges: {
      type: Number,
      required: true,
    },
    serviceCharge: {
      type: Number,
      default: 5,
    },
    taxAmount: {
      type: Number,
      default: 0,
    },
    totalAmount: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      enum: ['unpaid', 'paid', 'overdue', 'cancelled'],
      default: 'unpaid',
    },
    dueDate: {
      type: Date,
      required: true,
    },
    paidDate: {
      type: Date,
    },
    generatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
  }
);

billSchema.index({ userId: 1, month: 1, year: 1 }, { unique: true });

// Auto-generate bill number before save
billSchema.pre('validate', async function (next) {
  if (!this.billNumber) {
    const count = await mongoose.model('Bill').countDocuments();
    const pad = String(count + 1).padStart(6, '0');
    this.billNumber = `WB-${this.year}${String(this.month).padStart(2, '0')}-${pad}`;
  }
  next();
});

module.exports = mongoose.model('Bill', billSchema);
