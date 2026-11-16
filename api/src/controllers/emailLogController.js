const EmailLog = require('../models/EmailLog');
const { retryEmail, MAX_ATTEMPTS } = require('../services/emailService');
const { getTaskAccess, can } = require('../services/taskService');

const listTaskEmailLogs = async (req, res, next) => {
  try {
    const logs = await EmailLog.find({ taskId: req.task._id })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();
    return res.json({ count: logs.length, logs });
  } catch (err) {
    next(err);
  }
};

const retryEmailLog = async (req, res, next) => {
  try {
    const log = await EmailLog.findById(req.params.id).select('taskId');
    if (!log || !log.taskId) {
      return res.status(404).json({ message: 'Không tìm thấy lịch sử email' });
    }

    // Chỉ người tạo công việc được thử gửi lại; người khác coi như không thấy
    const { task, role } = await getTaskAccess(log.taskId, req.user._id);
    if (!task || !can(role, 'manageAccess')) {
      return res.status(404).json({ message: 'Không tìm thấy lịch sử email' });
    }

    const result = await retryEmail(log._id);
    if (!result) {
      return res.status(409).json({
        message: `Email không thể gửi lại (đã gửi thành công, đang gửi hoặc đã thử đủ ${MAX_ATTEMPTS} lần)`,
      });
    }

    const { html, text, ...safe } = result.toObject();
    return res.json({ message: 'Đã thử gửi lại email', log: safe });
  } catch (err) {
    next(err);
  }
};

module.exports = { listTaskEmailLogs, retryEmailLog };