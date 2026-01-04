import React, { useState, useEffect } from 'react';
import { orderService } from '../../services/orderService';
import { Link, useLocation } from 'react-router-dom';
import ReviewModal from '../../components/ReviewModal';
import axios from 'axios';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import './History.css';

dayjs.extend(utc);

const History = () => {
    const [groupedOrders, setGroupedOrders] = useState([]);
    const [openMaPhieu, setOpenMaPhieu] = useState(null);
    const [loading, setLoading] = useState(true);
    const [reviewModal, setReviewModal] = useState(null);
    const [statusFilter, setStatusFilter] = useState('ALL'); // State để lọc Tab
    
    const location = useLocation();
    const isBookingPage = location.pathname.includes('my-bookings'); 

    const DEFAULT_PET_IMG = 'https://placehold.co/80x80?text=Pet+Shop';

    // Reset filter khi đổi trang giữa Đơn hàng và Đặt hẹn
    useEffect(() => {
        setStatusFilter('ALL');
    }, [isBookingPage]);

    // --- HELPER FUNCTIONS ---
    const getValue = (obj, possibleKeys) => {
        if (!obj) return null;
        const keys = Object.keys(obj);
        for (const key of possibleKeys) {
            if (obj[key] !== undefined && obj[key] !== null) return obj[key];
            const foundKey = keys.find(k => k.toLowerCase() === key.toLowerCase());
            if (foundKey && obj[foundKey] !== undefined && obj[foundKey] !== null) return obj[foundKey];
        }
        return null;
    };

    const parseMoney = (val) => {
        if (!val) return 0;
        if (typeof val === 'number') return val;
        const cleanStr = String(val).replace(/\./g, '').replace(/,/g, '').replace(/\D/g, ''); 
        return Number(cleanStr) || 0;
    };

    const fmtMoney = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(parseMoney(val));
    
    const renderStars = (num) => {
        const n = Math.round(num || 0);
        return (
            <span style={{ color: '#f1c40f', fontSize: '14px', letterSpacing: '2px' }}>
                {'★'.repeat(n)}{'☆'.repeat(5 - n)}
            </span>
        );
    };

    const renderStatus = (status) => {
        const s = status ? String(status).trim().toUpperCase() : '';
        let color = '#7f8c8d'; let text = s;
        switch (s) {
            case 'DD': color = '#3498db'; text = '🔵 Chờ duyệt / Sắp tới'; break;
            case 'DTH': color = '#e67e22'; text = '🚚 Đang giao / Thực hiện'; break;
            case 'DHT': case 'HT': color = '#27ae60'; text = '✅ Đã hoàn thành'; break;
            case 'DH': case 'HUY': color = '#e74c3c'; text = '❌ Đã hủy'; break;
            default: text = `Trạng thái: ${s}`;
        }
        return <div className="status-line" style={{ color: color, fontWeight: 'bold' }}>{text}</div>;
    };

    const getBorderColor = (status) => {
        const s = status ? String(status).trim().toUpperCase() : '';
        switch (s) {
            case 'DD': return '#3498db'; case 'DTH': return '#e67e22';
            case 'DHT': case 'HT': return '#27ae60'; case 'DH': return '#e74c3c';
            default: return '#ccc';
        }
    };

    const handleCancel = (maPhieu) => {
        if (!window.confirm("Bạn có chắc chắn muốn hủy đơn hàng này không?")) return;
        orderService.cancelOrder(maPhieu)
            .then(() => {
                alert("Đã hủy thành công!");
                window.location.reload(); 
            })
            .catch(err => {
                alert("Lỗi khi hủy: " + (err.response?.data?.message || err.message));
            });
    };

    const handleReceived = async (maPhieu) => {
        if (!window.confirm("Xác nhận bạn đã nhận hàng?")) return;
        try {
            const token = localStorage.getItem('token');
            await axios.post('https://happy-pet-fomc.onrender.com/api/orders/confirm-received', 
                { MaPhieu: maPhieu }, 
                { headers: { Authorization: `Bearer ${token}` } }
            );
            alert("Đã xác nhận nhận hàng thành công!");
            window.location.reload();
        } catch (err) {
            alert("Lỗi: " + (err.response?.data?.message || err.message));
        }
    };

    useEffect(() => {
        const fetchHistory = async () => {
            try {
                setLoading(true);
                const rawData = await orderService.getOrderHistory();
                console.log('🔍 RAW DATA từ API:', rawData?.[0]); // Debug: xem field nào có
                const groups = {};
                if (Array.isArray(rawData)) {
                    rawData.forEach(item => {
                        const id = getValue(item, ['MaPhieu']);
                        if (!id) return;
                        if (!groups[id]) {
                            console.log('🔍 DEBUG - Item cho', id, ':', {
                                TG_ThucHienDV: item.TG_ThucHienDV,
                                TG_LapPhieu: item.TG_LapPhieu,
                                NgayMua_willBe: item.TG_ThucHienDV
                            });
                            // 🔥 BỎ "Z" ở cuối để parse như giờ local thay vì UTC
                            const timeStr = item.TG_ThucHienDV ? String(item.TG_ThucHienDV).replace('Z', '') : null;
                            groups[id] = {
                                MaPhieu: id,
                                NgayDat: item.TG_LapPhieu ? String(item.TG_LapPhieu).replace('Z', '') : null,
                                NgayMuonNhan: timeStr, // Dùng TG_ThucHienDV làm ngày muốn nhận
                                ChiNhanh: item.ChiNhanh || 'Online',
                                TrangThai: getValue(item, ['TrangThai']),
                                LoaiPhieu: getValue(item, ['LoaiPhieu']) || 'MH',
                                LoaiDichVu: item.LoaiDichVu,
                                TenThuCung: item.TenThuCung,
                                TongThanhTien: parseMoney(getValue(item, ['TongThanhTienSC'])),
                                PhiGiaoHang: parseMoney(getValue(item, ['PhiGiaoHang'])),
                                DaDanhGiaDV: !!item.DaDanhGiaDV,
                                SaoDV: item.SaoDV,
                                BinhLuanDV: item.BinhLuanDV,
                                TrieuChung: item.TrieuChung,
                                ChanDoan: item.ChanDoan,
                                NgayHenTaiKham: item.NgayHenTaiKham,
                                DanhSachVaccine: item.DanhSachVaccine, 
                                Items: []
                            };
                        }
                        if (item.MaMatHang) {
                            groups[id].Items.push({
                                MaMatHang: item.MaMatHang,
                                TenMatHang: item.TenMatHang,
                                LinkAnh: item.LinkAnh || DEFAULT_PET_IMG,
                                SoLuong: item.SoLuong,
                                DonGia: item.DonGia,
                                ThanhTien: item.ThanhTien,
                                DaDanhGia: !!item.DaDanhGiaSP,
                                SaoSP: item.SaoSP,
                                BinhLuanSP: item.BinhLuanSP
                            });
                        }
                    });
                }
                const sorted = Object.values(groups).sort((a, b) => new Date(b.NgayMua) - new Date(a.NgayMua));
                setGroupedOrders(sorted);
            } catch (err) { console.error(err); } finally { setLoading(false); }
        };
        fetchHistory();
    }, []);

    const filteredOrders = groupedOrders.filter(order => {
        const matchesType = isBookingPage ? order.LoaiPhieu !== 'MH' : order.LoaiPhieu === 'MH';
        if (!matchesType) return false;
        const st = String(order.TrangThai).trim().toUpperCase();
        if (statusFilter === 'ALL') return true;
        if (statusFilter === 'WAITING') return st === 'DD';
        if (statusFilter === 'PROCESSING') return st === 'DTH';
        if (statusFilter === 'COMPLETED') return st === 'HT' || st === 'DHT';
        if (statusFilter === 'CANCELLED') return st === 'HUY' || st === 'DH';
        return true;
    });

    const handleReviewSubmit = async (reviewData) => {
        try {
            const token = localStorage.getItem('token'); 
            const endpoint = reviewModal.type === 'SERVICE' ? 'https://happy-pet-fomc.onrender.com/api/reviews/service' : 'https://happy-pet-fomc.onrender.com/api/reviews/product';
            await axios.post(endpoint, reviewData, { headers: { Authorization: `Bearer ${token}` } });
            alert('Cảm ơn bạn đã đánh giá!'); 
            setReviewModal(null);
            window.location.reload(); 
        } catch (err) { alert('Lỗi: ' + (err.response?.data?.message || err.message)); }
    };

    if (loading) return <div className="loading-state">⏳ Đang tải dữ liệu...</div>;

    return (
        <div className="history-page" style={{ padding: '20px' }}>
            {/* 🔥 KHUNG TRẮNG BAO QUANH NỘI DUNG (Y chang Quản lý lịch hẹn) */}
            <div className="history-container-card" style={{
                backgroundColor: 'white',
                padding: '30px',
                borderRadius: '15px',
                boxShadow: '0 4px 15px rgba(0,0,0,0.05)',
                maxWidth: '900px',
                margin: '0 auto'
            }}>
                <h2 className="title" style={{ textAlign: 'center', marginBottom: '25px', color: '#333' }}>
                    {isBookingPage ? '🏥 Quản Lý Đặt Hẹn' : '📦 Đơn Hàng Của Tôi'}
                </h2>

                {/* TAB THANH LỌC */}
                <div className="filter-tabs" style={{ display: 'flex', justifyContent: 'center', gap: '10px', marginBottom: '30px', borderBottom: '1px solid #eee', paddingBottom: '15px' }}>
                    <button onClick={() => setStatusFilter('ALL')} className={statusFilter === 'ALL' ? 'tab-active' : 'tab-item'}>Tất cả</button>
                    {isBookingPage ? (
                        <>
                            <button onClick={() => setStatusFilter('WAITING')} className={statusFilter === 'WAITING' ? 'tab-active' : 'tab-item'}>Sắp tới</button>
                            <button onClick={() => setStatusFilter('COMPLETED')} className={statusFilter === 'COMPLETED' ? 'tab-active' : 'tab-item'}>Đã hoàn thành</button>
                        </>
                    ) : (
                        <>
                            <button onClick={() => setStatusFilter('WAITING')} className={statusFilter === 'WAITING' ? 'tab-active' : 'tab-item'}>Đã đặt / Chờ duyệt</button>
                            <button onClick={() => setStatusFilter('PROCESSING')} className={statusFilter === 'PROCESSING' ? 'tab-active' : 'tab-item'}>Đang giao</button>
                        </>
                    )}
                    <button onClick={() => setStatusFilter('CANCELLED')} className={statusFilter === 'CANCELLED' ? 'tab-active' : 'tab-item'}>Đã hủy</button>
                </div>

                <div className="order-list">
                    {filteredOrders.length > 0 ? filteredOrders.map(order => {
                        const isCompleted = ['DHT', 'HT'].includes(String(order.TrangThai).trim().toUpperCase());
                        const isServiceTicket = order.LoaiPhieu !== 'MH'; 

                        return (
                            <div key={order.MaPhieu} className="order-card-booking-style">
                                <div className="card-left-border" style={{ borderLeftColor: getBorderColor(order.TrangThai) }}>
                                    <div className="card-content">
                                        <div className="card-title-row" onClick={() => setOpenMaPhieu(openMaPhieu === order.MaPhieu ? null : order.MaPhieu)}>
                                            <span className="order-name">
                                                {isServiceTicket ? '🏥 Phiếu Dịch Vụ' : '🛒 Đơn Hàng'} #{order.MaPhieu}
                                            </span>
                                        </div>
                                        <div className="card-info-row">📍 {order.ChiNhanh}</div>
                                        {order.TenThuCung && isServiceTicket && (
                                            <div className="card-info-row" style={{fontSize: '13px', color: '#555'}}>
                                                🐾 Thú cưng: <strong>{order.TenThuCung}</strong>
                                            </div>
                                        )}
                                        {order.NgayDat && (
                                            <div className="card-info-row" style={{fontSize: '13px', color: '#555'}}>
                                                📅 Ngày đặt: {dayjs(order.NgayDat).format('DD/MM/YYYY HH:mm')}
                                            </div>
                                        )}
                                        {order.NgayMuonNhan && (
                                            <div className="card-info-row" style={{fontSize: '13px', color: '#555'}}>
                                                📦 Ngày muốn nhận: {dayjs(order.NgayMuonNhan).format('DD/MM/YYYY')}
                                            </div>
                                        )}
                                        {order.PhiGiaoHang > 0 && (
                                            <div className="card-info-row" style={{fontSize: '13px', color: '#555'}}>
                                                🚚 Phí ship: {fmtMoney(order.PhiGiaoHang)}
                                            </div>
                                        )}
                                        {order.NgayHenTaiKham && isCompleted && isServiceTicket && (
                                            <div className="card-info-row" style={{fontSize: '14px', color: '#e67e22', fontWeight: 'bold', marginTop: '5px', background: '#fff3e0', padding: '8px', borderRadius: '5px', border: '2px solid #ff9800'}}>
                                                🔔 Lịch tái khám: {dayjs(order.NgayHenTaiKham).format('DD/MM/YYYY')}
                                            </div>
                                        )}
                                        {renderStatus(order.TrangThai)}
                                        <div className="card-money-row">💰 {fmtMoney(order.TongThanhTien)}</div>
                                    </div>
                                    
                                    <div className="card-toggle-btn" style={{display:'flex', flexDirection:'column', gap:'8px', alignItems:'flex-end'}}>
                                        <button 
                                            onClick={() => setOpenMaPhieu(openMaPhieu === order.MaPhieu ? null : order.MaPhieu)}
                                            style={{padding:'6px 12px', border:'1px solid #3498db', background:'#f0f8ff', color:'#3498db', borderRadius:'5px', cursor:'pointer', fontSize:'13px'}}
                                        >
                                            {openMaPhieu === order.MaPhieu ? 'Thu gọn ▲' : 'Chi tiết ▼'}
                                        </button>

                                        {String(order.TrangThai).trim().toUpperCase() === 'DD' && (() => {
                                            const isServiceTicket = order.LoaiDichVu !== 'Dịch vụ khác';
                                            
                                            // Nếu là đơn hàng (MH), check 2 tiếng từ lúc đặt
                                            if (!isServiceTicket) {
                                                const orderTime = dayjs(order.TG_LapPhieu);
                                                const now = dayjs();
                                                const hoursSinceOrder = now.diff(orderTime, 'hour', true);
                                                
                                                if (hoursSinceOrder >= 2) {
                                                    return (
                                                        <span style={{color: '#999', fontSize: '12px', fontStyle: 'italic'}}>
                                                            🔒 Không thể hủy (quá 2 tiếng)
                                                        </span>
                                                    );
                                                }
                                            }
                                            
                                            return (
                                                <button 
                                                    onClick={() => handleCancel(order.MaPhieu)}
                                                    style={{padding:'6px 12px', backgroundColor:'#fff', border:'1px solid #e74c3c', color:'#e74c3c', borderRadius:'5px', cursor:'pointer', fontWeight:'bold', fontSize:'12px'}}
                                                >
                                                    ✖ Hủy
                                                </button>
                                            );
                                        })()}

                                        {String(order.TrangThai).trim().toUpperCase() === 'DTH' && !isServiceTicket && (() => {
                                            // NgayMuonNhan thực chất là TG_ThucHienDV (lưu ngày muốn nhận)
                                            const deliveryDate = dayjs(order.NgayMuonNhan || order.TG_ThucHienDV);
                                            const today = dayjs();
                                            const canReceive = deliveryDate.isSame(today, 'day') || deliveryDate.isBefore(today, 'day');
                                            
                                            return (
                                                <button 
                                                    onClick={() => handleReceived(order.MaPhieu)}
                                                    disabled={!canReceive}
                                                    style={{
                                                        padding:'6px 12px', 
                                                        backgroundColor: canReceive ? '#27ae60' : '#ccc', 
                                                        border:'none', 
                                                        color:'#fff', 
                                                        borderRadius:'5px', 
                                                        cursor: canReceive ? 'pointer' : 'not-allowed', 
                                                        fontWeight:'bold', 
                                                        fontSize:'12px',
                                                        opacity: canReceive ? 1 : 0.6
                                                    }}
                                                    title={canReceive ? 'Xác nhận đã nhận hàng' : `Chỉ được nhận từ ngày ${deliveryDate.format('DD/MM/YYYY')}`}
                                                >
                                                    ✅ Đã nhận hàng
                                                </button>
                                            );
                                        })()}
                                    </div>
                                </div>

                                {openMaPhieu === order.MaPhieu && (
                                    <div className="order-detail-box">
                                        {!isServiceTicket && order.Items.length > 0 && (
                                            <table className="detail-table">
                                                <thead><tr><th align="left">Sản phẩm</th><th>SL</th><th>Giá</th><th align="right">Đánh giá</th></tr></thead>
                                                <tbody>
                                                    {order.Items.map((item, idx) => (
                                                        <tr key={idx}>
                                                            <td><div className="product-cell"><img src={item.LinkAnh} onError={(e)=>e.target.src=DEFAULT_PET_IMG} alt=""/><span>{item.TenMatHang}</span></div></td>
                                                            <td align="center">x{item.SoLuong}</td>
                                                            <td align="center">{fmtMoney(item.DonGia)}</td>
                                                            <td align="right">
                                                                {isCompleted ? (
                                                                    item.DaDanhGia ? (
                                                                        <div style={{textAlign: 'right'}}>
                                                                            <div>{renderStars(item.SaoSP)}</div>
                                                                            <div style={{fontSize: '11px', color: '#555', fontStyle: 'italic'}}>"{item.BinhLuanSP}"</div>
                                                                        </div>
                                                                    ) : (
                                                                        <button className="btn-rate-mini" onClick={()=>setReviewModal({type:'PRODUCT', data:{MaPhieu:order.MaPhieu, MaMatHang:item.MaMatHang}})}>Viết nhận xét</button>
                                                                    )
                                                                ) : <span>-</span>}
                                                            </td>
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </table>
                                        )}

                                        {isServiceTicket && (
                                            <div className="medical-record" style={{padding: '15px', backgroundColor: '#f9f9f9', borderRadius: '8px', marginBottom:'10px'}}>
                                                {order.TrieuChung && <p>🤒 <b>Triệu chứng:</b> {order.TrieuChung}</p>}
                                                {order.ChanDoan && <p>👨‍⚕️ <b>Chẩn đoán:</b> {order.ChanDoan}</p>}
                                                {order.NgayHenTaiKham && (
                                                    <p style={{color:'#ff9800', fontWeight:'bold', background:'#fff3e0', padding:'8px', borderRadius:'5px', marginTop:'10px'}}>
                                                        📅 <b>Ngày hẹn tái khám:</b> {dayjs(order.NgayHenTaiKham).format('DD/MM/YYYY')}
                                                    </p>
                                                )}
                                                {order.DanhSachVaccine && (
                                                    <div style={{marginTop:'10px', padding:'10px', background:'#e8f5e9', borderRadius:'5px', border:'1px solid #4caf50'}}>
                                                        <p style={{color:'#2e7d32', marginBottom:'5px'}}><b>💉 Danh sách Vaccine:</b></p>
                                                        <div style={{fontSize:'14px', color:'#555', lineHeight:'1.8'}}>
                                                            {order.DanhSachVaccine.split(',').map((vaccine, idx) => {
                                                                const isPackage = vaccine.includes('[Theo gói]');
                                                                const isReminder = vaccine.includes('[Mũi nhắc lại]');
                                                                const isSingle = vaccine.includes('[Lẻ]');
                                                                
                                                                let badge = '';
                                                                let badgeColor = '';
                                                                
                                                                if (isReminder) {
                                                                    badge = '🔄 Nhắc lại';
                                                                    badgeColor = '#9c27b0';
                                                                } else if (isPackage) {
                                                                    badge = '📦 Theo gói';
                                                                    badgeColor = '#2196f3';
                                                                } else if (isSingle) {
                                                                    badge = '🎯 Tiêm lẻ';
                                                                    badgeColor = '#ff9800';
                                                                }
                                                                
                                                                const cleanName = vaccine.replace(/\[(Theo gói|Lẻ|Mũi nhắc lại)\]/g, '').trim();
                                                                
                                                                return (
                                                                    <div key={idx} style={{marginBottom:'5px', display:'flex', alignItems:'center', gap:'8px'}}>
                                                                        <span>•</span>
                                                                        <span>{cleanName}</span>
                                                                        {badge && (
                                                                            <span style={{
                                                                                background:badgeColor, 
                                                                                color:'white', 
                                                                                padding:'2px 8px', 
                                                                                borderRadius:'12px', 
                                                                                fontSize:'11px',
                                                                                fontWeight:'bold'
                                                                            }}>
                                                                                {badge}
                                                                            </span>
                                                                        )}
                                                                    </div>
                                                                );
                                                            })}
                                                        </div>
                                                    </div>
                                                )}
                                                
                                                {isCompleted && (
                                                    <div style={{marginTop:'10px', borderTop:'1px dashed #ccc', paddingTop:'10px', textAlign:'right'}}>
                                                        {order.DaDanhGiaDV ? (
                                                            <>
                                                                <div style={{fontWeight:'bold', color:'#8e44ad'}}>✨ Đánh giá dịch vụ: {renderStars(order.SaoDV)}</div>
                                                                <div style={{fontSize:'12px', color:'#555', fontStyle:'italic'}}>"{order.BinhLuanDV}"</div>
                                                            </>
                                                        ) : (
                                                            <button className="btn-rate-service" onClick={()=>setReviewModal({type:'SERVICE', data:{MaPhieu:order.MaPhieu}})}>✨ Viết đánh giá dịch vụ</button>
                                                        )}
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                        <div className="detail-footer">
                                            <div>{order.PhiGiaoHang > 0 && `Phí ship: ${fmtMoney(order.PhiGiaoHang)}`}</div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        );
                    }) : (
                        <div className="empty-state">
                            <p style={{ textAlign: 'center', fontStyle: 'italic', color: '#999' }}>Không có dữ liệu trong mục này.</p>
                        </div>
                    )}
                </div>
            </div>
            {reviewModal && <ReviewModal type={reviewModal.type} data={reviewModal.data} onClose={()=>setReviewModal(null)} onSubmit={handleReviewSubmit}/>}
        </div>
    );
};

export default History;