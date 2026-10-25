const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ message: 'Bạn chưa đăng nhập' });
    }

    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch (e) {
      return res
        .status(401)
        .json({ message: 'Token không hợp lệ hoặc đã hết hạn' });
    }

    // Kiểm tra tài khoản còn tồn tại trong DB
    const user = await User.findById(payload.userId);
    if (!user) {
      return res.status(401).json({ message: 'Tài khoản không tồn tại' });
    }

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
};

module.exports = { protect };