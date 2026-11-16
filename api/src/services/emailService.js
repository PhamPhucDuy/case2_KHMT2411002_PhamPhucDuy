const EmailLog = require('../models/EmailLog');
const { getTransporter, getFromAddress } = require('../config/email');

const MAX_ATTEMPTS = 3;

// Gửi một email theo bản ghi log (log phải có html và text) và cập nhật trạng thái
const deliver = async (log) => {
  log.attempts += 1;
  const transporter = getTransporter();

  if (!transporter) {
    log.status = 'failed';
    log.errorMessage = 'SMTP chưa được cấu hình';
  } else {
    try {
      await transporter.sendMail({
        from: getFromAddress(),
        to: log.recipientEmail,
        subject: log.subject,
        html: log.html,
        text: log.text,
      });
      log.status = 'sent';
      log.sentAt = new Date();
      log.errorMessage = '';
    } catch (err) {
      log.status = 'failed';
      log.errorMessage = String(err.message || err).slice(0, 300);
    }
  }

  await log.save();
  return log;
};

const sendTaskEmail = async ({ to, taskId, eventType, subject, html, text }) => {
  try {
    const log = await EmailLog.create({
      taskId,
      recipientEmail: to,
      eventType,
      subject,
      html,
      text,
      status: 'pending',
    });
    return await deliver(log);
  } catch (err) {
    console.error('Lỗi gửi email:', err.message);
    return null;
  }
};

// Gửi ngầm: không chờ kết quả để API trả lời nhanh
const queueTaskEmails = (items) => {
  Promise.allSettled(items.map(sendTaskEmail));
};

// Chỉ email failed và chưa quá số lần thử mới gửi lại được.
// Chuyển failed -> pending là một lệnh nguyên tử nên không bị gửi trùng.
const retryEmail = async (logId) => {
  const log = await EmailLog.findOneAndUpdate(
    { _id: logId, status: 'failed', attempts: { $lt: MAX_ATTEMPTS } },
    { status: 'pending' },
    { new: true }
  ).select('+html +text');

  if (!log) return null;
  return deliver(log);
};

module.exports = { queueTaskEmails, retryEmail, MAX_ATTEMPTS };