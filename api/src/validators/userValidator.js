const { query, param } = require('express-validator');

const searchUserRules = [
  query('q')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Từ khóa tìm kiếm từ 2 đến 100 ký tự'),
];

const userIdRules = [
  param('id').isMongoId().withMessage('Mã người dùng không hợp lệ'),
];

module.exports = { searchUserRules, userIdRules };