const router = require('express').Router();
const UserController = require('../controllers/user.controller');

// Đăng ký
router.post('/register', UserController.register);

// Đăng nhập
router.post('/login', UserController.login);

module.exports = router;
