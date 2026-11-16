const { param } = require('express-validator');

const emailLogIdRules = [
  param('id').isMongoId().withMessage('Mã lịch sử email không hợp lệ'),
];

module.exports = { emailLogIdRules };