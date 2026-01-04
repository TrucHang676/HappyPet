import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './DirectorDashboard.css';

const DirectorDashboard = () => {
    const [activeTab, setActiveTab] = useState('overview');
    const [branchRevenue, setBranchRevenue] = useState([]);
    const [topService, setTopService] = useState(null);
    const [memberStats, setMemberStats] = useState([]);
    const [petStats, setPetStats] = useState([]);
    
    // Filters
    const [month, setMonth] = useState(new Date().getMonth() + 1);
    const [year, setYear] = useState(new Date().getFullYear());
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    
    const token = localStorage.getItem('token');
    const config = { headers: { Authorization: `Bearer ${token}` } };
    
    // Load doanh thu các chi nhánh
    const loadBranchRevenue = () => {
        axios.get(`https://happy-pet-fomc.onrender.com/api/director/revenue/branches?thang=${month}&nam=${year}`, config)
            .then(res => setBranchRevenue(res.data))
            .catch(err => console.error(err));
    };
    
    useEffect(() => {
        loadBranchRevenue();
    }, []);
    
    // Load top dịch vụ
    const loadTopService = () => {
        const params = new URLSearchParams();
        if (dateFrom) params.append('tuNgay', dateFrom);
        if (dateTo) params.append('denNgay', dateTo);
        
        axios.get(`https://happy-pet-fomc.onrender.com/api/director/revenue/top-service?${params}`, config)
            .then(res => setTopService(res.data))
            .catch(err => console.error(err));
    };
    
    useEffect(() => {
        loadTopService();
    }, []);
    
    // Load thống kê hội viên
    const loadMemberStats = () => {
        axios.get(`https://happy-pet-fomc.onrender.com/api/director/members/stats?nam=${year}`, config)
            .then(res => setMemberStats(res.data))
            .catch(err => console.error(err));
    };
    
    // Load thống kê thú cưng
    const loadPetStats = () => {
        axios.get('https://happy-pet-fomc.onrender.com/api/director/pets/by-type', config)
            .then(res => setPetStats(res.data))
            .catch(err => console.error(err));
    };
    
    useEffect(() => {
        if (activeTab === 'members') loadMemberStats();
        if (activeTab === 'pets') loadPetStats();
    }, [activeTab]);
    
    return (
        <div className="director-container">
            <h1 className="dashboard-title">🏢 Bảng Điều Khiển Giám Đốc</h1>
            
            {/* Navigation Tabs */}
            <div className="tab-navigation">
                <button onClick={() => setActiveTab('overview')} className={activeTab === 'overview' ? 'tab-active' : ''}>
                    📊 Tổng quan
                </button>
                <button onClick={() => setActiveTab('branches')} className={activeTab === 'branches' ? 'tab-active' : ''}>
                    🏪 Chi nhánh
                </button>
                <button onClick={() => setActiveTab('members')} className={activeTab === 'members' ? 'tab-active' : ''}>
                    👑 Hội viên
                </button>
                <button onClick={() => setActiveTab('pets')} className={activeTab === 'pets' ? 'tab-active' : ''}>
                    🐾 Thú cưng
                </button>
            </div>
            
            {/* Tab Content */}
            <div className="tab-content">
                {activeTab === 'overview' && (
                    <div className="overview-section">
                        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                            <h2>Doanh thu toàn hệ thống</h2>
                            <div>
                                <label>Tháng: </label>
                                <input 
                                    type="number" 
                                    min="1" 
                                    max="12" 
                                    value={month} 
                                    onChange={(e) => setMonth(e.target.value)}
                                    style={{width: '60px', marginLeft: '10px'}}
                                />
                                <label style={{marginLeft: '15px'}}>Năm: </label>
                                <input 
                                    type="number" 
                                    value={year} 
                                    onChange={(e) => setYear(e.target.value)}
                                    style={{width: '80px', marginLeft: '10px'}}
                                />
                                <button onClick={loadBranchRevenue} className="btn-primary" style={{marginLeft: '15px'}}>Xem</button>
                            </div>
                        </div>
                        
                        {topService && (
                            <div className="top-service-card">
                                <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                                    <h3>🏆 Dịch vụ mang lại doanh thu cao nhất</h3>
                                    <div>
                                        <label>Từ: </label>
                                        <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
                                        <label style={{marginLeft: '10px'}}>Đến: </label>
                                        <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
                                        <button onClick={loadTopService} className="btn-primary" style={{marginLeft: '10px'}}>Xem</button>
                                    </div>
                                </div>
                                <div className="service-info">
                                    <p className="service-name">{topService.LoaiDichVu}</p>
                                    <p className="service-revenue">{parseInt(topService.TongDoanhThu || 0).toLocaleString()}đ</p>
                                </div>
                            </div>
                        )}
                        
                        <h3 style={{marginTop: '30px'}}>So sánh doanh thu chi nhánh</h3>
                        <div className="branch-comparison">
                            {branchRevenue.map((branch, idx) => (
                                <div key={idx} className="branch-card">
                                    <h4>{branch.TenCN}</h4>
                                    <div className="branch-revenue">
                                        <p><span>Trực tiếp:</span> {parseInt(branch.DoanhThuOffline || 0).toLocaleString()}đ</p>
                                        <p><span>Online:</span> {parseInt(branch.DoanhThuOnline || 0).toLocaleString()}đ</p>
                                        <p className="total"><span>Tổng:</span> {parseInt(branch.TongCong || 0).toLocaleString()}đ</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
                
                {activeTab === 'branches' && (
                    <div className="branches-section">
                        <h2>Chi tiết doanh thu các chi nhánh</h2>
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Chi nhánh</th>
                                    <th>Doanh thu trực tiếp</th>
                                    <th>Doanh thu online</th>
                                    <th>Tổng cộng</th>
                                </tr>
                            </thead>
                            <tbody>
                                {branchRevenue.map((branch, idx) => (
                                    <tr key={idx}>
                                        <td><strong>{branch.TenCN}</strong></td>
                                        <td>{parseInt(branch.DoanhThuOffline || 0).toLocaleString()}đ</td>
                                        <td>{parseInt(branch.DoanhThuOnline || 0).toLocaleString()}đ</td>
                                        <td className="total-col">{parseInt(branch.TongCong || 0).toLocaleString()}đ</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
                
                {activeTab === 'members' && (
                    <div className="members-section">
                        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                            <h2>Thống kê hội viên theo hạng</h2>
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
                        <div className="member-cards">
                            {memberStats.map((tier, idx) => (
                                <div key={idx} className="member-card">
                                    <h3>{tier.TenHang}</h3>
                                    <p className="member-count">{tier.SoLuongKhach} khách hàng</p>
                                    <p className="member-discount">Ưu đãi: {tier.PhanTramGiamGia}%</p>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
                
                {activeTab === 'pets' && (
                    <div className="pets-section">
                        <h2>Thống kê thú cưng theo loại và giống</h2>
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Loại</th>
                                    <th>Giống</th>
                                    <th>Số lượng</th>
                                    <th>Số chủ nuôi</th>
                                </tr>
                            </thead>
                            <tbody>
                                {petStats.map((pet, idx) => (
                                    <tr key={idx}>
                                        <td>{pet.Loai}</td>
                                        <td>{pet.Giong}</td>
                                        <td><strong>{pet.SoLuong}</strong></td>
                                        <td>{pet.SoChuNuoi}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
};

export default DirectorDashboard;
