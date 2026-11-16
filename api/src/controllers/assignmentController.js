const User = require('../models/User');

const USER_FIELDS = 'fullName email avatarUrl';
const sameId = (a, b) => String(a) === String(b);

const listAssignees = async (req, res, next) => {
  try {
    const task = req.task;
    await task.populate({ path: 'assigneeIds', select: USER_FIELDS });

    return res.json({
      count: task.assigneeIds.length,
      primaryAssigneeId: task.primaryAssigneeId,
      assignees: task.assigneeIds,
    });
  } catch (err) {
    next(err);
  }
};

const addAssignees = async (req, res, next) => {
  try {
    const task = req.task;
    const { userIds = [], emails = [], primaryAssigneeId } = req.body;

    const users = await User.find({
      $or: [{ _id: { $in: userIds } }, { email: { $in: emails } }],
    }).select(USER_FIELDS);

    const foundIds = new Set(users.map((u) => String(u._id)));
    const foundEmails = new Set(users.map((u) => u.email));
    const notFound = [
      ...userIds.filter((id) => !foundIds.has(String(id))),
      ...emails.filter((e) => !foundEmails.has(e)),
    ];

    const existing = new Set(task.assigneeIds.map(String));
    const added = [];
    const alreadyAssigned = [];
    for (const u of users) {
      if (existing.has(String(u._id))) {
        alreadyAssigned.push(u);
      } else {
        task.assigneeIds.push(u._id);
        existing.add(String(u._id));
        added.push(u);
      }
    }

    let primaryChanged = false;
    if (primaryAssigneeId) {
      if (!existing.has(String(primaryAssigneeId))) {
        return res.status(400).json({
          message: 'Người phụ trách chính phải nằm trong danh sách được giao',
        });
      }
      primaryChanged = !sameId(task.primaryAssigneeId, primaryAssigneeId);
      task.primaryAssigneeId = primaryAssigneeId;
    }

    if (added.length > 0 || primaryChanged) await task.save();

    return res.json({
      message:
        added.length > 0 ? 'Giao việc thành công' : 'Không có người nào mới được giao',
      added,
      alreadyAssigned,
      notFound,
      primaryAssigneeId: task.primaryAssigneeId,
    });
  } catch (err) {
    next(err);
  }
};

const updateAssignee = async (req, res, next) => {
  try {
    const task = req.task;
    const { userId } = req.params;

    if (!task.assigneeIds.some((id) => sameId(id, userId))) {
      return res.status(404).json({ message: 'Người này chưa được giao việc' });
    }

    if (req.body.isPrimary) {
      task.primaryAssigneeId = userId;
    } else if (task.primaryAssigneeId && sameId(task.primaryAssigneeId, userId)) {
      task.primaryAssigneeId = null;
    }
    await task.save();

    return res.json({
      message: 'Cập nhật người phụ trách chính thành công',
      primaryAssigneeId: task.primaryAssigneeId,
    });
  } catch (err) {
    next(err);
  }
};

const removeAssignee = async (req, res, next) => {
  try {
    const task = req.task;
    const { userId } = req.params;

    if (!task.assigneeIds.some((id) => sameId(id, userId))) {
      return res.status(404).json({ message: 'Người này chưa được giao việc' });
    }

    task.assigneeIds = task.assigneeIds.filter((id) => !sameId(id, userId));
    if (task.primaryAssigneeId && sameId(task.primaryAssigneeId, userId)) {
      task.primaryAssigneeId = null;
    }
    await task.save();

    return res.json({ message: 'Đã hủy giao việc' });
  } catch (err) {
    next(err);
  }
};

module.exports = { listAssignees, addAssignees, updateAssignee, removeAssignee };