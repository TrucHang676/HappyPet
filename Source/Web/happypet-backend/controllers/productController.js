const { sql, config } = require('../config/db');

exports.getAllProducts = async (req, res) => {
  try {
    const { tuKhoa, loaiMH, maCN } = req.query;

    const pool = await sql.connect(config);
    const request = pool.request()
      .input('TuKhoa', sql.NVarChar, tuKhoa || null)
      .input('LoaiMH', sql.VarChar, loaiMH || null);

    let result;

    if (maCN) {
      // ✅ SP này giờ đã tự tính thêm DiemTrungBinh và SoLuongDanhGia rồi
      result = await request
        .input('MaCN', sql.VarChar, maCN)
        .execute('sp_TraCuuSanPham_TheoChiNhanh_Online');
    } else {
      // ✅ SP này cũng vậy luôn
      result = await request.execute('sp_TraCuuSanPham_Online');
    }

    // SQL đã lo hết dữ liệu, mình chỉ việc trả về recordset thôi
    res.json(result.recordset);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};