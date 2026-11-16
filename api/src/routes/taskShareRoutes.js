const express = require('express');
const {
  listShares,
  addShares,
  updateShare,
  removeShare,
} = require('../controllers/taskShareController');
const { taskIdRules } = require('../validators/taskValidator');
const {
  shareIdRules,
  addShareRules,
  updateShareRules,
} = require('../validators/shareValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');
const { requireTaskPermission } = require('../middleware/permissionMiddleware');

// mergeParams để đọc được :id từ đường dẫn cha /tasks/:id/shares
const router = express.Router({ mergeParams: true });

router.use(protect);

router.get('/', taskIdRules, validate, requireTaskPermission('view'), listShares);
router.post(
  '/',
  taskIdRules,
  addShareRules,
  validate,
  requireTaskPermission('manageAccess'),
  addShares
);
router.patch(
  '/:shareId',
  taskIdRules,
  shareIdRules,
  updateShareRules,
  validate,
  requireTaskPermission('manageAccess'),
  updateShare
);
router.delete(
  '/:shareId',
  taskIdRules,
  shareIdRules,
  validate,
  requireTaskPermission('manageAccess'),
  removeShare
);

module.exports = router;