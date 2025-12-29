import React, { useState, useEffect, useMemo } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';
import dayjs from 'dayjs';

// 1. Gom hết import plugin vào đây
import isBetween from 'dayjs/plugin/isBetween';
import isoWeek from 'dayjs/plugin/isoWeek'; 

// 2. Import CSS
import './EmployeeDashboard.css';

// 3. Sau khi import xong hết mới chạy lệnh config
dayjs.extend(isBetween);
dayjs.extend(isoWeek);

const OrderManagement = () => {
    console.log('🚀🚀🚀 ORDER MANAGEMENT COMPONENT LOADED! 🚀🚀🚀');
    
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(false);
    
    // Tab Thời gian (mặc định là Hôm nay)
    const [timeTab, setTimeTab] = useState('today'); 
    // Tab Trạng thái (mặc định là Tất cả)
    const [statusTab, setStatusTab] = useState('all');
    
    // Modal xem chi tiết sản phẩm
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [selectedOrder, setSelectedOrder] = useState(null);
    const [orderDetails, setOrderDetails] = useState([]);
    const [loadingDetail, setLoadingDetail] = useState(false);
    
    console.log('📌 STATE HIỆN TẠI - timeTab:', timeTab, 'statusTab:', statusTab, 'orders.length:', orders.length); 

    // --- LOGIC GIỮ NGUYÊN ---
    const getDateRange = (tab) => {
        const today = dayjs();
        let start, end;

        switch (tab) {
            case 'today':
                // Hôm nay
                start = today;
                end = today;
                break;
                
            case 'next3':
                // 3 ngày tới (tính cả hôm nay)
                start = today;
                end = today.add(2, 'day'); // add 2 thôi để tổng là 3 ngày
                break;
                
            case 'week':
                // TUẦN NÀY: Từ Thứ 2 đầu tuần đến Chủ nhật cuối tuần (hoặc hôm nay nếu chưa hết tuần)
                start = today.startOf('isoWeek'); // Thứ 2 đầu tuần
                end = today; // Đến hôm nay thôi (không lấy tương lai)
                console.log('📆 WEEK RANGE:', start.format('YYYY-MM-DD'), '->', end.format('YYYY-MM-DD'));
                break;
                
            default:
                start = today;
                end = today;
        }
        
        return {
            tuNgay: start.format('YYYY-MM-DD'),
            denNgay: end.format('YYYY-MM-DD')
        };
    };

    const fetchOrders = async () => {
        console.log('🔥 FETCH ORDERS BẮT ĐẦU - timeTab:', timeTab);
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const { tuNgay, denNgay } = getDateRange(timeTab);
            console.log('📅 DATE RANGE:', tuNgay, '->', denNgay);

            const res = await axios.get('http://localhost:5000/api/employee/appointments', {
                headers: { Authorization: `Bearer ${token}` },
                params: { status: 'ALL', tuNgay, denNgay }
            });

            console.log('📦 DATA TRẢ VỀ:', res.data);
            console.log('📦 SỐ LƯỢNG TRẢ VỀ:', res.data?.length);
            if (res.data && res.data.length > 0) {
                console.log('📦 SAMPLE:', JSON.stringify(res.data[0], null, 2));
            }

            // Lọc DV Mua hàng
            const orderTickets = res.data.filter(item => item.LoaiDichVu === 'Dịch vụ khác');
            console.log('📦 SAU LỌC MUA HÀNG:', orderTickets.length);
            if (orderTickets.length > 0) {
                console.log('📦 SAMPLE SAU LỌC:', JSON.stringify(orderTickets[0], null, 2));
                console.log('📦 DiaChi:', orderTickets[0].DiaChi);
                console.log('📦 TongThanhTien:', orderTickets[0].TongThanhTien);
            } else {
                console.warn('⚠️ KHÔNG CÓ ĐƠN NÀO SAU KHI LỌC!');
            }
            setOrders(orderTickets);
            console.log('✅ ĐÃ SET STATE - orders.length:', orderTickets.length);
        } catch (error) {
            console.error('❌ LỖI FETCH:', error);
            console.error('❌ LỖI CHI TIẾT:', error.response?.data);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchOrders();
        setStatusTab('all'); 
    }, [timeTab]);

    const viewOrderDetail = async (order) => {
        setSelectedOrder(order);
        setShowDetailModal(true);
        setLoadingDetail(true);
        
        try {
            const token = localStorage.getItem('token');
            const maPhieu = order.MaPhieu.trim(); // Trim để bỏ khoảng trắng
            console.log('🔍 Calling API:', `http://localhost:5000/api/employee/order-detail/${maPhieu}`);
            
            const res = await axios.get(`http://localhost:5000/api/employee/order-detail/${maPhieu}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            console.log('📦 Chi tiết đơn hàng:', res.data);
            setOrderDetails(res.data);
        } catch (error) {
            console.error('Lỗi lấy chi tiết:', error);
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể tải chi tiết đơn hàng!', 'error');
        } finally {
            setLoadingDetail(false);
        }
    };

    const filteredOrders = useMemo(() => {
        if (statusTab === 'all') return orders;
        if (statusTab === 'HT_GROUP') return orders.filter(o => o.TrangThai === 'DHT' || o.TrangThai === 'HT');
        return orders.filter(item => item.TrangThai === statusTab);
    }, [orders, statusTab]);

    const countStatus = (status) => {
        if (status === 'HT_GROUP') return orders.filter(o => o.TrangThai === 'DHT' || o.TrangThai === 'HT').length;
        return orders.filter(o => o.TrangThai === status).length;
    };

    const handleConfirmDelivery = async (maPhieu) => {
        const confirm = await Swal.fire({
            title: 'Xác nhận đã giao?',
            text: 'Đơn hàng sẽ được chuyển sang hoàn tất và cộng điểm cho khách.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d7852b', // Màu cam
            confirmButtonText: 'Xác nhận ngay',
            cancelButtonText: 'Hủy bỏ'
        });

        if (!confirm.isConfirmed) return;

        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/employee/confirm-delivery', { MaPhieu: maPhieu }, { headers: { Authorization: `Bearer ${token}` } });
            Swal.fire('Thành công', 'Đơn hàng đã hoàn tất!', 'success');
            fetchOrders();
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Thất bại', 'error');
        } finally {
            setLoading(false);
        }
    };

    const formatMoney = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0);

    // --- PHẦN RENDER STATUS ĐƯỢC LÀM ĐẸP ---
    const renderStatus = (status) => {
        switch (status) {
            case 'DD': 
                return <span className="status-badge status-waiting">🔵 Chờ duyệt</span>;
            case 'DTH': 
                return <span className="status-badge status-shipping">🚚 Đang giao</span>;
            case 'DHT': 
            case 'HT':
                return <span className="status-badge status-done">✅ Hoàn tất</span>;
            case 'DH': 
                return <span className="status-badge status-cancel">❌ Đã hủy</span>;
            default:
                return <span className="status-badge">{status}</span>;
        }
    };

    return (
        <div className="dashboard-container">
            <h2 className="dashboard-title">📦 Quản Lý Đơn Hàng Online</h2>
            <p className="dashboard-subtitle">Theo dõi, duyệt đơn và xác nhận giao hàng cho khách.</p>
            
            {/* 1. TABS THỜI GIAN (Style Nút Tròn Cam) */}
            <div className="tabs-container">
                <button className={`tab-btn ${timeTab === 'today' ? 'active' : ''}`} onClick={() => setTimeTab('today')}>
                    📅 Hôm nay
                </button>
                <button className={`tab-btn ${timeTab === 'next3' ? 'active' : ''}`} onClick={() => setTimeTab('next3')}>
                    🗓️ 3 ngày tới
                </button>
                <button className={`tab-btn ${timeTab === 'week' ? 'active' : ''}`} onClick={() => setTimeTab('week')}>
                    📆 Tuần này
                </button>
            </div>

            {/* 2. FILTER TRẠNG THÁI (Style Pill/Thuốc) */}
            <div className="tab-sub-filter">
                <div className={`filter-pill ${statusTab === 'all' ? 'active' : ''}`} onClick={() => setStatusTab('all')}>
                    Tất cả <span className="badge-count">{orders.length}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'DD' ? 'active' : ''}`} onClick={() => setStatusTab('DD')}>
                    Chờ duyệt <span className="badge-count">{countStatus('DD')}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'DTH' ? 'active' : ''}`} onClick={() => setStatusTab('DTH')}>
                    Đang giao <span className="badge-count">{countStatus('DTH')}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'HT_GROUP' ? 'active' : ''}`} onClick={() => setStatusTab('HT_GROUP')}>
                    Hoàn tất <span className="badge-count">{countStatus('HT_GROUP')}</span>
                </div>
                 <div className={`filter-pill ${statusTab === 'DH' ? 'active' : ''}`} onClick={() => setStatusTab('DH')}>
                    Đã hủy <span className="badge-count">{countStatus('DH')}</span>
                </div>
            </div>

            {/* 3. BẢNG DỮ LIỆU (Style Card Đổ Bóng) */}
            <div className="table-card">
                <table className="booking-table">
                    <thead>
                        <tr>
                            <th>Mã đơn</th>
                            <th>Khách hàng</th>
                            <th>Địa chỉ giao hàng</th>
                            <th>Ngày muốn nhận</th>
                            <th>Tổng tiền</th>
                            <th>Trạng thái</th>
                            <th>Hành động</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan="7" style={{textAlign: 'center', padding: '30px', color: '#888'}}>⏳ Đang tải dữ liệu...</td></tr>
                        ) : filteredOrders.length === 0 ? (
                            <tr><td colSpan="7" style={{textAlign: 'center', padding: '40px', color: '#999'}}>
                                <div style={{fontSize: '40px', marginBottom: '10px'}}>📭</div>
                                Không tìm thấy đơn hàng nào trong mục này.
                            </td></tr>
                        ) : (
                            filteredOrders.map((item, index) => (
                                <tr key={index}>
                                    <td><strong>#{item.MaPhieu}</strong></td>
                                    <td>
                                        <div style={{fontWeight: '600'}}>{item.TenKhachHang}</div>
                                        <div className="text-muted">📞 {item.SDT}</div>
                                    </td>
                                    <td style={{maxWidth: '250px', fontSize: '13px'}}>
                                        <div style={{color: '#2c3e50', lineHeight: '1.4'}}>{item.DiaChi || 'Nhận tại cửa hàng'}</div>
                                    </td>
                                    <td>
                                        <div style={{fontWeight: '500', color: '#d7852b'}}>{dayjs(item.TG_ThucHienDV).format('DD/MM/YYYY')}</div>
                                        <div className="text-muted">09:00</div>
                                    </td>
                                    <td style={{fontWeight: 'bold', color: '#27ae60', fontSize: '1.05rem'}}>
                                        {formatMoney(item.TongThanhTien || item.TongTien || 0)}
                                    </td>
                                    <td>{renderStatus(item.TrangThai)}</td>
                                    <td>
                                        <div style={{display: 'flex', gap: '8px', flexWrap: 'wrap'}}>
                                            <button 
                                                className="btn-view-detail"
                                                onClick={() => viewOrderDetail(item)}
                                                style={{
                                                    padding: '6px 12px',
                                                    background: '#3498db',
                                                    color: 'white',
                                                    border: 'none',
                                                    borderRadius: '4px',
                                                    cursor: 'pointer',
                                                    fontSize: '13px'
                                                }}
                                            >
                                                📦 Chi tiết
                                            </button>
                                            
                                            {item.TrangThai === 'DTH' && (() => {
                                                const deliveryDate = dayjs(item.TG_ThucHienDV);
                                                const today = dayjs();
                                                const canDeliver = deliveryDate.isSame(today, 'day') || deliveryDate.isBefore(today, 'day');
                                                
                                                return (
                                                    <button 
                                                        className="btn-check-in" 
                                                        onClick={() => handleConfirmDelivery(item.MaPhieu)}
                                                        disabled={!canDeliver}
                                                        style={{ opacity: canDeliver ? 1 : 0.5, cursor: canDeliver ? 'pointer' : 'not-allowed' }}
                                                        title={canDeliver ? 'Click để xác nhận' : `Chỉ được xác nhận từ ngày ${deliveryDate.format('DD/MM/YYYY')}`}
                                                    >
                                                        Xác nhận giao
                                                    </button>
                                                );
                                            })()}
                                            
                                            {item.TrangThai === 'DD' && <span className="text-muted" style={{fontStyle:'italic'}}>Chờ Check-in</span>}
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* MODAL XEM CHI TIẾT ĐƠN HÀNG (GIAO DIỆN MỚI) */}
            {/* MODAL XEM CHI TIẾT ĐƠN HÀNG */}
            {showDetailModal && (
                <div className="modal-overlay" onClick={() => setShowDetailModal(false)}>
                    <div 
                        className="modal-content" 
                        onClick={(e) => e.stopPropagation()} 
                        style={{
                            width: '95%',         /* Chiếm 95% màn hình trên mobile */
                            maxWidth: '1000px',   /* Rộng tối đa 1000px trên máy tính (ĐÃ SỬA) */
                            borderRadius: '16px',
                            padding: '30px',      /* Tăng khoảng cách lề cho thoáng */
                            maxHeight: '90vh',    /* Tránh bị tràn màn hình dọc */
                            overflowY: 'auto'     /* Cho phép cuộn nếu danh sách quá dài */
                        }}
                    >
                        
                        {/* 1. HEADER */}
                        <div className="modal-header-modern">
                            <div className="modal-title">
                                <span style={{fontSize: '1.5rem'}}>🧾</span>
                                <span>Chi tiết đơn hàng #{selectedOrder?.MaPhieu}</span>
                            </div>
                            <button className="modal-close-btn" onClick={() => setShowDetailModal(false)}>✕</button>
                        </div>
                        
                        <div className="modal-body">
                            {/* 2. THÔNG TIN KHÁCH HÀNG (CARD CAM NHẠT) */}
                            <div className="order-info-section">
                                {/* Cột Trái: Thông tin người đặt */}
                                <div className="info-group">
                                    <span className="info-label">Khách hàng</span>
                                    <span className="info-value" style={{fontWeight: '700', fontSize: '1.1rem'}}>
                                        👤 {selectedOrder?.TenKhachHang}
                                    </span>
                                    <span className="info-value" style={{fontSize: '0.95rem', color: '#666', marginTop: '4px'}}>
                                        📞 {selectedOrder?.SDT}
                                    </span>
                                </div>

                                {/* Cột Phải: Thông tin giao hàng */}
                                <div className="info-group">
                                    <span className="info-label">Giao đến</span>
                                    <span className="info-value" style={{lineHeight: '1.4'}}>
                                        📍 {selectedOrder?.DiaChi || 'Nhận tại cửa hàng'}
                                    </span>
                                    <span className="info-label" style={{marginTop: '12px'}}>Ngày nhận hàng</span>
                                    <span className="info-value">
                                        📅 {dayjs(selectedOrder?.TG_ThucHienDV).format('DD/MM/YYYY')}
                                    </span>
                                </div>
                            </div>

                            {/* 3. DANH SÁCH SẢN PHẨM */}
                            <h4 style={{margin: '10px 0 15px 0', color: '#555', borderLeft: '4px solid #d7852b', paddingLeft: '10px'}}>
                                🛒 Danh sách sản phẩm
                            </h4>
                            
                            {loadingDetail ? (
                                <div className="loading-box">
                                    <div className="spinner"></div>
                                    ⏳ Đang tải chi tiết đơn hàng...
                                </div>
                            ) : orderDetails.length === 0 ? (
                                <div className="loading-box">
                                    📭 Không có sản phẩm nào trong đơn hàng này
                                </div>
                            ) : (
                                <>
                                    <table className="detail-table">
                                        <thead>
                                            <tr>
                                                <th style={{width: '45%'}}>Sản phẩm</th>
                                                <th style={{textAlign: 'right', width: '20%'}}>Đơn giá</th>
                                                <th style={{textAlign: 'center', width: '10%'}}>SL</th>
                                                <th style={{textAlign: 'right', width: '25%'}}>Thành tiền</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {orderDetails.map((item, idx) => (
                                                <tr key={idx}>
                                                    <td>
                                                        <div className="item-name" style={{fontSize: '1rem'}}>{item.TenMatHang}</div>
                                                        <span className="item-code">#{item.MaMatHang}</span>
                                                    </td>
                                                    <td style={{textAlign: 'right', color: '#666', fontSize: '1rem'}}>
                                                        {formatMoney(item.Gia)}
                                                    </td>
                                                    <td style={{textAlign: 'center', fontWeight: 'bold', fontSize: '1rem'}}>
                                                        x{item.SoLuong}
                                                    </td>
                                                    <td style={{textAlign: 'right', fontWeight: '700', color: '#2c3e50', fontSize: '1rem'}}>
                                                        {formatMoney(item.ThanhTien)}
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>

                                    {/* 4. TỔNG TIỀN (TO & RÕ) */}
                                    <div className="total-section" style={{marginTop: '20px', paddingRight: '10px'}}>
                                        <div className="total-label" style={{fontSize: '1.2rem'}}>TỔNG THANH TOÁN:</div>
                                        <div className="total-price" style={{fontSize: '1.8rem'}}>
                                            {formatMoney(selectedOrder?.TongThanhTien || 0)}
                                        </div>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default OrderManagement;