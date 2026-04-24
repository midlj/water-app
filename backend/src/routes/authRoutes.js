const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middlewares/auth');
const { loginSchema, validate } = require('../validations/authValidation');

router.post('/login', validate(loginSchema), authController.login);
router.post('/register', protect, authController.register);
router.get('/me', protect, authController.getMe);

module.exports = router;
