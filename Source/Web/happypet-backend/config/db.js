const sql = require('mssql');
require('dotenv').config();

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    server: process.env.DB_SERVER, 
    database: process.env.DB_NAME,
    port: parseInt(process.env.DB_PORT), // Quan trọng: Kết nối thẳng vào cổng 1433
    options: {
        encrypt: true, 
        trustServerCertificate: true // Bắt buộc true khi chạy ở máy cá nhân (localhost)
    }
};

const connectDB = async () => {
    try {
        console.log(`⏳ Đang kết nối đến ${config.server}...`);
        const pool = await sql.connect(config); // Gán vào biến
        console.log("✅ Đã kết nối SQL Server thành công!");
        return pool; // PHẢI CÓ DÒNG NÀY
    } catch (err) {
        console.log("❌ Lỗi kết nối SQL:", err.message);
        throw err; 
    }
};
module.exports = { connectDB, sql, config };