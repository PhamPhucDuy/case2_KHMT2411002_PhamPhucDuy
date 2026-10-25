const { body } = require('express-validator');

const registerRules = [
  body('fullName')
    .trim()
    .notEmpty().withMessage('Họ tên không được để trống')
    .isLength({ max: 100 }).withMessage('Họ tên tối đa 100 ký tự'),

  body('email')
    .trim()
    .notEmpty().withMessage('Email không được để trống').bail()
    .isEmail().withMessage('Email không hợp lệ')
    .toLowerCase(),

  body('password')
    .isLength({ min: 6 }).withMessage('Mật khẩu tối thiểu 6 ký tự'),
];

const loginRules = [
  body('email')
    .trim()
    .notEmpty().withMessage('Email không được để trống').bail()
    .isEmail().withMessage('Email không hợp lệ')
    .toLowerCase(),

  body('password')
    .notEmpty().withMessage('Mật khẩu không được để trống'),
];
const updateProfileRules = [
  body('fullName')
    .optional()
    .trim()
    .notEmpty().withMessage('Họ tên không được để trống')
    .isLength({ max: 100 }).withMessage('Họ tên tối đa 100 ký tự'),

  body('avatarUrl')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Đường dẫn ảnh tối đa 500 ký tự'),
];
module.exports = { registerRules, loginRules, updateProfileRules };