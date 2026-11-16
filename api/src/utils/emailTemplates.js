const escapeHtml = (value) =>
  String(value ?? '').replace(
    /[&<>"']/g,
    (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])
  );

const formatDate = (d) =>
  d
    ? new Date(d).toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })
    : 'Chưa đặt';

const PRIORITY_LABEL = { low: 'Thấp', medium: 'Trung bình', high: 'Cao' };
const STATUS_LABEL = {
  todo: 'Chưa thực hiện',
  in_progress: 'Đang thực hiện',
  completed: 'Đã hoàn thành',
};

const render = ({ subject, heading, intro, task, extraRows = [] }) => {
  const rows = [
    ['Công việc', task.title],
    ['Ưu tiên', PRIORITY_LABEL[task.priority] || task.priority],
    ['Trạng thái', STATUS_LABEL[task.status] || task.status],
    ['Ngày bắt đầu', formatDate(task.startDate)],
    ['Hạn hoàn thành', formatDate(task.dueDate)],
    ...extraRows,
  ];

  const html = `
<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;color:#222">
  <h2 style="color:#3f51b5">${escapeHtml(heading)}</h2>
  <p>${escapeHtml(intro)}</p>
  <table style="border-collapse:collapse;width:100%">
    ${rows
      .map(
        ([k, v]) =>
          `<tr><td style="padding:6px 8px;border:1px solid #ddd;background:#f6f6f6">${escapeHtml(
            k
          )}</td><td style="padding:6px 8px;border:1px solid #ddd">${escapeHtml(v)}</td></tr>`
      )
      .join('')}
  </table>
  <p style="color:#888;font-size:12px">Email tự động từ Task Manager.</p>
</div>`;

  const text = [heading, intro, '', ...rows.map(([k, v]) => `${k}: ${v}`)].join('\n');
  return { subject, html, text };
};

const taskAssigned = ({ task, actorName, recipientName }) =>
  render({
    subject: `Bạn được giao công việc: ${task.title}`,
    heading: 'Bạn được giao công việc mới',
    intro: `Xin chào ${recipientName}, ${actorName} đã giao cho bạn một công việc.`,
    task,
  });

const taskShared = ({ task, actorName, recipientName, permission }) =>
  render({
    subject: `Công việc được chia sẻ với bạn: ${task.title}`,
    heading: 'Có công việc được chia sẻ với bạn',
    intro: `Xin chào ${recipientName}, ${actorName} đã chia sẻ một công việc với bạn.`,
    task,
    extraRows: [['Quyền của bạn', permission === 'editor' ? 'Chỉnh sửa' : 'Chỉ xem']],
  });

const dueDateChanged = ({ task, actorName, recipientName, oldDue }) =>
  render({
    subject: `Hạn hoàn thành đã thay đổi: ${task.title}`,
    heading: 'Hạn hoàn thành đã thay đổi',
    intro: `Xin chào ${recipientName}, ${actorName} đã đổi hạn hoàn thành của một công việc.`,
    task,
    extraRows: [['Hạn cũ', formatDate(oldDue)]],
  });

const taskCompleted = ({ task, actorName, recipientName }) =>
  render({
    subject: `Công việc đã hoàn thành: ${task.title}`,
    heading: 'Công việc đã hoàn thành',
    intro: `Xin chào ${recipientName}, ${actorName} đã đánh dấu hoàn thành một công việc.`,
    task,
  });

const dueSoon = ({ task, recipientName }) =>
  render({
    subject: `Sắp đến hạn: ${task.title}`,
    heading: 'Công việc sắp đến hạn',
    intro: `Xin chào ${recipientName}, công việc sau sẽ đến hạn trong vòng 24 giờ tới.`,
    task,
  });

module.exports = { taskAssigned, taskShared, dueDateChanged, taskCompleted, dueSoon };
