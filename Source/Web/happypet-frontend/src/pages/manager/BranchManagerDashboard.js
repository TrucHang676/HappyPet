import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './BranchManagerDashboard.css';

const BranchManagerDashboard = () => {
    const [activeTab, setActiveTab] = useState('overview');
    const [revenue, setRevenue] = useState(null);
    const [employees, setEmployees] = useState([]);
    const [inventory, setInventory] = useState([]);
    const [stats, setStats] = useState({});
    
    // Stats tab data
    const [productRevenue, setProductRevenue] = useState([]);
    const [topEmployees, setTopEmployees] = useState([]);
    const [topService, setTopService] = useState(null);
    const [memberStats, setMemberStats] = useState(null);
    
    // Filters cho stats
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [diemSan, setDiemSan] = useState(4.0);
    const [nguongCanhBao, setNguongCanhBao] = useState(10);
    const [year, setYear] = useState(new Date().getFullYear());
    
    // Filters cho overview revenue
    const [revenueMonth, setRevenueMonth] = useState(new Date().getMonth() + 1);
    const [revenueYear, setRevenueYear] = useState(new Date().getFullYear());
    
    // State cho nhập hàng
    const [selectedProduct, setSelectedProduct] = useState('');
    const [importQuantity, setImportQuantity] = useState(1);
    
    const token = localStorage.getItem('token');
    const config = { headers: { Authorization: `Bearer ${token}` } };
    
    // Load doanh thu
    const loadRevenue = () => {
        axios.get(`https://happy-pet-fomc.onrender.com/api/branch-manager/revenue?loaiThongKe=THANG&nam=${revenueYear}&thang=${revenueMonth}`, config)
            .then(res => setRevenue(res.data))
            .catch(err => console.error(err));
    };
    
    useEffect(() => {
        loadRevenue();
    }, []);
    
    // Load nhân viên
    const loadEmployees = () => {
        axios.get('https://happy-pet-fomc.onrender.com/api/branch-manager/employees', config)
            .then(res => setEmployees(res.data))
            .catch(err => console.error(err));
    };
    
    // Load tồn kho cảnh báo
    const loadInventory = () => {
        axios.get(`https://happy-pet-fomc.onrender.com/api/branch-manager/inventory/alert?nguongCanhBao=${nguongCanhBao}`, config)
            .then(res => setInventory(res.data))
            .catch(err => console.error(err));
    };
    
    // Xử lý nhập hàng
    const handleImportStock = async () => {
        if (!selectedProduct) {
            alert('Vui lòng chọn mặt hàng!');
            return;
        }
        if (!importQuantity || importQuantity <= 0) {
            alert('Số lượng phải lớn hơn 0!');
            return;
        }
        
        try {
            await axios.post('https://happy-pet-fomc.onrender.com/api/branch-manager/inventory/import', {
                maMatHang: selectedProduct,
                soLuongNhap: importQuantity
            }, config);
            
            alert('Nhập hàng thành công!');
            setSelectedProduct('');
            setImportQuantity(1);
            loadInventory(); // Reload inventory
        } catch (err) {
            console.error(err);
            alert(err.response?.data?.message || 'Lỗi nhập hàng!');
        }
    };
    
    // Load thống kê sản phẩm
    const loadProductRevenue = () => {
        const params = new URLSearchParams();
        if (dateFrom) params.append('tuNgay', dateFrom);
        if (dateTo) params.append('denNgay', dateTo);
        
        axios.get(`https://happy-pet-fomc.onrender.com/api/branch-manager/revenue/products?${params}`, config)
            .then(res => {
                console.log('Product revenue data:', res.data);
                setProductRevenue(res.data);
            })
            .catch(err => console.error(err));
    };
    
    // Load nhân viên xuất sắc
    const loadTopEmployees = () => {
        axios.get(`https://happy-pet-fomc.onrender.com/api/branch-manager/employees/top-rated?diemSan=${diemSan}`, config)
            .then(res => {
                console.log('Top employees data:', res.data);
                setTopEmployees(res.data);
            })
            .catch(err => console.error(err));
    };
    
    // Load dịch vụ doanh thu cao nhất
    const loadTopService = () => {
        axios.get('https://happy-pet-fomc.onrender.com/api/branch-manager/service/top-revenue', config)
            .then(res => {
                console.log('Top service data:', res.data);
                setTopService(res.data);
            })
            .catch(err => console.error(err));
    };
    
    // Load thống kê hội viên
    const loadMemberStats = () => {
        axios.get(`https://happy-pet-fomc.onrender.com/api/branch-manager/members/stats?nam=${year}`, config)
            .then(res => {
                console.log('Member stats data:', res.data);
                setMemberStats(res.data);
            })
            .catch(err => console.error(err));
    };
    
    useEffect(() => {
        if (activeTab === 'employees') loadEmployees();
        if (activeTab === 'inventory') loadInventory();
        if (activeTab === 'stats') {
            loadProductRevenue();
            loadTopEmployees();
            loadTopService();
            loadMemberStats();
        }
    }, [activeTab]);
    
    return (
        <div className="branch-manager-container">
            <h1 className="dashboard-title">📊 Quản Lý Chi Nhánh</h1>
            
            {/* Navigation Tabs */}
            <div className="tab-navigation">
                <button onClick={() => setActiveTab('overview')} className={activeTab === 'overview' ? 'tab-active' : ''}>
                    📈 Tổng quan
                </button>
                <button onClick={() => setActiveTab('employees')} className={activeTab === 'employees' ? 'tab-active' : ''}>
                    👥 Nhân viên
                </button>
                <button onClick={() => setActiveTab('inventory')} className={activeTab === 'inventory' ? 'tab-active' : ''}>
                    📦 Tồn kho
                </button>
                <button onClick={() => setActiveTab('stats')} className={activeTab === 'stats' ? 'tab-active' : ''}>
                    📊 Thống kê
                </button>
            </div>
            
            {/* Tab Content */}
            <div className="tab-content">
                {activeTab === 'overview' && (
                    <div className="overview-section">
                        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px'}}>
                            <h2>Doanh thu chi nhánh</h2>
                            <div>
                                <label>Tháng: </label>
                                <input 
                                    type="number" 
                                    min="1" 
                                    max="12" 
                                    value={revenueMonth} 
                                    onChange={(e) => setRevenueMonth(e.target.value)}
                                    style={{width: '60px', marginLeft: '10px'}}
                                />
                                <label style={{marginLeft: '15px'}}>Năm: </label>
                                <input 
                                    type="number" 
                                    value={revenueYear} 
                                    onChange={(e) => setRevenueYear(e.target.value)}
                                    style={{width: '80px', marginLeft: '10px'}}
                                />
                                <button onClick={loadRevenue} className="btn-primary" style={{marginLeft: '15px'}}>Xem</button>
                            </div>
                        </div>
                        {revenue && (
                            <div className="revenue-cards">
                                <div className="stat-card">
                                    <h3>💰 Trực tiếp</h3>
                                    <p className="stat-value">{parseInt(revenue.DoanhThuTrucTiep || 0).toLocaleString()}đ</p>
                                </div>
                                <div className="stat-card">
                                    <h3>🌐 Online</h3>
                                    <p className="stat-value">{parseInt(revenue.DoanhThuOnline || 0).toLocaleString()}đ</p>
                                </div>
                                <div className="stat-card highlight">
                                    <h3>📊 Tổng cộng</h3>
                                    <p className="stat-value">{parseInt(revenue.TongDoanhThu || 0).toLocaleString()}đ</p>
                                </div>
                            </div>
                        )}
                        
                        <div className="quick-stats">
                            <div className="quick-card">
                                <h4>👥 Nhân viên</h4>
                                <p>{employees.length || '...'}</p>
                            </div>
                            <div className="quick-card alert">
                                <h4>⚠️ Cảnh báo tồn kho</h4>
                                <p>{inventory.length || 0} sản phẩm</p>
                            </div>
                        </div>
                    </div>
                )}
                
                {activeTab === 'employees' && (
                    <div className="employees-section">
                        <h2>Danh sách nhân viên</h2>
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Mã NV</th>
                                    <th>Họ tên</th>
                                    <th>Chức vụ</th>
                                    <th>Lương cơ bản</th>
                                    <th>Ngày vào làm</th>
                                </tr>
                            </thead>
                            <tbody>
                                {employees.map(emp => (
                                    <tr key={emp.MaNV}>
                                        <td>{emp.MaNV}</td>
                                        <td>{emp.HoTen}</td>
                                        <td>{emp.ChucVu}</td>
                                        <td>{parseInt(emp.LuongCoBan).toLocaleString()}đ</td>
                                        <td>{new Date(emp.NgayVaoLam).toLocaleDateString('vi-VN')}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
                
                {activeTab === 'inventory' && (
                    <div className="inventory-section">
                        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px'}}>
                            <h2>⚠️ Sản phẩm sắp hết hàng</h2>
                            <div>
                                <label>Ngưỡng cảnh báo: </label>
                                <input 
                                    type="number" 
                                    value={nguongCanhBao} 
                                    onChange={(e) => setNguongCanhBao(e.target.value)}
                                    style={{width: '80px', marginLeft: '10px', marginRight: '10px'}}
                                />
                                <button onClick={loadInventory} className="btn-primary">Tìm kiếm</button>
                            </div>
                        </div>
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Mã MH</th>
                                    <th>Tên mặt hàng</th>
                                    <th>Loại</th>
                                    <th>Tồn kho</th>
                                </tr>
                            </thead>
                            <tbody>
                                {inventory.map(item => (
                                    <tr key={item.MaMatHang} className={item.SoLuongTon === 0 ? 'out-of-stock' : ''}>
                                        <td>{item.MaMatHang}</td>
                                        <td>{item.TenMatHang}</td>
                                        <td>{item.LoaiMH}</td>
                                        <td className="stock-qty">{item.SoLuongTon}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                        
                        {/* Nhập hàng vào kho */}
                        <div className="stats-block" style={{marginTop: '40px', paddingTop: '30px', borderTop: '2px solid #e9ecef'}}>
                            <h3>📦 Nhập hàng vào kho</h3>
                            <div style={{display: 'flex', gap: '15px', alignItems: 'flex-end', marginTop: '20px', flexWrap: 'wrap'}}>
                                <div style={{flex: 1, minWidth: '300px'}}>
                                    <label style={{display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500'}}>Chọn mặt hàng:</label>
                                    <select 
                                        value={selectedProduct} 
                                        onChange={(e) => setSelectedProduct(e.target.value)}
                                        style={{
                                            width: '100%',
                                            padding: '10px 12px',
                                            border: '1px solid #ddd',
                                            borderRadius: '6px',
                                            fontSize: '14px'
                                        }}
                                    >
                                        <option value="">-- Chọn mặt hàng --</option>
                                        {inventory.map(item => (
                                            <option key={item.MaMatHang} value={item.MaMatHang}>
                                                {item.MaMatHang} - {item.TenMatHang} (Tồn: {item.SoLuongTon})
                                            </option>
                                        ))}
                                    </select>
                                </div>
                                
                                <div style={{width: '150px'}}>
                                    <label style={{display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500'}}>Số lượng nhập:</label>
                                    <input 
                                        type="number" 
                                        min="1"
                                        value={importQuantity} 
                                        onChange={(e) => setImportQuantity(parseInt(e.target.value) || 1)}
                                        style={{
                                            width: '100%',
                                            padding: '10px 12px',
                                            border: '1px solid #ddd',
                                            borderRadius: '6px',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                                
                                <button 
                                    onClick={handleImportStock}
                                    className="btn-primary" 
                                    style={{
                                        padding: '10px 30px',
                                        fontSize: '15px'
                                    }}
                                >
                                    📦 Nhập hàng
                                </button>
                            </div>
                        </div>
                    </div>
                )}
                
                {activeTab === 'stats' && (
                    <div className="stats-section">
                        <h2>📊 Thống kê chi nhánh</h2>
                        
                        {/* Doanh thu sản phẩm */}
                        <div className="stats-block">
                            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                                <h3>💰 Doanh thu sản phẩm</h3>
                                <div>
                                    <label>Từ ngày: </label>
                                    <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
                                    <label style={{marginLeft: '15px'}}>Đến ngày: </label>
                                    <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
                                    <button onClick={loadProductRevenue} className="btn-primary" style={{marginLeft: '15px'}}>Xem</button>
                                </div>
                            </div>
                            <table className="data-table" style={{marginTop: '15px'}}>
                                <thead>
                                    <tr>
                                        <th>STT</th>
                                        <th>Mã SP</th>
                                        <th>Tên sản phẩm</th>
                                        <th>Số lượng bán</th>
                                        <th>Doanh thu</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {productRevenue.map((item, idx) => (
                                        <tr key={item.MaMatHang}>
                                            <td>{idx + 1}</td>
                                            <td>{item.MaMatHang}</td>
                                            <td>{item.TenMatHang}</td>
                                            <td>{item.TongSoLuongBan || 0}</td>
                                            <td>{parseInt(item.TongDoanhThu || 0).toLocaleString()}đ</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                        
                        {/* Nhân viên xuất sắc */}
                        <div className="stats-block" style={{marginTop: '30px'}}>
                            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                                <h3>⭐ Nhân viên xuất sắc</h3>
                                <div>
                                    <label>Điểm sàn: </label>
                                    <input 
                                        type="number" 
                                        step="0.1" 
                                        value={diemSan} 
                                        onChange={(e) => setDiemSan(e.target.value)}
                                        style={{width: '80px', marginLeft: '10px'}}
                                    />
                                    <button onClick={loadTopEmployees} className="btn-primary" style={{marginLeft: '15px'}}>Xem</button>
                                </div>
                            </div>
                            <table className="data-table" style={{marginTop: '15px'}}>
                                <thead>
                                    <tr>
                                        <th>STT</th>
                                        <th>Mã NV</th>
                                        <th>Họ tên</th>
                                        <th>Điểm TB</th>
                                        <th>Số đánh giá</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {topEmployees.map((emp, idx) => (
                                        <tr key={emp.MaNV}>
                                            <td>{idx + 1}</td>
                                            <td>{emp.MaNV}</td>
                                            <td>{emp.HoTen}</td>
                                            <td><span style={{color: '#28a745', fontWeight: 'bold'}}>{parseFloat(emp.DiemTrungBinh || 0).toFixed(2)}</span></td>
                                            <td>{emp.SoLuotDanhGia || 0}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                        
                        {/* Dịch vụ top doanh thu */}
                        <div className="stats-block" style={{marginTop: '30px'}}>
                            <h3>🏆 Dịch vụ doanh thu cao nhất</h3>
                            {topService && topService.LoaiDichVu ? (
                                <div className="stat-card highlight" style={{marginTop: '15px', padding: '20px'}}>
                                    <h4 style={{marginBottom: '10px'}}>{topService.LoaiDichVu}</h4>
                                    <p style={{fontSize: '14px', color: '#666'}}>Thống kê 6 tháng gần đây</p>
                                    <p style={{fontSize: '24px', fontWeight: 'bold', color: '#28a745', marginTop: '10px'}}>
                                        {parseInt(topService.TongDoanhThu || 0).toLocaleString()}đ
                                    </p>
                                </div>
                            ) : (
                                <p style={{marginTop: '15px', color: '#999', fontStyle: 'italic'}}>Chưa có dữ liệu dịch vụ</p>
                            )}
                        </div>
                        
                        {/* Thống kê hội viên */}
                        <div className="stats-block" style={{marginTop: '30px'}}>
                            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                                <h3>👥 Thống kê hội viên theo cấp</h3>
                                <div>
                                    <label>Năm: </label>
                                    <input 
                                        type="number" 
                                        value={year} 
                                        onChange={(e) => setYear(e.target.value)}
                                        style={{width: '100px', marginLeft: '10px'}}
                                    />
                                    <button onClick={loadMemberStats} className="btn-primary" style={{marginLeft: '15px'}}>Xem</button>
                                </div>
                            </div>
                            {memberStats && Array.isArray(memberStats) && memberStats.length > 0 && (
                                <div className="revenue-cards" style={{marginTop: '15px'}}>
                                    {memberStats.map((tier, idx) => (
                                        <div key={idx} className={idx === memberStats.length - 1 ? "stat-card highlight" : "stat-card"}>
                                            <h4>
                                                {idx === 0 && '🥉'} 
                                                {idx === 1 && '🥈'} 
                                                {idx === 2 && '🥇'}
                                                {' '}{tier.TenHang}
                                            </h4>
                                            <p className="stat-value">{tier.SoLuongKhach || 0} khách</p>
                                            <p style={{fontSize: '14px', marginTop: '8px'}}>Giảm giá: {tier.PhanTramGiamGia}%</p>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default BranchManagerDashboard;
