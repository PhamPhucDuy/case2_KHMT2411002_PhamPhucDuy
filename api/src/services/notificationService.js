const Notification = require('../models/Notification');

// Tạo thông báo cho nhiều người; bỏ qua người thực hiện thao tác.
// Lỗi tạo thông báo chỉ được ghi log, không làm hỏng thao tác chính.
const notifyUsers = async ({
  userIds,
  taskId,
  type,
  title,
  message,
  excludeUserId,
}) => {
  const targets = [...new Set(userIds.map(String))].filter(
    (id) => !excludeUserId || id !== String(excludeUserId)
  );
  if (targets.length === 0) return [];

  try {
    return await Notification.insertMany(
      targets.map((userId) => ({ userId, taskId, type, title, message }))
    );
  } catch (err) {
    console.error('Không tạo được thông báo:', err.message);
    return [];
  }
};

module.exports = { notifyUsers };