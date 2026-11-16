const { query } = require('express-validator');

const deadlineRules = [
  query('days')
    .optional()
    .isInt({ min: 1, max: 30 })
    .withMessage('days phải từ 1 đến 30')
    .toInt(),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('limit phải từ 1 đến 100')
    .toInt(),
];

module.exports = { deadlineRules };
