const express = require('express');
const { searchUsers, getUser } = require('../controllers/userController');
const { searchUserRules, userIdRules } = require('../validators/userValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

// /search phải đứng trước /:id
router.get('/search', searchUserRules, validate, searchUsers);
router.get('/:id', userIdRules, validate, getUser);

module.exports = router;