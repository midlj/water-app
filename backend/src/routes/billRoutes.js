const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');
const { protect, restrictTo } = require('../middlewares/auth');
const { generateBillSchema, validate } = require('../validations/billValidation');

router.use(protect);

router.post('/generate', restrictTo('admin'), validate(generateBillSchema), billController.generateBill);
router.get('/', restrictTo('admin'), billController.getAllBills);
router.get('/user/:userId', billController.getBillsByUser);
router.get('/:id', billController.getBillById);
router.patch('/:id/status', restrictTo('admin'), billController.updateBillStatus);

module.exports = router;
