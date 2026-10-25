const bcrypt = require('bcryptjs');
const User = require('../models/User');

const register = async (req, res, next) => {
  try {
    const { fullName, email, password } = req.body;

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: 'Email đã được sử dụng' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ fullName, email, passwordHash });

    return res.status(201).json({ message: 'Đăng ký thành công', user });
  } catch (err) {
    next(err);
  }
};

module.exports = { register };