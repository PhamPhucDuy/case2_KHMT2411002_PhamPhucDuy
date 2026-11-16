const User = require('../models/User');
const TaskShare = require('../models/TaskShare');
const { onTaskShared } = require('../services/taskEventService');

const USER_FIELDS = 'fullName email avatarUrl';

const listShares = async (req, res, next) => {
  try {
    const shares = await TaskShare.find({ taskId: req.task._id })
      .populate('userId', USER_FIELDS)
      .populate('sharedBy', 'fullName email')
      .sort({ createdAt: 1 })
      .lean();

    return res.json({ count: shares.length, shares });
  } catch (err) {
    next(err);
  }
};

const addShares = async (req, res, next) => {
  try {
    const task = req.task;
    const { userIds = [], emails = [], permission = 'viewer' } = req.body;

    const users = await User.find({
      $or: [{ _id: { $in: userIds } }, { email: { $in: emails } }],
    }).select(USER_FIELDS);

    const foundIds = new Set(users.map((u) => String(u._id)));
    const foundEmails = new Set(users.map((u) => u.email));
    const notFound = [
      ...userIds.filter((id) => !foundIds.has(String(id))),
      ...emails.filter((e) => !foundEmails.has(e)),
    ];

    // Không chia sẻ cho chính người tạo
    const ownerId = String(task.createdBy);
    const skipped = users.filter((u) => String(u._id) === ownerId);
    const candidates = users.filter((u) => String(u._id) !== ownerId);

    const existing = await TaskShare.find({
      taskId: task._id,
      userId: { $in: candidates.map((u) => u._id) },
    })
      .select('userId')
      .lean();
    const existingSet = new Set(existing.map((s) => String(s.userId)));

    const alreadyShared = candidates.filter((u) => existingSet.has(String(u._id)));
    const toCreate = candidates.filter((u) => !existingSet.has(String(u._id)));

    let shared = [];
    if (toCreate.length > 0) {
      const docs = await TaskShare.insertMany(
        toCreate.map((u) => ({
          taskId: task._id,
          userId: u._id,
          permission,
          sharedBy: req.user._id,
        }))
      );
      shared = docs.map((d, i) => ({
        shareId: d._id,
        user: toCreate[i],
        permission: d.permission,
      }));
    }

    if (shared.length > 0) {
      await onTaskShared({
        task,
        actor: req.user,
        users: shared.map((s) => s.user),
        permission,
      });
    }

    return res.status(shared.length > 0 ? 201 : 200).json({
      message:
        shared.length > 0 ? 'Chia sẻ công việc thành công' : 'Không có ai mới được chia sẻ',
      shared,
      alreadyShared,
      skipped,
      notFound,
    });
  } catch (err) {
    next(err);
  }
};

const updateShare = async (req, res, next) => {
  try {
    const share = await TaskShare.findOne({
      _id: req.params.shareId,
      taskId: req.task._id,
    });
    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });
    }

    share.permission = req.body.permission;
    await share.save();

    return res.json({ message: 'Cập nhật quyền thành công', share });
  } catch (err) {
    next(err);
  }
};

const removeShare = async (req, res, next) => {
  try {
    const share = await TaskShare.findOneAndDelete({
      _id: req.params.shareId,
      taskId: req.task._id,
    });
    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });
    }

    return res.json({ message: 'Đã thu hồi quyền chia sẻ' });
  } catch (err) {
    next(err);
  }
};

module.exports = { listShares, addShares, updateShare, removeShare };