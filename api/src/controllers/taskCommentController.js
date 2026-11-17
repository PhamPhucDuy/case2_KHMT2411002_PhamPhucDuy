const mongoose = require('mongoose');
const TaskComment = require('../models/TaskComment');
const { getTaskAccess, can } = require('../services/taskService');
const { logActivity } = require('../services/activityService');

async function authorize(req, res, write = false) {
  if (!mongoose.isValidObjectId(req.params.id)) {
    res.status(404).json({ message: 'Task not found' });
    return null;
  }
  const { task, role } = await getTaskAccess(req.params.id, req.user._id);
  if (!task || !can(role, 'view')) {
    res.status(404).json({ message: 'Task not found' });
    return null;
  }
  if (write && !['owner', 'editor', 'assignee'].includes(role)) {
    res.status(403).json({ message: 'Only task participants can write comments' });
    return null;
  }
  return { task, role };
}

function validText(value) {
  if (typeof value !== 'string') return null;
  const text = value.trim();
  return text.length >= 1 && text.length <= 1000 ? text : null;
}

function present(comment, currentUserId, role) {
  const authorId = String(comment.userId?._id || comment.userId);
  const isAuthor = authorId === String(currentUserId);
  return {
    ...comment,
    canEdit: role !== 'viewer' && isAuthor,
    canDelete: role !== 'viewer' && (isAuthor || role === 'owner'),
  };
}

exports.list = async (req, res, next) => {
  try {
    const access = await authorize(req, res);
    if (!access) return;
    const latest = await TaskComment.find({ taskId: access.task._id })
      .sort({ createdAt: -1 }).limit(100)
      .populate('userId', 'fullName email').lean();
    res.json({
      comments: latest.reverse().map((c) => present(c, req.user._id, access.role)),
      canComment: access.role !== 'viewer',
    });
  } catch (error) { next(error); }
};

exports.add = async (req, res, next) => {
  try {
    const access = await authorize(req, res, true);
    if (!access) return;
    const text = validText(req.body?.text);
    if (!text) return res.status(400).json({ message: 'Comment must be 1-1000 characters' });
    const comment = await TaskComment.create({
      taskId: access.task._id, userId: req.user._id, text,
    });
    await logActivity({ taskId: access.task._id, userId: req.user._id,
      action: 'comment_added', details: { commentId: comment._id } });
    res.status(201).json({ message: 'Comment created', id: comment._id });
  } catch (error) { next(error); }
};

exports.edit = async (req, res, next) => {
  try {
    const access = await authorize(req, res, true);
    if (!access) return;
    if (!mongoose.isValidObjectId(req.params.commentId)) {
      return res.status(404).json({ message: 'Comment not found' });
    }
    const comment = await TaskComment.findOne({
      _id: req.params.commentId, taskId: access.task._id,
    });
    if (!comment) return res.status(404).json({ message: 'Comment not found' });
    if (String(comment.userId) !== String(req.user._id)) {
      return res.status(403).json({ message: 'You can edit only your own comments' });
    }
    const text = validText(req.body?.text);
    if (!text) return res.status(400).json({ message: 'Comment must be 1-1000 characters' });
    comment.text = text;
    await comment.save();
    await logActivity({ taskId: access.task._id, userId: req.user._id,
      action: 'comment_edited', details: { commentId: comment._id } });
    res.json({ message: 'Comment updated' });
  } catch (error) { next(error); }
};

exports.remove = async (req, res, next) => {
  try {
    const access = await authorize(req, res, true);
    if (!access) return;
    if (!mongoose.isValidObjectId(req.params.commentId)) {
      return res.status(404).json({ message: 'Comment not found' });
    }
    const comment = await TaskComment.findOne({
      _id: req.params.commentId, taskId: access.task._id,
    });
    if (!comment) return res.status(404).json({ message: 'Comment not found' });
    const author = String(comment.userId) === String(req.user._id);
    if (!author && access.role !== 'owner') {
      return res.status(403).json({ message: 'You cannot delete this comment' });
    }
    await comment.deleteOne();
    await logActivity({ taskId: access.task._id, userId: req.user._id,
      action: 'comment_deleted', details: { commentId: req.params.commentId } });
    res.json({ message: 'Comment deleted' });
  } catch (error) { next(error); }
};