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
module.exports = {
  createTaskRules,
  listTaskRules,
  taskIdRules,
  updateTaskRules,
};