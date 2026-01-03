import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';
import dayjs from 'dayjs';
import './Manager.css';

const ManagerDashboard = () => {
    const [activeTab, setActiveTab] = useState('overview');
    const [branches, setBranches] = useState([]);
    const [employees, setEmployees] = useState([]);
    const [products, setProducts] = useState([]);
    const [searchTerm, setSearchTerm] = useState(''); // State tìm kiếm nhân viên
    
    // States cho các form
    const [transferData, setTransferData] = useState({
        MaNV: '',
        MaCN_Moi: '',
        NgayBD: dayjs().format('YYYY-MM-DD'),
        NgayKT: dayjs().add(1, 'year').format('YYYY-MM-DD'),
        GhiChu: ''
    });

    const [stockData, setStockData] = useState({
        MaMatHang: '',
        SoLuongNhap: ''
    });

    const [newProductData, setNewProductData] = useState({
        TenMatHang: '',
        HangSX: '',
        NgaySanXuat: dayjs().format('YYYY-MM-DD'),
        NgayHetHan: dayjs().add(2, 'years').format('YYYY-MM-DD'),
        DonGia: '',
        LoaiMH: 'SPK',
        LoaiSP: 'Đồ chơi'
    });

    // States cho thống kê
    const [stats, setStats] = useState({
        productRevenue: [],
        branchRevenue: [],
        topEmployees: [],
        topProducts: [],
        lowStock: [],
        topService: {},
        membershipStats: []
    });

    const [filters, setFilters] = useState({
        tuNgay: dayjs().subtract(1, 'month').format('YYYY-MM-DD'),
        denNgay: dayjs().format('YYYY-MM-DD'),
        thang: dayjs().month() + 1,
        nam: dayjs().year(),
        diemSan: 4.0,
        nguongCanhBao: 10
    });

    const token = localStorage.getItem('token');
    const maCN = localStorage.getItem('maCN');

    useEffect(() => {
        loadBranches();
        loadEmployees();
        loadProducts();
    }, []);

    const loadBranches = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/branches');
            setBranches(res.data);
        } catch (err) {
            console.error(err);
        }
    };

    const loadEmployees = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/employees', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setEmployees(res.data);
        } catch (err) {
            console.error(err);
        }
    };

    const loadProducts = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/products', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setProducts(res.data);
        } catch (err) {
            console.error(err);
        }
    };

    // ================ THỐNG KÊ ================
    const loadProductRevenue = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/product-revenue', {
                params: { tuNgay: filters.tuNgay, denNgay: filters.denNgay },
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, productRevenue: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    const loadBranchRevenue = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/branch-revenue', {
                params: { thang: filters.thang, nam: filters.nam },
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, branchRevenue: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    const loadTopEmployees = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/top-employees', {
                params: { diemSan: filters.diemSan },
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, topEmployees: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    const loadTopProducts = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/top-products', {
                params: { diemSan: filters.diemSan },
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, topProducts: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    const loadLowStock = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/low-stock-alert', {
                params: { maCN: maCN, nguongCanhBao: filters.nguongCanhBao },
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, lowStock: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    const loadTopService = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/top-service', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, topService: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    const loadMembershipStats = async () => {
        try {
            const res = await axios.get('http://localhost:5000/api/manager/membership-stats', {
                params: { nam: filters.nam },
                headers: { Authorization: `Bearer ${token}` }
            });
            setStats(prev => ({ ...prev, membershipStats: res.data }));
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Không thể tải dữ liệu', 'error');
        }
    };

    // ================ ĐIỀU ĐỘNG NHÂN SỰ ================
    const handleTransferEmployee = async (e) => {
        e.preventDefault();
        try {
            const res = await axios.post('http://localhost:5000/api/manager/transfer-employee', 
                transferData,
                { headers: { Authorization: `Bearer ${token}` } }
            );
            Swal.fire('Thành công', res.data.message, 'success');
            setTransferData({
                MaNV: '',
                MaCN_Moi: '',
                NgayBD: dayjs().format('YYYY-MM-DD'),
                NgayKT: dayjs().add(1, 'year').format('YYYY-MM-DD'),
                GhiChu: ''
            });
            loadEmployees();
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Điều động thất bại', 'error');
        }
    };

    // ================ NHẬP HÀNG ================
    const handleImportStock = async (e) => {
        e.preventDefault();
        try {
            const res = await axios.post('http://localhost:5000/api/manager/import-stock',
                { ...stockData, MaCN: maCN },
                { headers: { Authorization: `Bearer ${token}` } }
            );
            Swal.fire('Thành công', res.data.message, 'success');
            setStockData({ MaMatHang: '', SoLuongNhap: '' });
            loadLowStock();
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Nhập hàng thất bại', 'error');
        }
    };

    // ================ THÊM MẶT HÀNG ================
    const handleAddProduct = async (e) => {
        e.preventDefault();
        try {
            const res = await axios.post('http://localhost:5000/api/manager/add-product',
                newProductData,
                { headers: { Authorization: `Bearer ${token}` } }
            );
            Swal.fire('Thành công', res.data.message, 'success');
            setNewProductData({
                TenMatHang: '',
                HangSX: '',
                NgaySanXuat: dayjs().format('YYYY-MM-DD'),
                NgayHetHan: dayjs().add(2, 'years').format('YYYY-MM-DD'),
                DonGia: '',
                LoaiMH: 'SPK',
                LoaiSP: 'Đồ chơi'
            });
            loadProducts();
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Thêm mặt hàng thất bại', 'error');
        }
    };

    // ================ CẬP NHẬT XẾP HẠNG (31/12 only) ================
    const handleUpdateRanking = async () => {
        const today = dayjs();
        if (today.month() !== 11 || today.date() !== 31) {
            Swal.fire('Cảnh báo', 'Chức năng này chỉ được phép chạy vào ngày 31/12!', 'warning');
            return;
        }

        Swal.fire({
            title: 'Xác nhận',
            text: 'Bạn có chắc muốn cập nhật xếp hạng hội viên?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Có, cập nhật',
            cancelButtonText: 'Hủy'
        }).then(async (result) => {
            if (result.isConfirmed) {
                try {
                    const res = await axios.post('http://localhost:5000/api/manager/update-membership-ranking',
                        { nam: filters.nam },
                        { headers: { Authorization: `Bearer ${token}` } }
                    );
                    Swal.fire('Thành công', res.data.message, 'success');
                    loadMembershipStats();
                } catch (err) {
                    Swal.fire('Lỗi', err.response?.data?.message || 'Cập nhật thất bại', 'error');
                }
            }
        });
    };

    const formatCurrency = (value) => {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value);
    };

    return (
        <div className="manager-dashboard">
            <div className="manager-header">
                <h1>🎯 Quản Lý Hệ Thống</h1>
                <p>Dashboard dành cho Quản lý Chi nhánh & Admin</p>
            </div>

            {/* TABS */}
            <div className="manager-tabs">
                <button className={activeTab === 'overview' ? 'active' : ''} onClick={() => setActiveTab('overview')}>
                    📊 Tổng quan
                </button>
                <button className={activeTab === 'revenue' ? 'active' : ''} onClick={() => setActiveTab('revenue')}>
                    💰 Doanh thu
                </button>
                <button className={activeTab === 'rating' ? 'active' : ''} onClick={() => setActiveTab('rating')}>
                    ⭐ Đánh giá
                </button>
                <button className={activeTab === 'stock' ? 'active' : ''} onClick={() => setActiveTab('stock')}>
                    📦 Kho hàng
                </button>
                <button className={activeTab === 'employee' ? 'active' : ''} onClick={() => setActiveTab('employee')}>
                    👥 Nhân sự
                </button>
                <button className={activeTab === 'membership' ? 'active' : ''} onClick={() => setActiveTab('membership')}>
                    🎖️ Hội viên
                </button>
            </div>

            {/* CONTENT */}
            <div className="manager-content">
                
                {/* TỔNG QUAN */}
                {activeTab === 'overview' && (
                    <div className="overview-section">
                        <h2>📊 Tổng quan hệ thống</h2>
                        
                        <div className="overview-cards">
                            <div className="overview-card">
                                <div className="card-icon">🏢</div>
                                <div className="card-info">
                                    <h3>{branches.length}</h3>
                                    <p>Chi nhánh</p>
                                </div>
                            </div>
                            <div className="overview-card">
                                <div className="card-icon">👥</div>
                                <div className="card-info">
                                    <h3>{employees.length}</h3>
                                    <p>Nhân viên</p>
                                </div>
                            </div>
                            <div className="overview-card">
                                <div className="card-icon">📦</div>
                                <div className="card-info">
                                    <h3>{products.length}</h3>
                                    <p>Mặt hàng</p>
                                </div>
                            </div>
                            <div className="overview-card" onClick={() => { loadTopService(); }}>
                                <div className="card-icon">🏆</div>
                                <div className="card-info">
                                    <h3>Top DV</h3>
                                    <p>Doanh thu cao nhất 6 tháng</p>
                                </div>
                            </div>
                        </div>

                        {/* Top Service */}
                        {stats.topService.LoaiDichVu && (
                            <div className="top-service-box">
                                <h3>🏆 Dịch vụ mang lại doanh thu cao nhất (6 tháng gần đây)</h3>
                                <div className="service-highlight">
                                    <span className="service-name">{stats.topService.LoaiDichVu}</span>
                                    <span className="service-revenue">{formatCurrency(stats.topService.TongDoanhThu)}</span>
                                </div>
                            </div>
                        )}
                    </div>
                )}

                {/* DOANH THU */}
                {activeTab === 'revenue' && (
                    <div className="revenue-section">
                        <h2>💰 Thống kê Doanh thu</h2>
                        
                        {/* Doanh thu sản phẩm */}
                        <div className="stat-box">
                            <h3>📦 Doanh thu Sản phẩm</h3>
                            <div className="filter-row">
                                <input type="date" value={filters.tuNgay} onChange={(e) => setFilters({...filters, tuNgay: e.target.value})} />
                                <input type="date" value={filters.denNgay} onChange={(e) => setFilters({...filters, denNgay: e.target.value})} />
                                <button onClick={loadProductRevenue}>🔍 Xem</button>
                            </div>
                            <table className="stat-table">
                                <thead>
                                    <tr>
                                        <th>Mã</th>
                                        <th>Tên sản phẩm</th>
                                        <th>Số lượng bán</th>
                                        <th>Tổng doanh thu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {stats.productRevenue.map((item, idx) => (
                                        <tr key={idx}>
                                            <td>{item.MaMatHang}</td>
                                            <td>{item.TenMatHang}</td>
                                            <td>{item.TongSoLuongBan}</td>
                                            <td>{formatCurrency(item.TongDoanhThu)}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        {/* Doanh thu chi nhánh */}
                        <div className="stat-box">
                            <h3>🏢 Doanh thu Chi nhánh</h3>
                            <div className="filter-row">
                                <select value={filters.thang} onChange={(e) => setFilters({...filters, thang: e.target.value})}>
                                    {[...Array(12)].map((_, i) => (
                                        <option key={i+1} value={i+1}>Tháng {i+1}</option>
                                    ))}
                                </select>
                                <input type="number" value={filters.nam} onChange={(e) => setFilters({...filters, nam: e.target.value})} />
                                <button onClick={loadBranchRevenue}>🔍 Xem</button>
                            </div>
                            <table className="stat-table">
                                <thead>
                                    <tr>
                                        <th>Chi nhánh</th>
                                        <th>DT Offline</th>
                                        <th>DT Online</th>
                                        <th>Tổng cộng</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {stats.branchRevenue.map((item, idx) => (
                                        <tr key={idx}>
                                            <td>{item.TenCN}</td>
                                            <td>{formatCurrency(item.DoanhThuOffline)}</td>
                                            <td>{formatCurrency(item.DoanhThuOnline)}</td>
                                            <td><strong>{formatCurrency(item.TongCong)}</strong></td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}

                {/* ĐÁNH GIÁ */}
                {activeTab === 'rating' && (
                    <div className="rating-section">
                        <h2>⭐ Thống kê Đánh giá</h2>
                        
                        <div className="filter-row">
                            <label>Điểm sàn:</label>
                            <input 
                                type="number" 
                                step="0.1" 
                                min="0" 
                                max="5" 
                                value={filters.diemSan} 
                                onChange={(e) => setFilters({...filters, diemSan: e.target.value})} 
                            />
                        </div>

                        {/* Top nhân viên */}
                        <div className="stat-box">
                            <h3>👥 Nhân viên xuất sắc (Điểm >= {filters.diemSan})</h3>
                            <button onClick={loadTopEmployees}>🔍 Xem</button>
                            <table className="stat-table">
                                <thead>
                                    <tr>
                                        <th>Mã NV</th>
                                        <th>Họ tên</th>
                                        <th>Chi nhánh</th>
                                        <th>Điểm TB</th>
                                        <th>Số lượt đánh giá</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {stats.topEmployees.map((item, idx) => (
                                        <tr key={idx}>
                                            <td>{item.MaNV}</td>
                                            <td>{item.HoTen}</td>
                                            <td>{item.TenCN}</td>
                                            <td><span className="rating-badge">{parseFloat(item.DiemTrungBinh).toFixed(2)} ⭐</span></td>
                                            <td>{item.SoLuotDanhGia}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        {/* Top sản phẩm */}
                        <div className="stat-box">
                            <h3>📦 Sản phẩm chất lượng cao (Điểm >= {filters.diemSan})</h3>
                            <button onClick={loadTopProducts}>🔍 Xem</button>
                            <table className="stat-table">
                                <thead>
                                    <tr>
                                        <th>Mã SP</th>
                                        <th>Tên sản phẩm</th>
                                        <th>Điểm TB</th>
                                        <th>Số lượt đánh giá</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {stats.topProducts.map((item, idx) => (
                                        <tr key={idx}>
                                            <td>{item.MaMatHang}</td>
                                            <td>{item.TenMatHang}</td>
                                            <td><span className="rating-badge">{parseFloat(item.DiemTrungBinh).toFixed(2)} ⭐</span></td>
                                            <td>{item.SoLuotDanhGia}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}

                {/* KHO HÀNG */}
                {activeTab === 'stock' && (
                    <div className="stock-section">
                        <h2>📦 Quản lý Kho hàng</h2>
                        
                        <div className="stock-grid">
                            {/* Cảnh báo hết hàng */}
                            <div className="stat-box">
                                <h3>⚠️ Cảnh báo hết hàng</h3>
                                <div className="filter-row">
                                    <label>Ngưỡng cảnh báo:</label>
                                    <input 
                                        type="number" 
                                        value={filters.nguongCanhBao} 
                                        onChange={(e) => setFilters({...filters, nguongCanhBao: e.target.value})} 
                                    />
                                    <button onClick={loadLowStock}>🔍 Xem</button>
                                </div>
                                <table className="stat-table">
                                    <thead>
                                        <tr>
                                            <th>Mã</th>
                                            <th>Tên mặt hàng</th>
                                            <th>Loại</th>
                                            <th>Tồn kho</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {stats.lowStock.map((item, idx) => (
                                            <tr key={idx} className={item.SoLuongTon === 0 ? 'out-of-stock' : 'low-stock'}>
                                                <td>{item.MaMatHang}</td>
                                                <td>{item.TenMatHang}</td>
                                                <td>{item.LoaiMH}</td>
                                                <td><strong>{item.SoLuongTon}</strong></td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>

                            {/* Nhập hàng */}
                            <div className="form-box">
                                <h3>📥 Nhập hàng vào kho</h3>
                                <form onSubmit={handleImportStock}>
                                    <label>Chọn mặt hàng:</label>
                                    <select 
                                        value={stockData.MaMatHang} 
                                        onChange={(e) => setStockData({...stockData, MaMatHang: e.target.value})}
                                        required
                                    >
                                        <option value="">-- Chọn mặt hàng --</option>
                                        {products.map(p => (
                                            <option key={p.MaMatHang} value={p.MaMatHang}>
                                                {p.TenMatHang} ({p.LoaiMH})
                                            </option>
                                        ))}
                                    </select>

                                    <label>Số lượng nhập:</label>
                                    <input 
                                        type="number" 
                                        value={stockData.SoLuongNhap}
                                        onChange={(e) => setStockData({...stockData, SoLuongNhap: e.target.value})}
                                        min="1"
                                        required
                                    />

                                    <button type="submit" className="btn-primary">📥 Nhập hàng</button>
                                </form>
                            </div>

                            {/* Thêm mặt hàng mới */}
                            <div className="form-box">
                                <h3>➕ Thêm mặt hàng mới</h3>
                                <form onSubmit={handleAddProduct}>
                                    <label>Tên mặt hàng:</label>
                                    <input 
                                        type="text" 
                                        value={newProductData.TenMatHang}
                                        onChange={(e) => setNewProductData({...newProductData, TenMatHang: e.target.value})}
                                        required
                                    />

                                    <label>Hãng sản xuất:</label>
                                    <input 
                                        type="text" 
                                        value={newProductData.HangSX}
                                        onChange={(e) => setNewProductData({...newProductData, HangSX: e.target.value})}
                                        required
                                    />

                                    <div className="form-row">
                                        <div>
                                            <label>Ngày SX:</label>
                                            <input 
                                                type="date" 
                                                value={newProductData.NgaySanXuat}
                                                onChange={(e) => setNewProductData({...newProductData, NgaySanXuat: e.target.value})}
                                                required
                                            />
                                        </div>
                                        <div>
                                            <label>Ngày hết hạn:</label>
                                            <input 
                                                type="date" 
                                                value={newProductData.NgayHetHan}
                                                onChange={(e) => setNewProductData({...newProductData, NgayHetHan: e.target.value})}
                                                required
                                            />
                                        </div>
                                    </div>

                                    <label>Đơn giá:</label>
                                    <input 
                                        type="number" 
                                        value={newProductData.DonGia}
                                        onChange={(e) => setNewProductData({...newProductData, DonGia: e.target.value})}
                                        min="0"
                                        required
                                    />

                                    <label>Loại mặt hàng:</label>
                                    <select 
                                        value={newProductData.LoaiMH}
                                        onChange={(e) => setNewProductData({...newProductData, LoaiMH: e.target.value})}
                                    >
                                        <option value="T">Thuốc</option>
                                        <option value="VC">Vaccine</option>
                                        <option value="SPK">Sản phẩm khác</option>
                                    </select>

                                    {newProductData.LoaiMH === 'SPK' && (
                                        <>
                                            <label>Loại sản phẩm:</label>
                                            <select 
                                                value={newProductData.LoaiSP}
                                                onChange={(e) => setNewProductData({...newProductData, LoaiSP: e.target.value})}
                                            >
                                                <option value="Đồ chơi">Đồ chơi</option>
                                                <option value="Phụ kiện">Phụ kiện</option>
                                                <option value="Thức ăn">Thức ăn</option>
                                                <option value="Quần áo">Quần áo</option>
                                            </select>
                                        </>
                                    )}

                                    <button type="submit" className="btn-primary">➕ Thêm mặt hàng</button>
                                </form>
                            </div>
                        </div>
                    </div>
                )}

                {/* NHÂN SỰ */}
                {/* NHÂN SỰ (GIAO DIỆN MỚI: SPLIT VIEW) */}
                {activeTab === 'employee' && (
                    <div className="employee-section">
                        <h2 style={{ marginBottom: '20px' }}>👥 Điều động & Luân chuyển Nhân sự</h2>

                        <div className="transfer-container">
                            {/* CỘT TRÁI: DANH SÁCH NHÂN VIÊN */}
                            <div className="employee-list-panel">
                                <div className="search-box">
                                    <input 
                                        type="text" 
                                        placeholder="🔍 Tìm kiếm theo tên hoặc mã nhân viên..." 
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                    />
                                </div>
                                
                                <div className="employee-list-scroll">
                                    {employees
                                        .filter(emp => 
                                            emp.HoTen.toLowerCase().includes(searchTerm.toLowerCase()) || 
                                            emp.MaNV.toString().includes(searchTerm)
                                        )
                                        .map(emp => (
                                            <div 
                                                key={emp.MaNV} 
                                                className={`employee-card ${transferData.MaNV === emp.MaNV ? 'active' : ''}`}
                                                onClick={() => setTransferData({ ...transferData, MaNV: emp.MaNV })}
                                            >
                                                <div className="emp-avatar">
                                                    {emp.HoTen.charAt(0)} {/* Lấy chữ cái đầu làm avatar */}
                                                </div>
                                                <div className="emp-info">
                                                    <h4>{emp.HoTen} <span style={{fontSize:'12px', color:'#999', fontWeight:'normal'}}>#{emp.MaNV}</span></h4>
                                                    <p>💼 {emp.Chucvu}</p>
                                                    <p>📍 {emp.TenCN}</p>
                                                </div>
                                                {transferData.MaNV === emp.MaNV && (
                                                    <div style={{marginLeft: 'auto', color: '#667eea', fontSize: '20px'}}>✔</div>
                                                )}
                                            </div>
                                        ))
                                    }
                                    {employees.length === 0 && (
                                        <p style={{textAlign:'center', color:'#999', marginTop: '20px'}}>Đang tải danh sách...</p>
                                    )}
                                </div>
                            </div>

            {/* CỘT PHẢI: FORM ĐIỀU ĐỘNG */}
            <div className="transfer-form-panel">
                {transferData.MaNV ? (
                    <>
                        {/* Banner hiển thị người đang được chọn */}
                        <div className="selected-user-banner">
                            <div style={{fontSize: '35px'}}>📝</div>
                            <div className="selected-user-info">
                                <h3>Đang điều động: {employees.find(e => e.MaNV === transferData.MaNV)?.HoTen}</h3>
                                <p>Chức vụ: {employees.find(e => e.MaNV === transferData.MaNV)?.Chucvu}</p>
                                <p>Từ chi nhánh: <strong>{employees.find(e => e.MaNV === transferData.MaNV)?.TenCN}</strong></p>
                            </div>
                        </div>

                        <form onSubmit={handleTransferEmployee}>
                            <label>Chuyển đến Chi nhánh mới:</label>
                            <select 
                                value={transferData.MaCN_Moi}
                                onChange={(e) => setTransferData({...transferData, MaCN_Moi: e.target.value})}
                                required
                                style={{marginBottom: '20px'}}
                            >
                                <option value="">-- Chọn chi nhánh đích --</option>
                                {branches.map(branch => (
                                    <option key={branch.MaCN} value={branch.MaCN}>
                                        🏢 {branch.TenCN}
                                    </option>
                                ))}
                            </select>

                            {/* Gom Ngày Bắt Đầu và Ngày Kết Thúc cùng 1 hàng cho gọn */}
                            <div className="form-grid-row">
                                <div>
                                    <label>Ngày bắt đầu:</label>
                                    <input 
                                        type="date" 
                                        value={transferData.NgayBD}
                                        onChange={(e) => setTransferData({...transferData, NgayBD: e.target.value})}
                                        required
                                    />
                                </div>
                                <div>
                                    <label>Ngày kết thúc:</label>
                                    <input 
                                        type="date" 
                                        value={transferData.NgayKT}
                                        onChange={(e) => setTransferData({...transferData, NgayKT: e.target.value})}
                                        required
                                    />
                                </div>
                            </div>

                            <label style={{marginTop: '10px'}}>Ghi chú / Lý do:</label>
                            <textarea 
                                value={transferData.GhiChu}
                                onChange={(e) => setTransferData({...transferData, GhiChu: e.target.value})}
                                rows="4"
                                placeholder="Nhập lý do điều động..."
                                style={{resize: 'none', marginBottom: '20px'}}
                            />

                            <button type="submit" className="btn-primary" style={{width: '100%', padding: '14px', fontSize: '16px'}}>
                                🚀 Xác nhận Điều động
                            </button>
                        </form>
                    </>
                ) : (
                    <div className="empty-state">
                        <div style={{fontSize: '50px', marginBottom: '15px'}}>👈</div>
                        <h3>Vui lòng chọn nhân viên</h3>
                        <p>Chọn một nhân viên từ danh sách bên trái để tiến hành điều động công tác.</p>
                    </div>
                )}
            </div>
        </div>
    </div>
)}

                {/* HỘI VIÊN */}
                {activeTab === 'membership' && (
                    <div className="membership-section">
                        <h2>🎖️ Quản lý Hội viên</h2>
                        
                        <div className="stat-box">
                            <h3>📊 Thống kê hội viên</h3>
                            <div className="filter-row">
                                <label>Năm:</label>
                                <input 
                                    type="number" 
                                    value={filters.nam}
                                    onChange={(e) => setFilters({...filters, nam: e.target.value})}
                                />
                                <button onClick={loadMembershipStats}>🔍 Xem</button>
                            </div>
                            <table className="stat-table">
                                <thead>
                                    <tr>
                                        <th>Hạng</th>
                                        <th>% Giảm giá</th>
                                        <th>Số lượng khách</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {stats.membershipStats.map((item, idx) => (
                                        <tr key={idx}>
                                            <td><strong>{item.TenHang}</strong></td>
                                            <td>{item.PhanTramGiamGia}%</td>
                                            <td>{item.SoLuongKhach}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        <div className="admin-action">
                            <h3>⚠️ Cập nhật xếp hạng (Chỉ dành Admin - 31/12)</h3>
                            <p>Chức năng này chỉ được phép chạy vào ngày 31/12 hàng năm để chốt sổ xếp hạng.</p>
                            <button onClick={handleUpdateRanking} className="btn-danger">
                                🔄 Cập nhật xếp hạng năm {filters.nam}
                            </button>
                        </div>
                    </div>
                )}

            </div>
        </div>
    );
};

export default ManagerDashboard;
