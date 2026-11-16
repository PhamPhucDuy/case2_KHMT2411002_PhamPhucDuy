const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const DAY_MS = 24 * 60 * 60 * 1000;

const getSharedIds = async (userId) => {
  const shares = await TaskShare.find({ userId }).select('taskId').lean();
  return shares.map((s) => s.taskId);
};

// Công việc người dùng có quyền thấy: tự tạo, được giao hoặc được chia sẻ
const accessOf = (userId, sharedIds) => ({
  $or: [{ createdBy: userId }, { assigneeIds: userId }, { _id: { $in: sharedIds } }],
});

// Đếm công việc theo trạng thái cho một điều kiện lọc
const countByStatus = async (filter) => {
  const rows = await Task.aggregate([
    { $match: filter },
    { $group: { _id: '$status', count: { $sum: 1 } } },
  ]);
  const byStatus = { todo: 0, in_progress: 0, completed: 0 };
  for (const r of rows) {
    if (r._id in byStatus) byStatus[r._id] = r.count;
  }
  const total = byStatus.todo + byStatus.in_progress + byStatus.completed;
  return { total, active: total - byStatus.completed, byStatus };
};

// GET /api/statistics/tasks
const taskStats = async (req, res, next) => {
  try {
    const me = req.user._id;
    const sharedIds = await getSharedIds(me);
    const stats = await countByStatus(accessOf(me, sharedIds));

    const [created, assigned, shared] = await Promise.all([
      Task.countDocuments({ createdBy: me }),
      Task.countDocuments({ assigneeIds: me }),
      Task.countDocuments({ _id: { $in: sharedIds } }),
    ]);

    return res.json({
      total: stats.total,
      active: stats.active,
      byStatus: stats.byStatus,
      byRole: { created, assigned, shared },
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/statistics/assignments
const assignmentStats = async (req, res, next) => {
  try {
    const me = req.user._id;

    const [assignedToMe, primaryAssignee, assignedByMe] = await Promise.all([
      countByStatus({ assigneeIds: me }),
      countByStatus({ primaryAssigneeId: me }),
      // Việc mình tạo và đã giao cho người khác
      countByStatus({ createdBy: me, assigneeIds: { $elemMatch: { $ne: me } } }),
    ]);

    return res.json({ assignedToMe, primaryAssignee, assignedByMe });
  } catch (err) {
    next(err);
  }
};

// GET /api/statistics/deadlines?days=3&limit=20
const deadlineStats = async (req, res, next) => {
  try {
    const me = req.user._id;
    const days = req.query.days || 3;
    const limit = req.query.limit || 20;
    const now = new Date();
    const until = new Date(now.getTime() + days * DAY_MS);

    const sharedIds = await getSharedIds(me);
    const access = accessOf(me, sharedIds);
    const open = { status: { $ne: 'completed' } };

    const overdueFilter = { $and: [access, open, { dueDate: { $lt: now } }] };
    const soonFilter = { $and: [access, open, { dueDate: { $gte: now, $lte: until } }] };
    const fields = 'title dueDate priority status';

    const [overdueCount, overdueTasks, soonCount, soonTasks] = await Promise.all([
      Task.countDocuments(overdueFilter),
      Task.find(overdueFilter).select(fields).sort({ dueDate: 1 }).limit(limit).lean(),
      Task.countDocuments(soonFilter),
      Task.find(soonFilter).select(fields).sort({ dueDate: 1 }).limit(limit).lean(),
    ]);

    return res.json({
      days,
      overdue: { count: overdueCount, tasks: overdueTasks },
      dueSoon: { count: soonCount, tasks: soonTasks },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { taskStats, assignmentStats, deadlineStats };
