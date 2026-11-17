const express = require('express');
const controller = require('../controllers/taskChecklistController');

// Mounted beneath the existing router.use(protect) in taskRoutes.js.
const router = express.Router({ mergeParams: true });
router.get('/', controller.list);
router.post('/', controller.add);
router.patch('/:itemId', controller.setDone);
router.delete('/:itemId', controller.remove);
module.exports = router;