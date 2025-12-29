const { sql, config } = require('../config/db');

const branchService = {
  getBranches: async () => {
    const pool = await sql.connect(config);
    const result = await pool.request().execute('sp_XemDanhSachChiNhanh');
    return result.recordset;
  }
};

module.exports = branchService;
