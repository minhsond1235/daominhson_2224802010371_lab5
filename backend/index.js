const app = require('./app');
const connectDB = require('./config/db');

const PORT = process.env.PORT || 3000;

// Kết nối MongoDB rồi mới start server
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
    console.log(`📋 Các API endpoints:`);
    console.log(`   POST http://localhost:${PORT}/register`);
    console.log(`   POST http://localhost:${PORT}/login`);
    console.log(`   GET  http://localhost:${PORT}/todos  (cần JWT)`);
    console.log(`   POST http://localhost:${PORT}/todos  (cần JWT)`);
    console.log(`   PUT  http://localhost:${PORT}/todos/:id  (cần JWT)`);
    console.log(`   DELETE http://localhost:${PORT}/todos/:id  (cần JWT)`);
  });
});
