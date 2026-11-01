const express = require('express');
const { createTask } = require('../controllers/taskController');
const { createTaskRules } = require('../validators/taskValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Mọi API công việc đều yêu cầu đăng nhập
router.use(protect);

router.post('/', createTaskRules, validate, createTask);

module.exports = router;