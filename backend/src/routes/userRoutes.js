const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { protect, restrictTo } = require('../middlewares/auth');
const { createUserSchema, updateUserSchema, validate } = require('../validations/userValidation');

router.use(protect);

router.get('/dashboard/stats', restrictTo('admin'), userController.getDashboardStats);
router.get('/', restrictTo('admin'), userController.getAllUsers);
router.post('/', restrictTo('admin'), validate(createUserSchema), userController.createUser);
router.get('/:id', userController.getUserById);
router.put('/:id', validate(updateUserSchema), userController.updateUser);

module.exports = router;
