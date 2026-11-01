const express = require('express');
const { createTask, listTasks } = require('../controllers/taskController');
const { createTaskRules, listTaskRules } = require('../validators/taskValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Mọi API công việc đều yêu cầu đăng nhập
router.use(protect);

router.get('/', listTaskRules, validate, listTasks);
router.post('/', createTaskRules, validate, createTask);

module.exports = router;