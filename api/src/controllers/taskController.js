const Task = require('../models/Task');

const createTask = async (req, res, next) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;

    const task = await Task.create({
      title,
      description,
      startDate,
      dueDate,
      priority,
      status,
      createdBy: req.user._id, // lấy từ token, không nhận từ client
    });

    return res.status(201).json({ message: 'Tạo công việc thành công', task });
  } catch (err) {
    next(err);
  }
};

module.exports = { createTask };