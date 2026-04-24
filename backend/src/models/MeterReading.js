const mongoose = require('mongoose');

const meterReadingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    reading: {
      type: Number,
      required: [true, 'Meter reading is required'],
      min: [0, 'Meter reading cannot be negative'],
    },
    previousReading: {
      type: Number,
      default: 0,
      min: [0, 'Previous reading cannot be negative'],
    },
    unitsConsumed: {
      type: Number,
      default: 0,
    },
    readingDate: {
      type: Date,
      required: [true, 'Reading date is required'],
      default: Date.now,
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
    recordedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

// Prevent duplicate readings for same user/month/year
meterReadingSchema.index({ userId: 1, month: 1, year: 1 }, { unique: true });

meterReadingSchema.pre('save', function (next) {
  if (this.reading >= this.previousReading) {
    this.unitsConsumed = this.reading - this.previousReading;
  } else {
    // Meter reset scenario
    this.unitsConsumed = this.reading;
  }
  next();
});

module.exports = mongoose.model('MeterReading', meterReadingSchema);
