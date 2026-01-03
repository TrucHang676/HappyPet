
import React, { useState, useEffect } from 'react';
import { orderService } from '../../services/orderService'; 
import axios from 'axios';
import Swal from 'sweetalert2';
import ReviewModal from '../../components/ReviewModal'; 
import { useNavigate } from 'react-router-dom';
import './Booking.css';

const MyBookings = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('ALL'); 
    const [filterType, setFilterType] = useState('ALL'); // ✅ Thêm filter loại phiếu
    const [openMaPhieu, setOpenMaPhieu] = useState(null); 
    const [reviewModal, setReviewModal] = useState(null);
    const navigate = useNavigate();

    const fetchBookings = async () => {
        try {
            const token = localStorage.getItem('token');
            if (!token) { navigate('/login'); return; }
            setLoading(true);
            
            const rawData = await orderService.getOrderHistory();
            
            // 🔥 FIX: Xử lý TG_ThucHienDV giống History.js
            console.log("Dữ liệu từ API nè bà ơi:", rawData?.[0]);

            const serviceList = rawData
                .filter(item => item.LoaiPhieu !== 'MH')
                .map(item => ({
                    ...item,
                    // Bỏ "Z" để parse đúng timezone Việt Nam
                    NgayMua: item.TG_ThucHienDV ? String(item.TG_ThucHienDV).replace('Z', '') : item.TG_LapPhieu
                }));
            setBookings(serviceList);
        } catch (error) { console.error(error); } 
        finally { setLoading(false); }
    };

    useEffect(() => { fetchBookings(); }, []);

    const handleCancel = (maPhieu) => {
        Swal.fire({
            title: 'Hủy lịch hẹn?', text: "Bạn có chắc chắn muốn hủy phiếu này không?",
            icon: 'warning', showCancelButton: true, confirmButtonColor: '#d33', confirmButtonText: 'Hủy luôn!', cancelButtonText: 'Giữ lại'
        }).then(async (result) => {
            if (result.isConfirmed) {
                try {
                    await orderService.cancelOrder(maPhieu);
                    Swal.fire('Thành công!', 'Lịch hẹn đã được hủy.', 'success');
                    fetchBookings();
                } catch (error) { Swal.fire('Thất bại!', 'Lỗi khi hủy.', 'error'); }
            }
        });
    };

    const handleReviewSubmit = async (reviewData) => {
        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/reviews/service', reviewData, { headers: { Authorization: `Bearer ${token}` } });
            Swal.fire('Cảm ơn!', 'Đánh giá thành công.', 'success');
            setReviewModal(null);
            fetchBookings(); 
        } catch (err) { Swal.fire('Lỗi', 'Không thể gửi đánh giá.', 'error'); }
    };

    const getStatusColor = (status) => {
        const s = status ? status.trim().toUpperCase() : '';
        if (s === 'DD') return '#007bff'; if (s === 'DTH') return '#ffc107';
        if (s === 'DHT' || s === 'HT') return '#28a745'; if (s === 'HUY' || s === 'DH') return '#dc3545';
        return '#6c757d';
    };

    const fmtMoney = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0);

    const renderStars = (num) => {
        const n = Math.round(num || 0);
        return (
            <span style={{ color: '#f1c40f', fontSize: '16px', letterSpacing: '2px' }}>
                {'★'.repeat(n)}{'☆'.repeat(5 - n)}
            </span>
        );
    };

    const displayList = bookings.filter(item => {
        const st = item.TrangThai?.trim().toUpperCase();
        const loaiPhieu = item.LoaiPhieu?.trim().toUpperCase();
        
        // Filter theo trạng thái
        let passStatus = true;
        if (activeTab === 'UPCOMING') passStatus = st === 'DD' || st === 'DTH';
        else if (activeTab === 'COMPLETED') passStatus = st === 'DHT' || st === 'HT';
        else if (activeTab === 'CANCELLED') passStatus = st === 'HUY' || st === 'DH';
        
        // ✅ Filter theo loại phiếu
        let passType = true;
        if (filterType === 'KB') passType = loaiPhieu === 'KB';
        else if (filterType === 'TV') passType = loaiPhieu === 'TV';
        
        return passStatus && passType;
    });

    return (
        <div className="booking-container" style={{maxWidth: '900px'}}>
            <h2 className="booking-title">📅 Quản Lý Lịch Hẹn</h2>
            
            <div className="tabs" style={{display:'flex', gap:'10px', marginBottom:'20px', borderBottom:'1px solid #ddd', paddingBottom:'10px', justifyContent:'center'}}>
                <button onClick={() => setActiveTab('ALL')} className={activeTab === 'ALL' ? 'tab-active' : 'tab-item'}>Tất cả</button>
                <button onClick={() => setActiveTab('UPCOMING')} className={activeTab === 'UPCOMING' ? 'tab-active' : 'tab-item'}>Sắp tới</button>
                <button onClick={() => setActiveTab('COMPLETED')} className={activeTab === 'COMPLETED' ? 'tab-active' : 'tab-item'}>Đã hoàn thành</button>
                <button onClick={() => setActiveTab('CANCELLED')} className={activeTab === 'CANCELLED' ? 'tab-active' : 'tab-item'}>Đã hủy</button>
            </div>

            {/* ✅ Filter theo loại phiếu */}
            <div style={{display:'flex', gap:'10px', marginBottom:'15px', justifyContent:'center'}}>
                <button onClick={() => setFilterType('ALL')} style={{padding:'8px 16px', border:'1px solid #ddd', borderRadius:'20px', background: filterType === 'ALL' ? '#007bff' : '#fff', color: filterType === 'ALL' ? '#fff' : '#333', cursor:'pointer', fontWeight: filterType === 'ALL' ? 'bold' : 'normal'}}>
                    🐾 Tất cả
                </button>
                <button onClick={() => setFilterType('KB')} style={{padding:'8px 16px', border:'1px solid #ddd', borderRadius:'20px', background: filterType === 'KB' ? '#28a745' : '#fff', color: filterType === 'KB' ? '#fff' : '#333', cursor:'pointer', fontWeight: filterType === 'KB' ? 'bold' : 'normal'}}>
                    🩺 Khám bệnh
                </button>
                <button onClick={() => setFilterType('TV')} style={{padding:'8px 16px', border:'1px solid #ddd', borderRadius:'20px', background: filterType === 'TV' ? '#17a2b8' : '#fff', color: filterType === 'TV' ? '#fff' : '#333', cursor:'pointer', fontWeight: filterType === 'TV' ? 'bold' : 'normal'}}>
                    💉 Tiêm vaccine
                </button>
            </div>

            {loading ? <p>Đang tải...</p> : (
                displayList.length === 0 ? 
                <p style={{textAlign:'center', color:'#777', fontStyle:'italic', marginTop:'20px'}}>Không có phiếu nào trong danh sách này.</p> 
                : 
                <div style={{display:'flex', flexDirection:'column', gap:'15px'}}>
                    {displayList.map((item) => {
                        const isCompleted = ['DHT', 'HT'].includes(item.TrangThai?.trim().toUpperCase());
                        
                        // 🔥 SỬA CHỖ NÀY: Quét mọi trường có thể có + trim khoảng trắng NCHAR 🔥
                        const petName = (item.TenPet || item.TenThuCung || item.TenTC || item.petName || item.PetName || item.MaThuCung || "").trim() || "Không rõ tên";
                        
                        // 🔥 FIX TIMEZONE: Hiển thị TG_ThucHienDV (thời gian hẹn/nhận)
                        const appointmentDateTime = item.NgayMua ? String(item.NgayMua).replace(/Z$/, '') : null;
                        const appointmentDate = appointmentDateTime ? new Date(appointmentDateTime) : new Date();
                        const timeStr = appointmentDate.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
                        const dateStr = appointmentDate.toLocaleDateString('vi-VN');

                        return (
                            <div key={item.MaPhieu} className="ticket-card" style={{
                                display:'flex', flexDirection:'column', padding:'20px', backgroundColor:'white', borderRadius:'10px',
                                boxShadow:'0 2px 8px rgba(0,0,0,0.1)', borderLeft: `6px solid ${getStatusColor(item.TrangThai)}`
                            }}>
                                <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', width: '100%'}}>
                                    <div>
                                        <h4 style={{margin:'0 0 5px 0', color:'#333'}}>
                                            {item.LoaiPhieu === 'KB' ? 'Khám Bệnh' : 'Tiêm Vaccine'} #{item.MaPhieu}
                                            <span style={{fontWeight:'normal', fontSize:'14px', color:'#777'}}> - 🕒 {timeStr} {dateStr}</span>
                                        </h4>
                                        
                                        <p style={{margin:'8px 0', fontSize:'15px', color:'#d35400', fontWeight:'600'}}>
                                            🐾 Thú cưng: <span style={{color: '#2c3e50'}}>{petName}</span>
                                        </p>

                                        <p style={{margin:'0', fontSize:'14px', color:'#555'}}>🏥 <strong>{item.ChiNhanh}</strong></p>
                                        <p style={{margin:'5px 0 0 0', fontWeight:'bold', fontSize:'13px', color: getStatusColor(item.TrangThai)}}>● {item.TrangThai}</p>
                                        {isCompleted && (
                                            <p style={{margin:'5px 0 0 0', color:'#2e7d32', fontWeight:'bold', fontSize:'14px'}}>
                                                💰 Tổng: {fmtMoney(item.TongThanhTienSC)}
                                            </p>
                                        )}
                                    </div>

                                    <div style={{display:'flex', flexDirection:'column', gap:'10px', alignItems:'flex-end'}}>
                                        {item.TrangThai?.trim().toUpperCase() === 'DD' && (
                                            <button onClick={() => handleCancel(item.MaPhieu)} style={{padding:'8px 15px', backgroundColor:'#fff', border:'1px solid #dc3545', color:'#dc3545', borderRadius:'5px', cursor:'pointer', fontWeight:'bold', fontSize:'12px'}}>Hủy Phiếu</button>
                                        )}
                                        <button onClick={() => setOpenMaPhieu(openMaPhieu === item.MaPhieu ? null : item.MaPhieu)} style={{padding:'6px 12px', border:'1px solid #007bff', background:'#f0f8ff', color:'#007bff', borderRadius:'5px', cursor:'pointer', fontSize:'13px'}}>
                                            {openMaPhieu === item.MaPhieu ? 'Thu gọn ▲' : 'Xem chi tiết ▼'}
                                        </button>
                                    </div>
                                </div>

                                {openMaPhieu === item.MaPhieu && (
                                    <div style={{marginTop:'15px', paddingTop:'15px', borderTop:'1px dashed #eee'}}>
                                        {item.TrieuChung && <p style={{margin:'5px 0'}}>🤒 <b>Triệu chứng:</b> {item.TrieuChung}</p>}
                                        {item.ChanDoan && <p style={{margin:'5px 0'}}>👨‍⚕️ <b>Chẩn đoán:</b> {item.ChanDoan}</p>}
                                        {/* ✅ Hiển thị ngày tái khám */}
                                        {item.LoaiPhieu === 'KB' && item.NgayHenTaiKham && (
                                            <p style={{margin:'5px 0', color:'#dc3545', fontWeight:'bold'}}>
                                                📅 <b>Ngày hẹn tái khám:</b> {new Date(item.NgayHenTaiKham).toLocaleDateString('vi-VN')}
                                            </p>
                                        )}
                                        {item.DanhSachVaccine && <p style={{margin:'5px 0', color:'#28a745'}}>💉 <b>Vaccine:</b> {item.DanhSachVaccine}</p>}
                                        {!item.TrieuChung && !item.ChanDoan && !item.DanhSachVaccine && <p style={{color:'#999', fontStyle:'italic'}}>Chưa có thông tin y tế.</p>}

                                        {isCompleted && (
                                            <div style={{marginTop: '15px', borderTop: '1px solid #eee', paddingTop: '10px'}}>
                                                {item.DaDanhGiaDV ? (
                                                    <div style={{backgroundColor: '#f8f9fa', padding: '10px', borderRadius: '8px', border: '1px solid #e9ecef'}}>
                                                        <div style={{display: 'flex', justifyContent: 'space-between', marginBottom: '5px'}}>
                                                            <span style={{fontWeight: 'bold', color: '#6f42c1'}}>✨ Đánh giá:</span>
                                                            {renderStars(item.SaoDV)}
                                                        </div>
                                                        <p style={{margin: 0, fontSize: '14px', color: '#555', fontStyle: 'italic'}}>
                                                            "{item.BinhLuanDV}"
                                                        </p>
                                                    </div>
                                                ) : (
                                                    <div style={{textAlign: 'right'}}>
                                                        <button 
                                                            onClick={() => setReviewModal({ type: 'SERVICE', data: { MaPhieu: item.MaPhieu } })}
                                                            style={{padding:'8px 15px', backgroundColor:'#6f42c1', color:'white', border:'none', borderRadius:'5px', cursor:'pointer', fontWeight:'bold'}}
                                                        >
                                                            ✨ Viết đánh giá
                                                        </button>
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
            {reviewModal && <ReviewModal type={reviewModal.type} data={reviewModal.data} onClose={() => setReviewModal(null)} onSubmit={handleReviewSubmit}/>}
        </div>
    );
};

export default MyBookings;