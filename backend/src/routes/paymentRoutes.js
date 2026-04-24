const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect, restrictTo } = require('../middlewares/auth');

router.use(protect);

router.post('/', paymentController.makePayment);
router.get('/', restrictTo('admin'), paymentController.getAllPayments);
router.get('/user/:userId', paymentController.getPaymentsByUser);
router.get('/:id', paymentController.getPaymentById);

module.exports = router;
