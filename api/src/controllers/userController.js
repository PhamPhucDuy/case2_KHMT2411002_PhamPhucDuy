const User = require('../models/User');

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const searchUsers = async (req, res, next) => {
  try {
    const rx = escapeRegex(req.query.q);
    const users = await User.find({
      $or: [
        { fullName: { $regex: rx, $options: 'i' } },
        { email: { $regex: rx, $options: 'i' } },
      ],
    })
      .select('fullName email avatarUrl')
      .limit(10)
      .lean();

    return res.json({ count: users.length, users });
  } catch (err) {
    next(err);
  }
};

const getUser = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id).select(
      'fullName email avatarUrl'
    );
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    return res.json({ user });
  } catch (err) {
    next(err);
  }
};

module.exports = { searchUsers, getUser };