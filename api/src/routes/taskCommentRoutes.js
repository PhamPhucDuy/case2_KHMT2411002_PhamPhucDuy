const express = require('express');
const controller = require('../controllers/taskCommentController');
const router = express.Router({ mergeParams: true });
router.get('/', controller.list);
router.post('/', controller.add);
router.patch('/:commentId', controller.edit);
router.delete('/:commentId', controller.remove);
module.exports = router;