const UserService = require('../services/user.service');

// POST /register
exports.register = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        status: false,
        message: 'Email và mật khẩu là bắt buộc',
      });
    }

    // Kiểm tra email đã tồn tại chưa
    const existing = await UserService.findByEmail(email);
    if (existing) {
      return res.status(409).json({
        status: false,
        message: `Email ${email} đã được đăng ký`,
      });
    }

    await UserService.createUser(email, password);

    res.status(201).json({
      status: true,
      message: 'Đăng ký thành công! Vui lòng đăng nhập.',
    });
  } catch (err) {
    next(err);
  }
};

// POST /login
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        status: false,
        message: 'Email và mật khẩu là bắt buộc',
      });
    }

    const user = await UserService.findByEmail(email);
    if (!user) {
      return res.status(404).json({
        status: false,
        message: 'Tài khoản không tồn tại',
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        status: false,
        message: 'Email hoặc mật khẩu không đúng',
      });
    }

    const token = UserService.generateToken(user);

    res.status(200).json({
      status: true,
      message: 'Đăng nhập thành công',
      token,
      userId: user._id,
      email: user.email,
    });
  } catch (err) {
    next(err);
  }
};
