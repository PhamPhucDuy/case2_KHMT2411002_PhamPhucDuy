const express = require('express');
const {
  listTaskEmailLogs,
  retryEmailLog,
} = require('../controllers/emailLogController');
const { taskIdRules } = require('../validators/taskValidator');
const { emailLogIdRules } = require('../validators/emailLogValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');
const { requireTaskPermission } = require('../middleware/permissionMiddleware');

// GET /api/tasks/:id/email-logs  (chỉ người tạo công việc xem được)
const taskEmailLogRouter = express.Router({ mergeParams: true });
taskEmailLogRouter.use(protect);
taskEmailLogRouter.get(
  '/',
  taskIdRules,
  validate,
  requireTaskPermission('manageAccess'),
  listTaskEmailLogs
);

// POST /api/email-logs/:id/retry
const emailLogRouter = express.Router();
emailLogRouter.use(protect);
emailLogRouter.post('/:id/retry', emailLogIdRules, validate, retryEmailLog);

module.exports = { taskEmailLogRouter, emailLogRouter };