import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Doctor.css';

const Medicines = () => {
    const [items, setItems] = useState([]);
    const [filteredItems, setFilteredItems] = useState([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');
    const [filterType, setFilterType] = useState('ALL'); // ALL, T, VC

    const fetchMedicinesAndVaccines = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get('http://localhost:5000/api/doctor/medicines', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setItems(res.data);
            setFilteredItems(res.data);
            console.log('✅ Loaded medicines & vaccines:', res.data.length, 'items');
        } catch (err) {
            console.error('❌ Error loading medicines & vaccines:', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchMedicinesAndVaccines();
    }, []);

    // Filter logic
    useEffect(() => {
        let result = items;

        // Filter by type (ALL, T=Thuốc, VC=Vaccine)
        if (filterType !== 'ALL') {
            result = result.filter(item => item.LoaiMH?.trim() === filterType);
        }

        // Filter by search text
        if (searchText.trim()) {
            const search = searchText.toLowerCase();
            result = result.filter(item =>
                item.TenThuoc?.toLowerCase().includes(search) ||
                item.MaThuoc?.toLowerCase().includes(search) ||
                item.LoaiThuoc?.toLowerCase().includes(search)
            );
        }

        setFilteredItems(result);
    }, [searchText, filterType, items]);

    const formatPrice = (price) => {
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
    };

    return (
        <div className="doctor-dashboard">
            <div className="dashboard-header">
                <h2>💊 Danh Sách Thuốc & Vaccine</h2>
                <button className="btn-refresh" onClick={fetchMedicinesAndVaccines}>
                    🔄 Làm mới
                </button>
            </div>

            {/* Search & Filter Controls */}
            <div style={{
                display: 'flex',
                gap: '15px',
                marginBottom: '20px',
                flexWrap: 'wrap',
                alignItems: 'center'
            }}>
                {/* Search Input */}
                <input
                    type="text"
                    placeholder="🔍 Tìm theo tên, mã thuốc/vaccine..."
                    value={searchText}
                    onChange={(e) => setSearchText(e.target.value)}
                    style={{
                        flex: '1',
                        minWidth: '250px',
                        padding: '10px 15px',
                        border: '2px solid #ddd',
                        borderRadius: '8px',
                        fontSize: '15px',
                        outline: 'none',
                        transition: 'border-color 0.3s'
                    }}
                    onFocus={(e) => e.target.style.borderColor = '#4CAF50'}
                    onBlur={(e) => e.target.style.borderColor = '#ddd'}
                />

                {/* Filter Buttons */}
                <div style={{ display: 'flex', gap: '10px' }}>
                    <button
                        onClick={() => setFilterType('ALL')}
                        style={{
                            padding: '10px 20px',
                            border: 'none',
                            borderRadius: '8px',
                            background: filterType === 'ALL' ? '#4CAF50' : '#f0f0f0',
                            color: filterType === 'ALL' ? 'white' : '#333',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            transition: 'all 0.3s'
                        }}
                    >
                        📦 Tất cả ({items.length})
                    </button>
                    <button
                        onClick={() => setFilterType('T')}
                        style={{
                            padding: '10px 20px',
                            border: 'none',
                            borderRadius: '8px',
                            background: filterType === 'T' ? '#2196F3' : '#f0f0f0',
                            color: filterType === 'T' ? 'white' : '#333',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            transition: 'all 0.3s'
                        }}
                    >
                        💊 Thuốc ({items.filter(i => i.LoaiMH?.trim() === 'T').length})
                    </button>
                    <button
                        onClick={() => setFilterType('VC')}
                        style={{
                            padding: '10px 20px',
                            border: 'none',
                            borderRadius: '8px',
                            background: filterType === 'VC' ? '#FF9800' : '#f0f0f0',
                            color: filterType === 'VC' ? 'white' : '#333',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                            transition: 'all 0.3s'
                        }}
                    >
                        💉 Vaccine ({items.filter(i => i.LoaiMH?.trim() === 'VC').length})
                    </button>
                </div>
            </div>

            {/* Results Summary */}
            <div style={{
                padding: '10px 15px',
                background: '#f8f9fa',
                borderRadius: '8px',
                marginBottom: '20px',
                fontSize: '14px',
                color: '#666'
            }}>
                Hiển thị <b style={{ color: '#4CAF50' }}>{filteredItems.length}</b> kết quả
                {searchText && ` cho từ khóa "${searchText}"`}
            </div>

            {loading ? (
                <div className="loading-container">
                    <div className="spinner">⏳</div>
                    <p>Đang tải dữ liệu...</p>
                </div>
            ) : filteredItems.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">📦</div>
                    <h3>Không tìm thấy kết quả</h3>
                    <p>Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc</p>
                </div>
            ) : (
                <div className="patient-grid" style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
                    gap: '20px'
                }}>
                    {filteredItems.map((item) => {
                        const isMedicine = item.LoaiMH?.trim() === 'T';
                        const isVaccine = item.LoaiMH?.trim() === 'VC';
                        
                        return (
                            <div 
                                key={item.MaThuoc} 
                                className="patient-card"
                                style={{
                                    border: `2px solid ${isMedicine ? '#2196F3' : '#FF9800'}`,
                                    borderRadius: '12px',
                                    padding: '15px',
                                    background: 'white',
                                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                                    transition: 'transform 0.2s, box-shadow 0.2s'
                                }}
                                onMouseEnter={(e) => {
                                    e.currentTarget.style.transform = 'translateY(-5px)';
                                    e.currentTarget.style.boxShadow = '0 6px 20px rgba(0,0,0,0.15)';
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.transform = 'translateY(0)';
                                    e.currentTarget.style.boxShadow = '0 2px 8px rgba(0,0,0,0.1)';
                                }}
                            >
                                <div className="card-header" style={{ marginBottom: '12px' }}>
                                    <span 
                                        className="status-badge"
                                        style={{
                                            background: isMedicine ? '#2196F3' : '#FF9800',
                                            color: 'white',
                                            padding: '5px 12px',
                                            borderRadius: '20px',
                                            fontSize: '13px',
                                            fontWeight: 'bold',
                                            display: 'inline-block'
                                        }}
                                    >
                                        {isMedicine ? '💊 Thuốc' : '💉 Vaccine'}
                                    </span>
                                </div>

                                <h3 style={{
                                    fontSize: '16px',
                                    fontWeight: 'bold',
                                    color: '#333',
                                    marginBottom: '10px',
                                    lineHeight: '1.4'
                                }}>
                                    {item.TenThuoc}
                                </h3>

                                <div className="card-body" style={{ fontSize: '14px' }}>
                                    <div className="info-row" style={{ marginBottom: '8px' }}>
                                        <span style={{ color: '#666' }}>🆔 Mã:</span>
                                        <span style={{ fontWeight: 'bold', color: '#333' }}>
                                            {item.MaThuoc}
                                        </span>
                                    </div>

                                    {isMedicine && item.LoaiThuoc && (
                                        <div className="info-row" style={{ marginBottom: '8px' }}>
                                            <span style={{ color: '#666' }}>📋 Loại:</span>
                                            <span style={{
                                                fontWeight: 'bold',
                                                color: item.LoaiThuoc?.trim() === 'KĐ' ? '#d32f2f' : '#4CAF50'
                                            }}>
                                                {item.LoaiThuoc?.trim() === 'KĐ' ? '⚠️ Kê đơn' : '✅ Không kê đơn'}
                                            </span>
                                        </div>
                                    )}

                                    {isVaccine && item.MoTa && (
                                        <div style={{
                                            marginBottom: '8px',
                                            padding: '8px',
                                            background: '#fff3cd',
                                            borderRadius: '6px',
                                            fontSize: '13px',
                                            color: '#856404'
                                        }}>
                                            ℹ️ {item.MoTa}
                                        </div>
                                    )}

                                    <div className="info-row" style={{ marginBottom: '8px' }}>
                                        <span style={{ color: '#666' }}>💰 Giá:</span>
                                        <span style={{ fontWeight: 'bold', color: '#4CAF50' }}>
                                            {formatPrice(item.DonGia)}
                                        </span>
                                    </div>

                                    <div className="info-row">
                                        <span style={{ color: '#666' }}>📦 Tồn kho:</span>
                                        <span style={{
                                            fontWeight: 'bold',
                                            color: item.SoLuongTon > 10 ? '#4CAF50' : 
                                                   item.SoLuongTon > 0 ? '#FF9800' : '#d32f2f'
                                        }}>
                                            {item.SoLuongTon} {isMedicine ? 'viên/hộp' : 'mũi'}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default Medicines;
