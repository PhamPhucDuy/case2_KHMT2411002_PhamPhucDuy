// Route không tồn tại
const notFound = (req, res) => {
  res.status(404).json({ message: 'Không tìm thấy đường dẫn' });
};

// Xử lý lỗi chung, không lộ chi tiết nội bộ ra ngoài
const errorHandler = (err, req, res, next) => {
  // Trùng unique index của MongoDB (ví dụ email)
  if (err.code === 11000) {
    return res.status(409).json({ message: 'Dữ liệu đã tồn tại' });
  }

  console.error(err); // chỉ ghi ở server, không trả cho client
  res.status(500).json({ message: 'Lỗi hệ thống, vui lòng thử lại sau' });
};

module.exports = { notFound, errorHandler };