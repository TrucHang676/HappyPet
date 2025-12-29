import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import dayjs from 'dayjs';
import './Doctor.css';

const DoctorDashboard = () => {
    const [waitingList, setWaitingList] = useState([]);
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const fetchWaitingList = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get('http://localhost:5000/api/doctor/waiting-list', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setWaitingList(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchWaitingList();
    }, []);

    return (
        <div className="doctor-dashboard">
            <div className="dashboard-header">
                <h2>🩺 Danh Sách Bệnh Nhân Chờ Khám</h2>
                <button className="btn-refresh" onClick={fetchWaitingList}>
                    🔄 Làm mới
                </button>
            </div>

            {loading ? (
                <div className="loading-container">
                    <div className="spinner">⏳</div>
                    <p>Đang tải danh sách...</p>
                </div>
            ) : waitingList.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">🏥</div>
                    <h3>Không có bệnh nhân chờ khám</h3>
                    <p>Danh sách đang trống. Hãy thư giãn hoặc kiểm tra lịch hẹn.</p>
                </div>
            ) : (
                <div className="patient-grid">
                    {waitingList.map(item => (
                        <div key={item.MaPhieu} className="patient-card">
                            <div className="card-header">
                                <div className="pet-info">
                                    <h3>🐾 {item.TenThuCung}</h3>
                                    <span className="pet-breed">{item.LoaiThuCung} • {item.GiongThuCung}</span>
                                </div>
                                <span className="status-badge waiting">Chờ khám</span>
                            </div>
                            
                            <div className="card-body">
                                <div className="info-row">
                                    <span className="label">👤 Chủ nuôi:</span>
                                    <span className="value">{item.TenKhachHang}</span>
                                </div>
                                <div className="info-row">
                                    <span className="label">🕒 Thời gian:</span>
                                    <span className="value">{dayjs(item.TG_LapPhieu).format('HH:mm - DD/MM/YYYY')}</span>
                                </div>
                                <div className="info-row">
                                    <span className="label">🆔 Mã phiếu:</span>
                                    <span className="value">#{item.MaPhieu}</span>
                                </div>
                            </div>

                            <div className="card-footer">
                                <button 
                                    className="btn-start-exam" 
                                    onClick={() => navigate(`/doctor/exam/${item.MaPhieu}`)}
                                >
                                    🩺 Bắt đầu khám
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default DoctorDashboard;