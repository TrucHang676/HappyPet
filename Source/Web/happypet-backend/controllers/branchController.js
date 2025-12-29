// const branchService = require('../services/branchService');

// exports.getBranches = async (req, res) => {
//   try {
//     const data = await branchService.getBranches();
//     res.json(data);
//   } catch (e) {
//     res.status(500).json({ message: e.message });
//   }
// };

const { sql, connectDB } = require('../config/db');

exports.getBranches = async (req, res) => {
    try {
        const { tuKhoa } = req.query; 
        const pool = await connectDB();

        const result = await pool.request()
            .input('TuKhoa', sql.NVarChar, tuKhoa || null)
            .execute('sp_XemDanhSachChiNhanh'); 
            
        res.json(result.recordset);
    } catch (error) {
        console.error("❌ Lỗi lấy chi nhánh:", error);
        res.status(500).json({ message: error.message });
    }
};