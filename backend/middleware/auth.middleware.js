const jwt = require('jsonwebtoken');

const JWT_SECRET = 'todo_jwt_secret_key_2024';

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      status: false,
      message: 'Không có token xác thực. Vui lòng đăng nhập.',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded._id;
    req.userEmail = decoded.email;
    next();
  } catch (err) {
    return res.status(401).json({
      status: false,
      message: 'Token không hợp lệ hoặc đã hết hạn.',
    });
  }
};

module.exports = { verifyToken, JWT_SECRET };
