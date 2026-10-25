const express = require('express');
const { register } = require('../controllers/authController');
const { registerRules } = require('../validators/authValidator');
const validate = require('../middleware/validateMiddleware');

const router = express.Router();

router.post('/register', registerRules, validate, register);

module.exports = router;