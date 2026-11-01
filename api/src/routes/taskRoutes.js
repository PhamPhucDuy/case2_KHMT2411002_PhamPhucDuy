const express = require('express');
const {
  createTask,
  listTasks,
  getTask,
  updateTask,
} = require('../controllers/taskController');
const {
  createTaskRules,
  listTaskRules,
  taskIdRules,
  updateTaskRules,
} = require('../validators/taskValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Mọi API công việc đều yêu cầu đăng nhập
router.use(protect);

router.get('/', listTaskRules, validate, listTasks);
router.post('/', createTaskRules, validate, createTask);
router.get('/:id', taskIdRules, validate, getTask);
router.put('/:id', taskIdRules, updateTaskRules, validate, updateTask);

module.exports = router;