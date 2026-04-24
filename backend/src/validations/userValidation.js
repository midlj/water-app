const Joi = require('joi');

const createUserSchema = Joi.object({
  name: Joi.string().max(100).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  phone: Joi.string().optional().allow(''),
  address: Joi.string().optional().allow(''),
  meterNumber: Joi.string().optional().allow(''),
  role: Joi.string().valid('client', 'admin').default('client'),
});

const updateUserSchema = Joi.object({
  name: Joi.string().max(100).optional(),
  phone: Joi.string().optional().allow(''),
  address: Joi.string().optional().allow(''),
  meterNumber: Joi.string().optional().allow(''),
  isActive: Joi.boolean().optional(),
});

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) {
    const messages = error.details.map((d) => d.message).join(', ');
    return res.status(400).json({ success: false, message: messages });
  }
  next();
};

module.exports = { createUserSchema, updateUserSchema, validate };
