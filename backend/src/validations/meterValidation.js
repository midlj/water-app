const Joi = require('joi');

const addReadingSchema = Joi.object({
  userId: Joi.string().hex().length(24).required().messages({
    'any.required': 'User ID is required',
  }),
  reading: Joi.number().min(0).required().messages({
    'number.min': 'Reading cannot be negative',
    'any.required': 'Meter reading value is required',
  }),
  readingDate: Joi.date().max('now').optional(),
  month: Joi.number().min(1).max(12).required(),
  year: Joi.number().min(2000).max(2100).required(),
  notes: Joi.string().max(500).optional().allow(''),
});

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) {
    const messages = error.details.map((d) => d.message).join(', ');
    return res.status(400).json({ success: false, message: messages });
  }
  next();
};

module.exports = { addReadingSchema, validate };
