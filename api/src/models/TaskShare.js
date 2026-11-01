const mongoose = require('mongoose');

const taskShareSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    permission: {
      type: String,
      enum: ['viewer', 'editor'],
      default: 'viewer',
    },
    sharedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
    {
      timestamps: { createdAt: true, updatedAt: false },
      collection: 'task_shares',
    }
);

// Mỗi người chỉ có một bản ghi chia sẻ trên mỗi công việc
taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('TaskShare', taskShareSchema);