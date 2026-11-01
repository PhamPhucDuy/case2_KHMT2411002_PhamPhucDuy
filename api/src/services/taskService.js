const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

// Trả về công việc và vai trò của người dùng trên công việc đó
const getTaskAccess = async (taskId, userId) => {
  const task = await Task.findById(taskId);
  if (!task) return { task: null, role: null };

  const uid = String(userId);
  if (String(task.createdBy) === uid) return { task, role: 'owner' };

  const share = await TaskShare.findOne({ taskId: task._id, userId });
  if (share && share.permission === 'editor') return { task, role: 'editor' };

  if (task.assigneeIds.some((id) => String(id) === uid)) {
    return { task, role: 'assignee' };
  }
  if (share) return { task, role: 'viewer' };

  return { task, role: null };
};

// Bảng quyền theo vai trò
const PERMISSIONS = {
  view: ['owner', 'editor', 'assignee', 'viewer'],
  edit: ['owner', 'editor'],
  changeStatus: ['owner', 'editor', 'assignee'],
  delete: ['owner'],
  manageAccess: ['owner'],
};

const can = (role, action) => PERMISSIONS[action].includes(role);

module.exports = { getTaskAccess, can };