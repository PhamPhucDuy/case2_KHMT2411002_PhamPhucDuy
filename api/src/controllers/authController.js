const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
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

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // passwordHash mặc định bị ẩn (select: false) nên phải lấy rõ ràng
    const user = await User.findOne({ email }).select('+passwordHash');

    // Cùng một thông báo cho "sai email" và "sai mật khẩu"
    const isMatch = user && (await bcrypt.compare(password, user.passwordHash));
    if (!isMatch) {
      return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    return res.json({ message: 'Đăng nhập thành công', token, user });
  } catch (err) {
    next(err);
  }
};

const getMe = (req, res) => {
  res.json({ user: req.user });
};
const updateMe = async (req, res, next) => {
  try {
    // Chỉ lấy đúng các trường được phép sửa
    const updates = {};
    if (req.body.fullName !== undefined) updates.fullName = req.body.fullName;
    if (req.body.avatarUrl !== undefined) updates.avatarUrl = req.body.avatarUrl;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ message: 'Không có thông tin nào để cập nhật' });
    }

    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    });

    return res.json({ message: 'Cập nhật thông tin thành công', user });
  } catch (err) {
    next(err);
  }
};
const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // req.user không có passwordHash nên phải lấy lại từ DB
    const user = await User.findById(req.user._id).select('+passwordHash');

    const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();

    return res.json({ message: 'Đổi mật khẩu thành công' });
  } catch (err) {
    next(err);
  }
};
module.exports = { register, login, getMe, updateMe, changePassword };