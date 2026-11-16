const express = require('express');
const {
  taskStats,
  assignmentStats,
  deadlineStats,
} = require('../controllers/statisticsController');
const { deadlineRules } = require('../validators/statisticsValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.get('/tasks', taskStats);
router.get('/assignments', assignmentStats);
router.get('/deadlines', deadlineRules, validate, deadlineStats);

module.exports = router;
