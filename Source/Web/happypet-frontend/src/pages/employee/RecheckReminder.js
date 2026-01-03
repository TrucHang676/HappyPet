import React, { useState, useEffect } from 'react';
import axios from 'axios';
import dayjs from 'dayjs';
import './EmployeeDashboard.css';

const RecheckReminder = () => {
    const [recheckList, setRecheckList] = useState([]);
    const [loading, setLoading] = useState(false);
    const [timeRange, setTimeRange] = useState('week'); // week, month, all

    const getDateRange = () => {
        const today = dayjs();
        let start, end;

        switch (timeRange) {
            case 'week':
                start = today;
                end = today.add(7, 'day');
                break;
            case 'month':
                start = today;
                end = today.add(30, 'day');
                break;
            case 'all':
                start = today;
                end = today.add(365, 'day'); // 1 năm
                break;
            default:
                start = today;
                end = today.add(7, 'day');
        }

        return {
            tuNgay: start.format('YYYY-MM-DD'),
            denNgay: end.format('YYYY-MM-DD')
        };
    };

    const fetchRecheckList = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const { tuNgay, denNgay } = getDateRange();

            const res = await axios.get('http://localhost:5000/api/employee/recheck-appointments', {
                headers: { Authorization: `Bearer ${token}` },
                params: { tuNgay, denNgay }
            });

            setRecheckList(res.data);
        } catch (error) {
            console.error('Lỗi lấy danh sách tái khám:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchRecheckList();
    }, [timeRange]);

    const getUrgencyBadge = (daysLeft) => {
        if (daysLeft < 0) {
            return <span style={{color: '#d32f2f', fontWeight: 'bold'}}>⚠️ Đã quá hạn {Math.abs(daysLeft)} ngày</span>;
        } else if (daysLeft === 0) {
            return <span style={{color: '#f57c00', fontWeight: 'bold'}}>🔥 Hôm nay</span>;
        } else if (daysLeft <= 3) {
            return <span style={{color: '#ff9800', fontWeight: 'bold'}}>⏰ Còn {daysLeft} ngày</span>;
        } else if (daysLeft <= 7) {
            return <span style={{color: '#ffa726'}}>📅 Còn {daysLeft} ngày</span>;
        } else {
            return <span style={{color: '#66bb6a'}}>🗓️ Còn {daysLeft} ngày</span>;
        }
    };

    return (
        <div className="dashboard-container">
            <div>
                <h2 className="dashboard-title">🔔 Nhắc Nhở Tái Khám</h2>
                <p className="dashboard-subtitle">Danh sách khách hàng có lịch hẹn tái khám sắp tới</p>
            </div>

            {/* TABS THỜI GIAN */}
            <div className="tabs-container" style={{marginBottom: '20px'}}>
                <button 
                    className={`tab-btn ${timeRange === 'week' ? 'active' : ''}`} 
                    onClick={() => setTimeRange('week')}
                >
                    📅 7 ngày tới
                </button>
                <button 
                    className={`tab-btn ${timeRange === 'month' ? 'active' : ''}`} 
                    onClick={() => setTimeRange('month')}
                >
                    🗓️ 30 ngày tới
                </button>
                <button 
                    className={`tab-btn ${timeRange === 'all' ? 'active' : ''}`} 
                    onClick={() => setTimeRange('all')}
                >
                    📆 Tất cả
                </button>
            </div>

            {/* BẢNG DỮ LIỆU */}
            <div className="table-card">
                <table className="booking-table">
                    <thead>
                        <tr>
                            <th>Mã phiếu</th>
                            <th>Khách hàng</th>
                            <th>Thú cưng</th>
                            <th>Ngày khám trước</th>
                            <th>Chẩn đoán</th>
                            <th>Ngày hẹn tái khám</th>
                            <th>Trạng thái</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr>
                                <td colSpan="7" style={{textAlign: 'center', padding: '30px', color: '#888'}}>
                                    ⏳ Đang tải dữ liệu...
                                </td>
                            </tr>
                        ) : recheckList.length === 0 ? (
                            <tr>
                                <td colSpan="7" style={{textAlign: 'center', padding: '40px', color: '#999'}}>
                                    <div style={{fontSize: '40px', marginBottom: '10px'}}>📭</div>
                                    Không có lịch tái khám nào trong thời gian này!
                                </td>
                            </tr>
                        ) : (
                            recheckList.map((item, index) => (
                                <tr key={index} style={{
                                    background: item.SoNgayConLai < 0 ? '#ffebee' : 
                                               item.SoNgayConLai === 0 ? '#fff3e0' :
                                               item.SoNgayConLai <= 3 ? '#fff9c4' : 'white'
                                }}>
                                    <td><strong>#{item.MaPhieu}</strong></td>
                                    <td>
                                        <div style={{fontWeight: '600'}}>{item.TenKhachHang}</div>
                                        <div className="text-muted">📞 {item.SDT}</div>
                                    </td>
                                    <td>🐶 {item.TenThuCung || 'N/A'}</td>
                                    <td style={{fontSize: '0.9em', color: '#666'}}>
                                        {dayjs(item.TG_ThucHienDV).format('DD/MM/YYYY')}
                                    </td>
                                    <td style={{fontSize: '0.9em'}}>
                                        {item.ChanDoan || 'N/A'}
                                    </td>
                                    <td style={{fontWeight: 'bold', fontSize: '1em'}}>
                                        {dayjs(item.NgayHenTaiKham).format('DD/MM/YYYY')}
                                    </td>
                                    <td>
                                        {getUrgencyBadge(item.SoNgayConLai)}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* THỐNG KÊ */}
            {recheckList.length > 0 && (
                <div style={{
                    marginTop: '20px',
                    padding: '15px',
                    background: '#f5f5f5',
                    borderRadius: '8px',
                    display: 'flex',
                    gap: '20px',
                    justifyContent: 'space-around'
                }}>
                    <div style={{textAlign: 'center'}}>
                        <div style={{fontSize: '24px', fontWeight: 'bold', color: '#d32f2f'}}>
                            {recheckList.filter(x => x.SoNgayConLai < 0).length}
                        </div>
                        <div style={{fontSize: '14px', color: '#666'}}>Đã quá hạn</div>
                    </div>
                    <div style={{textAlign: 'center'}}>
                        <div style={{fontSize: '24px', fontWeight: 'bold', color: '#f57c00'}}>
                            {recheckList.filter(x => x.SoNgayConLai === 0).length}
                        </div>
                        <div style={{fontSize: '14px', color: '#666'}}>Hôm nay</div>
                    </div>
                    <div style={{textAlign: 'center'}}>
                        <div style={{fontSize: '24px', fontWeight: 'bold', color: '#ff9800'}}>
                            {recheckList.filter(x => x.SoNgayConLai > 0 && x.SoNgayConLai <= 3).length}
                        </div>
                        <div style={{fontSize: '14px', color: '#666'}}>Trong 3 ngày</div>
                    </div>
                    <div style={{textAlign: 'center'}}>
                        <div style={{fontSize: '24px', fontWeight: 'bold', color: '#4caf50'}}>
                            {recheckList.filter(x => x.SoNgayConLai > 3).length}
                        </div>
                        <div style={{fontSize: '14px', color: '#666'}}>Còn lại</div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default RecheckReminder;
