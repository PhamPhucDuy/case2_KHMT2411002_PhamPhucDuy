const { query, param } = require('express-validator');

const listNotificationRules = [
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('limit phải từ 1 đến 100')
    .toInt(),
  query('unreadOnly')
    .optional()
    .isBoolean()
    .withMessage('unreadOnly phải là true hoặc false')
    .toBoolean(),
];

const notificationIdRules = [
  param('id').isMongoId().withMessage('Mã thông báo không hợp lệ'),
];

module.exports = { listNotificationRules, notificationIdRules };