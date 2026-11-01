const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };
const DEFAULT_ORDER = { dueDate: 'asc', priority: 'desc', createdAt: 'desc' };

// Chống người dùng nhập ký tự đặc biệt của regex vào ô tìm kiếm
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const createTask = async (req, res, next) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;

    const task = await Task.create({
      title,
      description,
      startDate,
      dueDate,
      priority,
      status,
      createdBy: req.user._id, // lấy từ token, không nhận từ client
    });

    return res.status(201).json({ message: 'Tạo công việc thành công', task });
  } catch (err) {
    next(err);
  }
};

const listTasks = async (req, res, next) => {
  try {
    const me = req.user._id;
    const { scope, status, priority, q, assigneeId } = req.query;
    const sortBy = req.query.sortBy || 'createdAt';
    const dir = (req.query.order || DEFAULT_ORDER[sortBy]) === 'asc' ? 1 : -1;

    // Các công việc đã được chia sẻ cho mình
    const shares = await TaskShare.find({ userId: me })
      .select('taskId permission')
      .lean();
    const shareMap = new Map(shares.map((s) => [String(s.taskId), s.permission]));
    const sharedIds = shares.map((s) => s.taskId);

    // Phạm vi truy cập: chỉ trả công việc mà người gọi có quyền thấy
    let access;
    if (scope === 'created') access = { createdBy: me };
    else if (scope === 'assigned') access = { assigneeIds: me };
    else if (scope === 'shared') access = { _id: { $in: sharedIds } };
    else {
      access = {
        $or: [{ createdBy: me }, { assigneeIds: me }, { _id: { $in: sharedIds } }],
      };
    }

    const conditions = [access];
    if (status) conditions.push({ status });
    if (priority) conditions.push({ priority });
    if (assigneeId) conditions.push({ assigneeIds: assigneeId });
    if (q) conditions.push({ title: { $regex: escapeRegex(q), $options: 'i' } });

    const tasks = await Task.find({ $and: conditions })
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
      .populate('primaryAssigneeId', 'fullName email')
      .lean();

    // Sắp xếp; công việc không có hạn luôn xếp cuối
    const keyOf = (t) => {
      if (sortBy === 'priority') return PRIORITY_RANK[t.priority];
      if (sortBy === 'dueDate') return t.dueDate ? new Date(t.dueDate).getTime() : null;
      return new Date(t.createdAt).getTime();
    };
    tasks.sort((a, b) => {
      const ka = keyOf(a);
      const kb = keyOf(b);
      if (ka === null && kb === null) return 0;
      if (ka === null) return 1;
      if (kb === null) return -1;
      return (ka - kb) * dir;
    });

    // Gắn vai trò của người gọi trên từng công việc
    const myId = String(me);
    const result = tasks.map((t) => ({
      ...t,
      myAccess: {
        isCreator: String(t.createdBy?._id) === myId,
        isAssignee: (t.assigneeIds || []).some((u) => String(u._id) === myId),
        sharePermission: shareMap.get(String(t._id)) || null,
      },
    }));

    return res.json({ count: result.length, tasks: result });
  } catch (err) {
    next(err);
  }
};

module.exports = { createTask, listTasks };