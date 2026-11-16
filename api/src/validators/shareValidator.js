const { body, param } = require('express-validator');

const PERMISSIONS = ['viewer', 'editor'];

const shareIdRules = [
  param('shareId').isMongoId().withMessage('Mã chia sẻ không hợp lệ'),
];

const addShareRules = [
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

  body('permission')
    .optional()
    .isIn(PERMISSIONS)
    .withMessage('permission phải là viewer hoặc editor'),

  body().custom((_, { req }) => {
    const { userIds, emails } = req.body;
    const total =
      (Array.isArray(userIds) ? userIds.length : 0) +
      (Array.isArray(emails) ? emails.length : 0);
    if (total === 0) {
      throw new Error('Cần ít nhất một người để chia sẻ (userIds hoặc emails)');
    }
    return true;
  }),
];

const updateShareRules = [
  body('permission')
    .isIn(PERMISSIONS)
    .withMessage('permission phải là viewer hoặc editor'),
];

module.exports = { shareIdRules, addShareRules, updateShareRules };