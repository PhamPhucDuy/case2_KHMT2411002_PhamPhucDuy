const User = require('../models/User');
const { notifyUsers } = require('./notificationService');
const { queueTaskEmails } = require('./emailService');
const { getParticipantIds } = require('./taskService');
const templates = require('../utils/emailTemplates');

const STATUS_LABEL = {
  todo: 'Chưa thực hiện',
  in_progress: 'Đang thực hiện',
  completed: 'Đã hoàn thành',
};

const loadUsers = (ids) =>
  User.find({ _id: { $in: ids } }).select('fullName email');

// Bỏ người thực hiện thao tác, dựng danh sách email cần gửi
const toItems = (users, actorId, task, eventType, build) =>
  users
    .filter((u) => String(u._id) !== String(actorId))
    .map((u) => ({ to: u.email, taskId: task._id, eventType, ...build(u) }));

// Các hàm dưới đây không bao giờ ném lỗi ra ngoài: lỗi thông báo/email
// không được làm hỏng thao tác chính của người dùng.

const onTaskAssigned = async ({ task, actor, users }) => {
  try {
    await notifyUsers({
      userIds: users.map((u) => u._id),
      taskId: task._id,
      type: 'task_assigned',
      title: 'Bạn được giao công việc mới',
      message: `${actor.fullName} đã giao cho bạn công việc "${task.title}"`,
      excludeUserId: actor._id,
    });
    queueTaskEmails(
      toItems(users, actor._id, task, 'task_assigned', (u) =>
        templates.taskAssigned({
          task,
          actorName: actor.fullName,
          recipientName: u.fullName,
        })
      )
    );
  } catch (err) {
    console.error('onTaskAssigned:', err.message);
  }
};

const onTaskShared = async ({ task, actor, users, permission }) => {
  try {
    await notifyUsers({
      userIds: users.map((u) => u._id),
      taskId: task._id,
      type: 'task_shared',
      title: 'Có công việc được chia sẻ với bạn',
      message: `${actor.fullName} đã chia sẻ công việc "${task.title}" với quyền ${
        permission === 'editor' ? 'chỉnh sửa' : 'chỉ xem'
      }`,
      excludeUserId: actor._id,
    });
    queueTaskEmails(
      toItems(users, actor._id, task, 'task_shared', (u) =>
        templates.taskShared({
          task,
          actorName: actor.fullName,
          recipientName: u.fullName,
          permission,
        })
      )
    );
  } catch (err) {
    console.error('onTaskShared:', err.message);
  }
};

const onDueDateChanged = async ({ task, actor, oldDue }) => {
  try {
    const ids = await getParticipantIds(task);
    const users = await loadUsers(ids);
    await notifyUsers({
      userIds: ids,
      taskId: task._id,
      type: 'due_date_changed',
      title: 'Hạn hoàn thành đã thay đổi',
      message: `${actor.fullName} đã đổi hạn hoàn thành của "${task.title}"`,
      excludeUserId: actor._id,
    });
    queueTaskEmails(
      toItems(users, actor._id, task, 'due_date_changed', (u) =>
        templates.dueDateChanged({
          task,
          actorName: actor.fullName,
          recipientName: u.fullName,
          oldDue,
        })
      )
    );
  } catch (err) {
    console.error('onDueDateChanged:', err.message);
  }
};

const onStatusChanged = async ({ task, actor }) => {
  try {
    const ids = await getParticipantIds(task);
    const done = task.status === 'completed';

    await notifyUsers({
      userIds: ids,
      taskId: task._id,
      type: done ? 'task_completed' : 'task_status_changed',
      title: done ? 'Công việc đã hoàn thành' : 'Trạng thái công việc thay đổi',
      message: done
        ? `${actor.fullName} đã hoàn thành công việc "${task.title}"`
        : `${actor.fullName} đã chuyển "${task.title}" sang "${STATUS_LABEL[task.status]}"`,
      excludeUserId: actor._id,
    });

    // Email chỉ gửi khi hoàn thành
    if (done) {
      const users = await loadUsers(ids);
      queueTaskEmails(
        toItems(users, actor._id, task, 'task_completed', (u) =>
          templates.taskCompleted({
            task,
            actorName: actor.fullName,
            recipientName: u.fullName,
          })
        )
      );
    }
  } catch (err) {
    console.error('onStatusChanged:', err.message);
  }
};

module.exports = { onTaskAssigned, onTaskShared, onDueDateChanged, onStatusChanged };