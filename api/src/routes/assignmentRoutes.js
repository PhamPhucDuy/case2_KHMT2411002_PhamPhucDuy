const express = require('express');
const {
  listAssignees,
  addAssignees,
  updateAssignee,
  removeAssignee,
} = require('../controllers/assignmentController');
const {
  taskIdRules,
  assigneeUserIdRules,
  addAssigneeRules,
  updateAssigneeRules,
} = require('../validators/taskValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');
const { requireTaskPermission } = require('../middleware/permissionMiddleware');

// mergeParams để đọc được :id từ đường dẫn cha /tasks/:id/assignees
const router = express.Router({ mergeParams: true });

router.use(protect);

router.get('/', taskIdRules, validate, requireTaskPermission('view'), listAssignees);
router.post(
  '/',
  taskIdRules,
  addAssigneeRules,
  validate,
  requireTaskPermission('assign'),
  addAssignees
);
router.patch(
  '/:userId',
  taskIdRules,
  assigneeUserIdRules,
  updateAssigneeRules,
  validate,
  requireTaskPermission('assign'),
  updateAssignee
);
router.delete(
  '/:userId',
  taskIdRules,
  assigneeUserIdRules,
  validate,
  requireTaskPermission('assign'),
  removeAssignee
);

module.exports = router;