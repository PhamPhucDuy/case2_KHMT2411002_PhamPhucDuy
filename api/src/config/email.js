const nodemailer = require('nodemailer');

let transporter = null;

const isConfigured = () =>
  Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS);

// Trả về null nếu SMTP chưa được cấu hình trong .env
const getTransporter = () => {
  if (!isConfigured()) return null;
  if (!transporter) {
    const port = Number(process.env.SMTP_PORT) || 587;
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port,
      secure: port === 465,
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 15000,
    });
  }
  return transporter;
};

const getFromAddress = () =>
  process.env.SMTP_FROM || `Task Manager <${process.env.SMTP_USER}>`;

module.exports = { getTransporter, getFromAddress };