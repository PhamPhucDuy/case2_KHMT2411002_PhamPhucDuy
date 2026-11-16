const Task = require('../models/Task');
const User = require('../models/User');
const { notifyUsers } = require('./notificationService');
const { queueTaskEmails } = require('./emailService');
const { getParticipantIds } = require('./taskService');
const templates = require('../utils/emailTemplates');

const WINDOW_MS = 24 * 60 * 60 * 1000; // nhắc trước hạn 24 giờ
const INTERVAL_MS = 10 * 60 * 1000; // quét mỗi 10 phút

let running = false;

const formatDue = (d) =>
  new Date(d).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' });

const sendReminders = async () => {
  if (running) return; // lần quét trước chưa xong thì bỏ qua
  running = true;
  try {
    const now = new Date();
    const candidates = await Task.find({
      status: { $ne: 'completed' },
      dueDate: { $gt: now, $lte: new Date(now.getTime() + WINDOW_MS) },
    }).lean();

    for (const task of candidates) {
      // Hạn này đã được nhắc rồi thì bỏ qua
      if (
        task.reminderSentFor &&
        new Date(task.reminderSentFor).getTime() === new Date(task.dueDate).getTime()
      ) {
        continue;
      }

      // Đánh dấu đã nhắc bằng một lệnh nguyên tử: chỉ một lần quét giành được
      const claim = await Task.updateOne(
        { _id: task._id, dueDate: task.dueDate, reminderSentFor: { $ne: task.dueDate } },
        { $set: { reminderSentFor: task.dueDate } },
        { timestamps: false }
      );
      if (claim.modifiedCount !== 1) continue;

      const ids = await getParticipantIds(task);
      const users = await User.find({ _id: { $in: ids } }).select('fullName email');

      await notifyUsers({
        userIds: ids,
        taskId: task._id,
        type: 'due_soon',
        title: 'Công việc sắp đến hạn',
        message: `Công việc "${task.title}" sẽ đến hạn lúc ${formatDue(task.dueDate)}`,
      });

      queueTaskEmails(
        users.map((u) => ({
          to: u.email,
          taskId: task._id,
          eventType: 'due_soon',
          ...templates.dueSoon({ task, recipientName: u.fullName }),
        }))
      );
    }
  } catch (err) {
    console.error('Lỗi quét nhắc việc:', err.message);
  } finally {
    running = false;
  }
};

// Gọi một lần khi server khởi động (sau khi đã kết nối cơ sở dữ liệu)
const startReminderJob = () => {
  sendReminders();
  setInterval(sendReminders, INTERVAL_MS);
};

module.exports = { startReminderJob, sendReminders };
