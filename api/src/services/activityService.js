const TaskActivity = require('../models/TaskActivity');

// Ghi lịch sử hoạt động. Không bao giờ ném lỗi ra ngoài:
// lỗi ghi lịch sử không được làm hỏng thao tác chính của người dùng.
const logActivity = async ({ taskId, userId, action, details = {} }) => {
  try {
    return await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('Không ghi được lịch sử hoạt động:', err.message);
    return null;
  }
};

// Thông tin ngắn gọn về một người dùng để lưu trong chi tiết lịch sử
const userSnapshot = (u, fallbackId = null) =>
  u ? { id: u._id, fullName: u.fullName, email: u.email } : { id: fallbackId };

module.exports = { logActivity, userSnapshot };
