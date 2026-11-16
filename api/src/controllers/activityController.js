const TaskActivity = require('../models/TaskActivity');
const { getTaskAccess, can } = require('../services/taskService');

// GET /api/tasks/:id/activities?limit=50
const listActivities = async (req, res, next) => {
  try {
    const { task, role } = await getTaskAccess(req.params.id, req.user._id);

    // Không có quyền xem thì coi như công việc không tồn tại
    if (!task || !can(role, 'view')) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const limit = req.query.limit || 50;
    const activities = await TaskActivity.find({ taskId: task._id })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('userId', 'fullName email')
      .lean();

    return res.json({ count: activities.length, activities });
  } catch (err) {
    next(err);
  }
};

module.exports = { listActivities };
