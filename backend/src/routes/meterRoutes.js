const express = require('express');
const router = express.Router();
const meterController = require('../controllers/meterController');
const { protect, restrictTo } = require('../middlewares/auth');
const { addReadingSchema, validate } = require('../validations/meterValidation');

router.use(protect);

router.post('/', restrictTo('admin'), validate(addReadingSchema), meterController.addReading);
router.get('/', restrictTo('admin'), meterController.getAllReadings);
router.get('/:userId', meterController.getReadings);

module.exports = router;
