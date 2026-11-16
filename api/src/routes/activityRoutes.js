const express = require('express');
const { query } = require('express-validator');
const { listActivities } = require('../controllers/activityController');
const { taskIdRules } = require('../validators/taskValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const activityLimitRules = [
  query('limit')
    .optional()
    .isInt({ min: 1, max: 200 })
    .withMessage('limit phải từ 1 đến 200')
    .toInt(),
];

// GET /api/tasks/:id/activities
const router = express.Router({ mergeParams: true });
router.use(protect);
router.get('/', taskIdRules, activityLimitRules, validate, listActivities);

module.exports = router;
