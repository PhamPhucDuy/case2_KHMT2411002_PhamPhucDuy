const mongoose = require('mongoose');
const { getTaskAccess, can } = require('../services/taskService');
const { logActivity } = require('../services/activityService');

async function access(req, res, permission) {
  if (!mongoose.isValidObjectId(req.params.id)) {
    res.status(404).json({ message: 'Task not found' });
    return null;
  }
  const { task, role } = await getTaskAccess(req.params.id, req.user._id);
  if (!task || !can(role, 'view')) {
    res.status(404).json({ message: 'Task not found' });
    return null;
  }
  if (!can(role, permission)) {
    res.status(403).json({ message: 'You do not have permission' });
    return null;
  }
  return { task, role };
}

function summary(items) {
  const total = items.length;
  const completed = items.filter((item) => item.done).length;
  return { total, completed, percent: total ? Math.round(completed * 100 / total) : 0 };
}

exports.list = async (req, res, next) => {
  try {
    const result = await access(req, res, 'view');
    if (!result) return;
    const { task, role } = result;
    res.json({
      items: task.checklist,
      summary: summary(task.checklist),
      canManage: can(role, 'edit'),
      canToggle: can(role, 'changeStatus'),
    });
  } catch (err) { next(err); }
};

exports.add = async (req, res, next) => {
  try {
    const result = await access(req, res, 'edit');
    if (!result) return;
    const { task } = result;
    const title = typeof req.body.title === 'string' ? req.body.title.trim() : '';
    if (!title || title.length > 120) {
      return res.status(400).json({ message: 'Title must contain 1-120 characters' });
    }
    if (task.checklist.length >= 50) {
      return res.status(400).json({ message: 'Maximum 50 checklist items' });
    }
    task.checklist.push({ title, createdBy: req.user._id });
    const item = task.checklist[task.checklist.length - 1];
    await task.save();
    await logActivity({
      taskId: task._id, userId: req.user._id,
      action: 'checklist_item_added',
      details: { itemId: item._id, title },
    });
    res.status(201).json({ item, summary: summary(task.checklist) });
  } catch (err) { next(err); }
};

exports.setDone = async (req, res, next) => {
  try {
    const result = await access(req, res, 'changeStatus');
    if (!result) return;
    const { task } = result;
    if (!mongoose.isValidObjectId(req.params.itemId)) {
      return res.status(404).json({ message: 'Checklist item not found' });
    }
    const item = task.checklist.id(req.params.itemId);
    if (!item) return res.status(404).json({ message: 'Checklist item not found' });
    if (typeof req.body.done !== 'boolean') {
      return res.status(400).json({ message: 'done must be a boolean' });
    }
    if (item.done !== req.body.done) {
      item.done = req.body.done;
      item.completedAt = item.done ? new Date() : null;
      item.completedBy = item.done ? req.user._id : null;
      await task.save();
      await logActivity({
        taskId: task._id, userId: req.user._id,
        action: item.done ? 'checklist_item_completed' : 'checklist_item_reopened',
        details: { itemId: item._id, title: item.title },
      });
    }
    res.json({ item, summary: summary(task.checklist) });
  } catch (err) { next(err); }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await access(req, res, 'edit');
    if (!result) return;
    const { task } = result;
    if (!mongoose.isValidObjectId(req.params.itemId)) {
      return res.status(404).json({ message: 'Checklist item not found' });
    }
    const item = task.checklist.id(req.params.itemId);
    if (!item) return res.status(404).json({ message: 'Checklist item not found' });
    const title = item.title;
    task.checklist.pull({ _id: item._id });
    await task.save();
    await logActivity({
      taskId: task._id, userId: req.user._id,
      action: 'checklist_item_deleted',
      details: { itemId: req.params.itemId, title },
    });
    res.json({ message: 'Checklist item deleted', summary: summary(task.checklist) });
  } catch (err) { next(err); }
};