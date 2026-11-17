const mongoose = require('mongoose');

const taskCommentSchema = new mongoose.Schema({
  taskId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task', required: true, index: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', required: true,
  },
  text: {
    type: String, required: true, trim: true, maxlength: 1000,
  },
}, { timestamps: true });

taskCommentSchema.index({ taskId: 1, createdAt: -1 });
module.exports = mongoose.model('TaskComment', taskCommentSchema);