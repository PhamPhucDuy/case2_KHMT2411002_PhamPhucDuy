const { body, query, param } = require('express-validator');

const createTaskRules = [
  body('title')
    .trim()
    .notEmpty().withMessage('Tên công việc không được để trống')
    .isLength({ max: 200 }).withMessage('Tên công việc tối đa 200 ký tự'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 2000 }).withMessage('Mô tả tối đa 2000 ký tự'),

  body('startDate')
    .optional({ values: 'falsy' })
    .isISO8601().withMessage('Ngày bắt đầu không hợp lệ')
    .toDate(),

  body('dueDate')
    .optional({ values: 'falsy' })
    .isISO8601().withMessage('Hạn hoàn thành không hợp lệ')
    .toDate()
    .custom((value, { req }) => {
      if (req.body.startDate && value < req.body.startDate) {
        throw new Error('Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu');
      }
      return true;
    }),

  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high'])
    .withMessage('Mức độ ưu tiên phải là low, medium hoặc high'),

  body('status')
    .optional()
    .isIn(['todo', 'in_progress', 'completed'])
    .withMessage('Trạng thái phải là todo, in_progress hoặc completed'),
];

const listTaskRules = [
  query('scope')
    .optional()
    .isIn(['created', 'assigned', 'shared'])
    .withMessage('scope phải là created, assigned hoặc shared'),

  query('status')
    .optional()
    .isIn(['todo', 'in_progress', 'completed'])
    .withMessage('status không hợp lệ'),

  query('priority')
    .optional()
    .isIn(['low', 'medium', 'high'])
    .withMessage('priority không hợp lệ'),

  query('q')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Từ khóa tối đa 100 ký tự'),

  query('assigneeId')
    .optional()
    .isMongoId()
    .withMessage('assigneeId không hợp lệ'),

  query('sortBy')
    .optional()
    .isIn(['dueDate', 'priority', 'createdAt'])
    .withMessage('sortBy phải là dueDate, priority hoặc createdAt'),

  query('order')
    .optional()
    .isIn(['asc', 'desc'])
    .withMessage('order phải là asc hoặc desc'),
];

const taskIdRules = [
  param('id').isMongoId().withMessage('Mã công việc không hợp lệ'),
];

const updateTaskRules = [
  body('title')
    .optional()
    .trim()
    .notEmpty().withMessage('Tên công việc không được để trống')
    .isLength({ max: 200 }).withMessage('Tên công việc tối đa 200 ký tự'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 2000 }).withMessage('Mô tả tối đa 2000 ký tự'),

  body('startDate')
    .optional({ values: 'falsy' })
    .isISO8601().withMessage('Ngày bắt đầu không hợp lệ')
    .toDate(),

  body('dueDate')
    .optional({ values: 'falsy' })
    .isISO8601().withMessage('Hạn hoàn thành không hợp lệ')
    .toDate(),

  body('priority')
    .optional()
    .isIn(['low', 'medium', 'high'])
    .withMessage('Mức độ ưu tiên phải là low, medium hoặc high'),
];

const updateStatusRules = [
  body('status')
    .isIn(['todo', 'in_progress', 'completed'])
    .withMessage('Trạng thái phải là todo, in_progress hoặc completed'),
];

const assigneeUserIdRules = [
  param('userId').isMongoId().withMessage('Mã người dùng không hợp lệ'),
];

const addAssigneeRules = [
  body('userIds')
    .optional()
    .isArray({ max: 20 })
    .withMessage('userIds phải là mảng tối đa 20 phần tử'),
  body('userIds.*').isMongoId().withMessage('userId không hợp lệ'),

  body('emails')
    .optional()
    .isArray({ max: 20 })
    .withMessage('emails phải là mảng tối đa 20 phần tử'),
  body('emails.*').trim().toLowerCase().isEmail().withMessage('Email không hợp lệ'),

  body('primaryAssigneeId')
    .optional({ values: 'falsy' })
    .isMongoId()
    .withMessage('primaryAssigneeId không hợp lệ'),

  body().custom((_, { req }) => {
    const { userIds, emails } = req.body;
    const total =
      (Array.isArray(userIds) ? userIds.length : 0) +
      (Array.isArray(emails) ? emails.length : 0);
    if (total === 0) {
      throw new Error('Cần ít nhất một người để giao việc (userIds hoặc emails)');
    }
    return true;
  }),
];

const updateAssigneeRules = [
  body('isPrimary')
    .isBoolean()
    .withMessage('isPrimary phải là true hoặc false')
    .toBoolean(),
];

module.exports = {
  createTaskRules,
  listTaskRules,
  taskIdRules,
  updateTaskRules,
  updateStatusRules,
  assigneeUserIdRules,
  addAssigneeRules,
  updateAssigneeRules,
};