const { getTaskAccess, can } = require('../services/taskService');

// Kiểm tra quyền trên công việc :id; gắn req.task và req.taskRole
const requireTaskPermission = (action) => async (req, res, next) => {
  try {
    const { task, role } = await getTaskAccess(req.params.id, req.user._id);

    // Không có quyền xem thì coi như không tồn tại
    if (!task || !can(role, 'view')) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    if (!can(role, action)) {
      return res
        .status(403)
        .json({ message: 'Bạn không có quyền thực hiện thao tác này' });
    }

    req.task = task;
    req.taskRole = role;
    next();
  } catch (err) {
    next(err);
  }
};

module.exports = { requireTaskPermission };