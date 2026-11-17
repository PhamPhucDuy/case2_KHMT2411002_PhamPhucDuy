const mongoose = require('mongoose');
const checklistItemSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true, maxlength: 120 },
  done: { type: Boolean, default: false },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  completedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  completedAt: { type: Date, default: null },
}, { timestamps: true });

const taskSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, default: '', trim: true },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    assigneeIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    primaryAssigneeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    startDate: { type: Date, default: null },
    dueDate: { type: Date, default: null },
        // Hạn mà lần nhắc việc gần nhất đã gửi; đổi hạn thì được nhắc lại
        reminderSentFor: { type: Date, default: null },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },
    checklist: { type: [checklistItemSchema], default: [] },
    status: {
      type: String,
      enum: ['todo', 'in_progress', 'completed'],
      default: 'todo',
    },
  },
  { timestamps: true }
);

taskSchema.index({ assigneeIds: 1 });

module.exports = mongoose.model('Task', taskSchema);