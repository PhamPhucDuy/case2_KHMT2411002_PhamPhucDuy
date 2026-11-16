const Notification = require('../models/Notification');

const listNotifications = async (req, res, next) => {
  try {
    const limit = req.query.limit || 50;
    const filter = { userId: req.user._id };
    if (req.query.unreadOnly) filter.isRead = false;

    const notifications = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('taskId', 'title status')
      .lean();

    return res.json({ count: notifications.length, notifications });
  } catch (err) {
    next(err);
  }
};

const unreadCount = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.user._id,
      isRead: false,
    });
    return res.json({ count });
  } catch (err) {
    next(err);
  }
};

const markRead = async (req, res, next) => {
  try {
    // Điều kiện userId bảo đảm chỉ đọc được thông báo của chính mình
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ message: 'Không tìm thấy thông báo' });
    }
    return res.json({ message: 'Đã đánh dấu đã đọc', notification });
  } catch (err) {
    next(err);
  }
};

const markAllRead = async (req, res, next) => {
  try {
    const result = await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true }
    );
    return res.json({
      message: 'Đã đánh dấu tất cả đã đọc',
      modified: result.modifiedCount,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { listNotifications, unreadCount, markRead, markAllRead };