const Joi = require('joi');

const generateBillSchema = Joi.object({
  userId: Joi.string().hex().length(24).required(),
  month: Joi.number().min(1).max(12).required(),
  year: Joi.number().min(2000).max(2100).required(),
  dueDays: Joi.number().min(1).max(90).default(30),
});

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) {
    const messages = error.details.map((d) => d.message).join(', ');
    return res.status(400).json({ success: false, message: messages });
  }
  next();
};

module.exports = { generateBillSchema, validate };
