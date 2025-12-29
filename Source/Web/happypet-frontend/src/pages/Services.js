import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Services.css'; // Bà nhớ tạo file CSS này nhé

const Services = () => {
    const [branches, setBranches] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchBranches = async () => {
            try {
                setLoading(true);
                const response = await axios.get('http://localhost:5000/api/branches');
                setBranches(response.data);
            } catch (err) {
                console.error("Lỗi lấy chi nhánh:", err);
            } finally {
                setLoading(false);
            }
        };
        fetchBranches();
    }, []);

    if (loading) return <div className="loading">⏳ Đang tải danh sách chi nhánh...</div>;

    return (
        <div className="services-page">
            <div className="services-container-card">
                <h2 className="title">🏥 Hệ Thống Chi Nhánh & Dịch Vụ</h2>
                <p className="subtitle">Chọn chi nhánh gần bạn nhất để được phục vụ tốt nhất</p>

                <div className="branch-grid">
                    {branches.length > 0 ? branches.map((branch) => (
                        <div key={branch.MaCN} className="branch-card">
                            <div className="branch-header">
                                <h3>📍 {branch.TenCN}</h3>
                                <span className={`status-badge ${branch.TrangThaiHoatDong === 'Đang mở cửa' ? 'open' : 'closed'}`}>
                                    {branch.TrangThaiHoatDong}
                                </span>
                            </div>

                            <div className="branch-info">
                                <p>🏠 <b>Địa chỉ:</b> {branch.DiaChi}</p>
                                <p>📞 <b>Hotline:</b> {branch.SDT}</p>
                                <p>⏰ <b>Giờ làm việc:</b> {branch.GioMoCua} - {branch.GioDongCua}</p>
                            </div>

                            {/* 🔥 HIỂN THỊ CÁC DỊCH VỤ CỦA CHI NHÁNH 🔥 */}
                            <div className="branch-services">
                                <h4>✨ Dịch vụ cung cấp:</h4>
                                <div className="service-tags">
                                    {branch.DichVuHoTro.split(', ').map((svc, index) => (
                                        <span key={index} className="service-tag">{svc}</span>
                                    ))}
                                </div>
                            </div>
                        </div>
                    )) : <p className="empty">Hiện chưa có dữ liệu chi nhánh.</p>}
                </div>
            </div>
        </div>
    );
};

export default Services;