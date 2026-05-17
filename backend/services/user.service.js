const User = require('../models/user.model');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth.middleware');

class UserService {
  // Tìm user theo email
  static async findByEmail(email) {
    return await User.findOne({ email });
  }

  // Tạo user mới
  static async createUser(email, password) {
    const user = new User({ email, password });
    return await user.save();
  }

  // Tạo JWT token
  static generateToken(user) {
    const payload = { _id: user._id, email: user.email };
    return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
  }
}

module.exports = UserService;
