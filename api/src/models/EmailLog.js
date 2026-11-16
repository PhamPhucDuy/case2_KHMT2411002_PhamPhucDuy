const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      default: null,
      index: true,
    },
    recipientEmail: { type: String, required: true },
    eventType: { type: String, required: true },
    subject: { type: String, required: true },
    status: {
      type: String,
      enum: ['pending', 'sent', 'failed'],
      default: 'pending',
    },
    attempts: { type: Number, default: 0 },
    errorMessage: { type: String, default: '' },
    sentAt: { type: Date, default: null },
    // Nội dung lưu để thử gửi lại; không trả ra API
    html: { type: String, select: false },
    text: { type: String, select: false },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'email_logs',
  }
);

module.exports = mongoose.model('EmailLog', emailLogSchema);