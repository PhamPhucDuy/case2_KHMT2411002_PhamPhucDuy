const express = require('express');
const {
  register,
  login,
  getMe,
  updateMe,
} = require('../controllers/authController');
const {
  registerRules,
  loginRules,
  updateProfileRules,
} = require('../validators/authValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/register', registerRules, validate, register);
router.post('/login', loginRules, validate, login);
router.get('/me', protect, getMe);
router.put('/me', protect, updateProfileRules, validate, updateMe);

module.exports = router;