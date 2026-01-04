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

const ServiceBookings = () => {
    const [bookings, setBookings] = useState([]);
    const [doctors, setDoctors] = useState([]);
    const [loading, setLoading] = useState(false);

    // State cho Tabs & Filter
    const [timeTab, setTimeTab] = useState('today');
    const [statusTab, setStatusTab] = useState('all');

    // State cho Modal Check-in
    const [showDoctorModal, setShowDoctorModal] = useState(false);
    const [currentTicket, setCurrentTicket] = useState(null);
    const [selectedDoctor, setSelectedDoctor] = useState('');

    // State cho Modal Walk-in
    const [showWalkInModal, setShowWalkInModal] = useState(false);
    const [walkInData, setWalkInData] = useState({
        MaKH: '',
        MaTC: '',
        LoaiPhieu: 'KB',
        TrieuChung: ''
    });
    
    // State cho tìm kiếm khách hàng
    const [phoneSearch, setPhoneSearch] = useState('');
    const [searchResult, setSearchResult] = useState(null);
    const [isSearching, setIsSearching] = useState(false);
    const [selectedPet, setSelectedPet] = useState(null);
    
    // State cho modal xuất hóa đơn
    const [showInvoiceModal, setShowInvoiceModal] = useState(false);
    const [currentInvoiceTicket, setCurrentInvoiceTicket] = useState(null);
    const [invoiceData, setInvoiceData] = useState({
        DiemMuonDung: 0,
        PhuongThucTT: 'Tiền mặt'
    });
    const [invoiceResult, setInvoiceResult] = useState(null);
    
    // State cho form đăng ký khách mới
    const [newCustomerForm, setNewCustomerForm] = useState({
        hoTen: '',
        gioiTinhUser: 'Nam',
        sdt: '',
        diaChi: '',
        tenPet: '',
        loaiPet: '',
        giongPet: '',
        gioiTinhPet: 'Đực',
        ngaySinhPet: '',
        tinhTrangSucKhoe: 'Bình thường',
        loaiPhieu: 'KB',
        trieuChung: ''
    });

    // 1. Logic tính ngày
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
                // --- QUAN TRỌNG: Dùng isoWeek để ép Thứ 2 là đầu tuần ---
                // Nếu hôm nay là 28/12 (CN) -> start sẽ lùi về 22/12 (T2)
                start = today.startOf('isoWeek'); 
                
                // End sẽ là 28/12 (CN)
                end = today.endOf('isoWeek');     
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

    // 2. Fetch dữ liệu
    const fetchBookings = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const { tuNgay, denNgay } = getDateRange(timeTab);

            const res = await axios.get('https://happy-pet-fomc.onrender.com/api/employee/appointments', {
                headers: { Authorization: `Bearer ${token}` },
                params: { status: 'ALL', tuNgay, denNgay }
            });

            // Lọc phiếu Dịch vụ (Khám bệnh, Tiêm vaccine)
            const serviceTickets = res.data.filter(item => ['Khám bệnh', 'Tiêm vaccine'].includes(item.LoaiDichVu));
            setBookings(serviceTickets);
        } catch (error) {
            console.error('Lỗi:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchDoctors = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get('https://happy-pet-fomc.onrender.com/api/employee/doctors-status', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setDoctors(res.data);
        } catch (error) {
            console.error('Lỗi:', error);
        }
    };

    useEffect(() => {
        fetchBookings();
        fetchDoctors();
        setStatusTab('all'); // Reset filter khi đổi ngày
    }, [timeTab]);

    // 3. Logic lọc Client-side
    const filteredBookings = useMemo(() => {
        if (statusTab === 'all') return bookings;
        if (statusTab === 'HT_GROUP') return bookings.filter(o => o.TrangThai === 'DHT' || o.TrangThai === 'HT');
        return bookings.filter(item => item.TrangThai === statusTab);
    }, [bookings, statusTab]);

    const countStatus = (status) => {
        if (status === 'HT_GROUP') return bookings.filter(o => o.TrangThai === 'DHT' || o.TrangThai === 'HT').length;
        return bookings.filter(o => o.TrangThai === status).length;
    };

    // 4. Logic Check-in
    const handleCheckIn = (ticket) => {
        // 🔧 COMMENT TẠM ĐỂ TEST - Bỏ check giờ làm việc
        
        const now = new Date();
        const currentHour = now.getHours();
        
        // Ví dụ: Giờ làm việc 8h - 22h (có thể sửa lại tùy ý)
        if (currentHour < 8 || currentHour >= 22) { 
            Swal.fire({ icon: 'warning', title: 'Ngoài giờ làm việc!', text: 'Vui lòng check-in trong giờ hành chính.' });
            return;
        }
        
        setCurrentTicket(ticket);
        setShowDoctorModal(true);
    };

    const confirmCheckIn = async () => {
        if (!selectedDoctor) return Swal.fire('Lỗi', 'Vui lòng chọn bác sĩ!', 'warning');
        
        const doctor = doctors.find(d => d.MaNV === selectedDoctor);
        if (doctor && doctor.TrangThai === 'Bận') {
            return Swal.fire({ icon: 'error', title: 'Bác sĩ bận!', text: `${doctor.TenNV} đang có ca khám.` });
        }

        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            await axios.put('https://happy-pet-fomc.onrender.com/api/employee/check-in', 
                { MaPhieu: currentTicket.MaPhieu, MaBacSi: selectedDoctor },
                { headers: { Authorization: `Bearer ${token}` } }
            );
            Swal.fire('Thành công', 'Check-in thành công!', 'success');
            setShowDoctorModal(false);
            setSelectedDoctor('');
            fetchBookings();
            fetchDoctors();
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Thất bại', 'error');
        } finally {
            setLoading(false);
        }
    };

    // 5. Logic xuất hóa đơn
    const handleExportInvoice = async (ticket) => {
        setCurrentInvoiceTicket(ticket);
        setShowInvoiceModal(true);
        setLoading(true);
        
        // 🔥 LẤY ĐIỂM TÍCH LŨY TỪ DATABASE (qua backend)
        try {
            const token = localStorage.getItem('token');
            const maKH = ticket.MaKH;
            
            if (!maKH) {
                console.warn('Ticket không có MaKH:', ticket);
                setInvoiceData({ DiemMuonDung: 0, PhuongThucTT: 'Tiền mặt', DiemHienCo: 0 });
                return;
            }
            
            // Gọi query trực tiếp để lấy điểm (backend sẽ query database)
            const response = await axios.get(`https://happy-pet-fomc.onrender.com/api/employee/customer-points/${maKH}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            const diemHienCo = response.data?.TongDiemTichLuy || 0;
            console.log(`✅ Điểm tích lũy của KH ${maKH}: ${diemHienCo}`);
            
            setInvoiceData({ DiemMuonDung: 0, PhuongThucTT: 'Tiền mặt', DiemHienCo: diemHienCo });
            setInvoiceResult(null);
        } catch (error) {
            console.error('❌ Lỗi lấy điểm tích lũy:', error);
            setInvoiceData({ DiemMuonDung: 0, PhuongThucTT: 'Tiền mặt', DiemHienCo: 0 });
        } finally {
            setLoading(false);
        }
    };

    const confirmExportInvoice = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const response = await axios.post('https://happy-pet-fomc.onrender.com/api/employee/export-invoice', {
                MaPhieu: currentInvoiceTicket.MaPhieu,
                DiemMuonDung: parseInt(invoiceData.DiemMuonDung) || 0,
                PhuongThucTT: invoiceData.PhuongThucTT
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });

            setInvoiceResult(response.data.invoice);
            
            Swal.fire({
                icon: 'success',
                title: 'Xuất hóa đơn thành công!',
                html: `
                    <div style="text-align: left; padding: 15px;">
                        <h4 style="margin-bottom: 15px; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 8px;">
                            📋 HÓA ĐƠN #${response.data.invoice.MaHoaDon}
                        </h4>
                        
                        <div style="margin-bottom: 20px; background: #f8f9fa; padding: 12px; border-radius: 6px;">
                            <p style="margin: 5px 0;"><strong>👤 Khách hàng:</strong> ${currentInvoiceTicket.TenKhachHang}</p>
                            <p style="margin: 5px 0;"><strong>🐾 Thú cưng:</strong> ${currentInvoiceTicket.TenThuCung || 'Chưa rõ'}</p>
                            <p style="margin: 5px 0;"><strong>🏥 Dịch vụ:</strong> ${currentInvoiceTicket.LoaiDichVu}</p>
                        </div>

                        <div style="margin-bottom: 15px;">
                            <p style="margin: 8px 0; font-size: 15px;"><strong>💰 Phí dịch vụ cơ bản:</strong> <span style="color: #7f8c8d;">${response.data.invoice.TienDichVuCoBan} đ</span></p>
                            <p style="margin: 8px 0; font-size: 15px;"><strong>📦 Tổng tiền hàng:</strong> <span style="color: #34495e;">${response.data.invoice.TongTienHang} đ</span></p>
                            <p style="margin: 8px 0; font-size: 14px; color: #e74c3c;">🎁 Giảm hạng TV: -${response.data.invoice.GiamHangTV} đ</p>
                            <p style="margin: 8px 0; font-size: 14px; color: #e74c3c;">🎯 Giảm điểm: -${response.data.invoice.GiamDiem} đ</p>
                        </div>

                        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px; border-radius: 8px; color: white; margin-top: 15px;">
                            <p style="margin: 0; font-size: 18px; font-weight: bold;">💳 Khách cần trả: ${response.data.invoice.KhachCanTra} đ</p>
                            <p style="margin: 8px 0 0 0; font-size: 13px; opacity: 0.9;">💎 Điểm được cộng: +${response.data.invoice.DiemDuocCong} điểm</p>
                        </div>

                        <p style="margin-top: 15px; font-size: 13px; color: #7f8c8d; text-align: center;">
                            💵 Phương thức: <strong>${invoiceData.PhuongThucTT}</strong>
                        </p>
                    </div>
                `,
                width: '550px',
                confirmButtonText: 'Đóng'
            });

            setShowInvoiceModal(false);
            fetchBookings();
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể xuất hóa đơn!', 'error');
        } finally {
            setLoading(false);
        }
    };

    // Handle Walk-in Modal
    const handlePhoneSearch = async () => {
        if (!phoneSearch || phoneSearch.length < 10) {
            return Swal.fire('Lỗi', 'Vui lòng nhập số điện thoại hợp lệ (10 số)!', 'warning');
        }

        setIsSearching(true);
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get(`https://happy-pet-fomc.onrender.com/api/employee/search-customer?sdt=${phoneSearch}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            setSearchResult(res.data);
            setIsSearching(false);
        } catch (error) {
            setIsSearching(false);
            Swal.fire('Lỗi', 'Không thể tìm kiếm khách hàng!', 'error');
        }
    };
    
    const handleWalkInSubmit = async () => {
        if (!walkInData.MaKH || !walkInData.MaTC) {
            return Swal.fire('Lỗi', 'Vui lòng nhập đầy đủ Mã khách hàng và Mã thú cưng!', 'warning');
        }

        try {
            const token = localStorage.getItem('token');
            await axios.post('https://happy-pet-fomc.onrender.com/api/employee/walk-in', walkInData, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            Swal.fire('Thành công', 'Đã tạo phiếu vãng lai!', 'success');
            setShowWalkInModal(false);
            setWalkInData({ MaKH: '', MaTC: '', LoaiPhieu: 'KB', TrieuChung: '' });
            setSearchResult(null);
            setPhoneSearch('');
            setSelectedPet(null);
            fetchBookings(); // Refresh danh sách
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể tạo phiếu!', 'error');
        }
    };
    
    // Handle tạo phiếu cho khách mới (full info)
    const handleNewCustomerSubmit = async () => {
        const finalSDT = newCustomerForm.sdt || phoneSearch;
        
        // Validate
        if (!newCustomerForm.hoTen || !finalSDT || !newCustomerForm.tenPet || !newCustomerForm.loaiPet) {
            return Swal.fire('Lỗi', 'Vui lòng điền đầy đủ thông tin bắt buộc!', 'warning');
        }
        
        if (finalSDT.length !== 10) {
            return Swal.fire('Lỗi', 'Số điện thoại phải có 10 số!', 'warning');
        }
        
        const payload = {
            SDT: finalSDT,
            HoTen: newCustomerForm.hoTen,
            GioiTinhUser: newCustomerForm.gioiTinhUser || 'Nam',
            DiaChi: newCustomerForm.diaChi || '',
            TenTC: newCustomerForm.tenPet,
            Loai: newCustomerForm.loaiPet,
            Giong: newCustomerForm.giongPet || 'Chưa rõ',
            GioiTinh: newCustomerForm.gioiTinhPet || 'Đực',
            NgSinh: newCustomerForm.ngaySinhPet || null,
            TinhTrangSucKhoe: newCustomerForm.tinhTrangSucKhoe || 'Bình thường',
            LoaiPhieu: newCustomerForm.loaiPhieu,
            TrieuChung: newCustomerForm.trieuChung || ''
        };
        
        console.log('🔍 Payload gửi đi:', payload);
        
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const res = await axios.post('https://happy-pet-fomc.onrender.com/api/employee/walk-in-full', payload, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            Swal.fire({
                icon: 'success',
                title: 'Thành công!',
                html: `
                    <div style="text-align: left;">
                        <p><strong>✅ Đã tạo phiếu vãng lai!</strong></p>
                        <p>📝 Mã phiếu: <strong>${res.data.data.MaPhieuMoi}</strong></p>
                        <p>👤 Khách hàng: ${res.data.data.TenKhachHang}</p>
                        <p>🐾 Thú cưng: ${res.data.data.TenThuCung}</p>
                    </div>
                `,
                confirmButtonText: 'Đóng'
            });
            
            resetWalkInModal();
            fetchBookings(); // Refresh danh sách
        } catch (error) {
            console.error('❌ Lỗi tạo phiếu khách mới:', error);
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể tạo phiếu!', 'error');
        } finally {
            setLoading(false);
        }
    };
    
    const handleSelectPet = (pet) => {
        setSelectedPet(pet);
        setWalkInData({
            ...walkInData,
            MaKH: searchResult.customer.MaKH,
            MaTC: pet.MaTC
        });
    };
    
    const resetWalkInModal = () => {
        setShowWalkInModal(false);
        setSearchResult(null);
        setPhoneSearch('');
        setSelectedPet(null);
        setWalkInData({ MaKH: '', MaTC: '', LoaiPhieu: 'KB', TrieuChung: '' });
        setNewCustomerForm({
            hoTen: '', gioiTinhUser: 'Nam', sdt: '', diaChi: '', tenPet: '', loaiPet: '', 
            giongPet: '', gioiTinhPet: 'Đực', ngaySinhPet: '', tinhTrangSucKhoe: 'Bình thường', loaiPhieu: 'KB', trieuChung: ''
        });
    };

    const formatTime = (dateStr) => dayjs(dateStr).format('HH:mm DD/MM');

    // 5. Render Status Badge
    const renderStatus = (status) => {
        switch (status) {
            case 'DD': return <span className="status-badge status-waiting">🔵 Chờ Check-in</span>;
            case 'DTH': return <span className="status-badge status-shipping">💉 Đang thực hiện</span>;
            case 'DHT': 
            case 'HT': return <span className="status-badge status-done">✅ Hoàn tất</span>;
            case 'DH': return <span className="status-badge status-cancel">❌ Đã hủy</span>;
            default: return <span className="status-badge">{status}</span>;
        }
    };

    return (
        <div className="dashboard-container">
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px'}}>
                <div>
                    <h2 className="dashboard-title">🏥 Quản Lý Dịch Vụ Thú Cưng</h2>
                    <p className="dashboard-subtitle">Quản lý check-in khám bệnh, tiêm vaccine và điều phối bác sĩ.</p>
                </div>
                <button 
                    className="btn-primary" 
                    onClick={() => setShowWalkInModal(true)}
                    style={{padding: '12px 24px', fontSize: '16px', fontWeight: 'bold'}}
                >
                    ➕ Tạo phiếu vãng lai
                </button>
            </div>

            {/* TABS THỜI GIAN */}
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

            {/* FILTER TRẠNG THÁI (Đã thêm mục ĐÃ HỦY) */}
            <div className="tab-sub-filter">
                <div className={`filter-pill ${statusTab === 'all' ? 'active' : ''}`} onClick={() => setStatusTab('all')}>
                    Tất cả <span className="badge-count">{bookings.length}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'DD' ? 'active' : ''}`} onClick={() => setStatusTab('DD')}>
                    Chờ Check-in <span className="badge-count">{countStatus('DD')}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'DTH' ? 'active' : ''}`} onClick={() => setStatusTab('DTH')}>
                    Đang thực hiện <span className="badge-count">{countStatus('DTH')}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'HT_GROUP' ? 'active' : ''}`} onClick={() => setStatusTab('HT_GROUP')}>
                    Hoàn tất <span className="badge-count">{countStatus('HT_GROUP')}</span>
                </div>
                <div className={`filter-pill ${statusTab === 'DH' ? 'active' : ''}`} onClick={() => setStatusTab('DH')}>
                    Đã hủy <span className="badge-count">{countStatus('DH')}</span>
                </div>
            </div>

            {/* BẢNG DỮ LIỆU */}
            <div className="table-card">
                <table className="booking-table">
                    <thead>
                        <tr>
                            <th>Mã phiếu</th>
                            <th>Loại DV</th>
                            <th>Khách hàng & Pet</th>
                            <th>Lịch hẹn</th>
                            <th>Bác sĩ phụ trách</th>
                            <th>Trạng thái</th>
                            <th>Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan="7" style={{textAlign: 'center', padding: '30px', color: '#888'}}>⏳ Đang tải dữ liệu...</td></tr>
                        ) : filteredBookings.length === 0 ? (
                            <tr><td colSpan="7" style={{textAlign: 'center', padding: '40px', color: '#999'}}>
                                <div style={{fontSize: '40px', marginBottom: '10px'}}>📭</div>
                                Không có lịch hẹn nào.
                            </td></tr>
                        ) : (
                            filteredBookings.map((item, index) => (
                                <tr key={index}>
                                    <td><strong>#{item.MaPhieu}</strong></td>
                                    <td>
                                        {item.LoaiDichVu === 'Khám bệnh' 
                                            ? <span style={{color:'#e67e22', fontWeight:'bold'}}>🩺 Khám bệnh</span> 
                                            : <span style={{color:'#2980b9', fontWeight:'bold'}}>💉 Tiêm vaccine</span>
                                        }
                                    </td>
                                    <td>
                                        <div style={{fontWeight: '600'}}>{item.TenKhachHang}</div>
                                        <div className="text-muted">📞 {item.SDT}</div>
                                        <div className="text-muted">🐶 {item.TenThuCung || 'Chưa rõ'}</div>
                                    </td>
                                    <td style={{fontWeight:'500'}}>{formatTime(item.TG_ThucHienDV)}</td>
                                    <td>{item.TenBacSi ? `👨‍⚕️ ${item.TenBacSi}` : <span style={{color:'#bdc3c7', fontStyle:'italic'}}>Chưa chỉ định</span>}</td>
                                    <td>{renderStatus(item.TrangThai)}</td>
                                    <td>
                                        {item.TrangThai === 'DD' && (() => {
                                            const appointmentDate = dayjs(item.TG_ThucHienDV);
                                            const today = dayjs();
                                            const canCheckIn = appointmentDate.isSame(today, 'day') || appointmentDate.isBefore(today, 'day');
                                            
                                            return (
                                                <button 
                                                    className="btn-check-in" 
                                                    onClick={() => handleCheckIn(item)}
                                                    disabled={!canCheckIn}
                                                    style={{ opacity: canCheckIn ? 1 : 0.5, cursor: canCheckIn ? 'pointer' : 'not-allowed' }}
                                                    title={canCheckIn ? 'Click để check-in' : `Chỉ được check-in từ ngày ${appointmentDate.format('DD/MM/YYYY')}`}
                                                >
                                                    Check-in
                                                </button>
                                            );
                                        })()}
                                        
                                        {item.TrangThai === 'DHT' && (
                                            (item.MaNV_XuatHD && item.MaNV_XuatHD.trim() !== item.MaNV_BacSi?.trim()) ? (
                                                // Đã xuất hóa đơn (MaNV khác bác sĩ = đã đổi thành nhân viên tiếp tán)
                                                <span 
                                                    style={{
                                                        backgroundColor: '#27ae60',
                                                        color: 'white',
                                                        padding: '8px 16px',
                                                        borderRadius: '20px',
                                                        fontSize: '14px',
                                                        fontWeight: '500',
                                                        display: 'inline-flex',
                                                        alignItems: 'center',
                                                        gap: '6px'
                                                    }}
                                                >
                                                    <i className="fas fa-check-circle"></i>
                                                    Đã xuất hóa đơn
                                                </span>
                                            ) : (
                                                // Chưa xuất hóa đơn (MaNV vẫn là bác sĩ)
                                                <button 
                                                    className="btn-check-in" 
                                                    onClick={() => handleExportInvoice(item)}
                                                    style={{ background: '#27ae60' }}
                                                >
                                                    💳 Xuất hóa đơn
                                                </button>
                                            )
                                        )}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* MODAL CHECK-IN */}
            {showDoctorModal && (
                <div className="modal-overlay" onClick={() => setShowDoctorModal(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <h3>🩺 Check-in & Chọn Bác Sĩ</h3>
                        <p style={{marginBottom: '10px', fontSize: '0.9rem', color: '#666'}}>
                            Chỉ định bác sĩ cho phiếu: <strong>#{currentTicket?.MaPhieu}</strong>
                        </p>
                        
                        <select 
                            className="form-select-custom"
                            value={selectedDoctor} 
                            onChange={(e) => setSelectedDoctor(e.target.value)}
                        >
                            <option value="">-- Chọn bác sĩ --</option>
                            {doctors.map((doc) => (
                                <option key={doc.MaNV} value={doc.MaNV} disabled={doc.TrangThai === 'Bận'}>
                                    {doc.TenNV} {doc.TrangThai === 'Bận' ? '(❌ Bận)' : '(✅ Rảnh)'}
                                </option>
                            ))}
                        </select>

                        <div className="modal-actions">
                            <button onClick={() => setShowDoctorModal(false)} className="btn-cancel">Hủy</button>
                            <button onClick={confirmCheckIn} disabled={loading} className="btn-check-in">
                                {loading ? 'Đang xử lý...' : 'Xác nhận Check-in'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* MODAL WALK-IN */}
            {showWalkInModal && (
                <div className="modal-overlay" onClick={resetWalkInModal}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{maxWidth: '700px', maxHeight: '90vh', overflowY: 'auto'}}>
                        <h3>🏥 Tạo Phiếu Vãng Lai</h3>
                        
                        {/* BƯỚC 1: TÌM KIẾM SĐT */}
                        {!searchResult && (
                            <div>
                                <p style={{marginBottom: '15px', fontSize: '0.9rem', color: '#666'}}>
                                    Nhập số điện thoại khách hàng để tìm kiếm
                                </p>
                                
                                <div style={{display: 'flex', gap: '10px', marginBottom: '20px'}}>
                                    <input 
                                        type="text"
                                        placeholder="Nhập SĐT (10 số)"
                                        value={phoneSearch}
                                        onChange={(e) => setPhoneSearch(e.target.value)}
                                        maxLength="10"
                                        style={{flex: 1, padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '16px'}}
                                    />
                                    <button 
                                        onClick={handlePhoneSearch} 
                                        disabled={isSearching}
                                        style={{padding: '10px 20px', background: '#2196f3', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold'}}
                                    >
                                        {isSearching ? '⏳ Đang tìm...' : '🔍 Tìm'}
                                    </button>
                                </div>
                                
                                <button onClick={resetWalkInModal} className="btn-cancel" style={{width: '100%'}}>
                                    Hủy
                                </button>
                            </div>
                        )}
                        
                        {/* BƯỚC 2A: KHÁCH CŨ - CHỌN THÚ CƯNG */}
                        {searchResult && searchResult.found && (
                            <div>
                                <div style={{background: '#e8f5e9', padding: '15px', borderRadius: '8px', marginBottom: '20px'}}>
                                    <h4 style={{margin: '0 0 10px 0', color: '#2e7d32'}}>✅ Tìm thấy khách hàng</h4>
                                    <p style={{margin: '5px 0'}}><strong>Họ tên:</strong> {searchResult.customer.HoTen}</p>
                                    <p style={{margin: '5px 0'}}><strong>SĐT:</strong> {searchResult.customer.SDT}</p>
                                    <p style={{margin: '5px 0'}}><strong>Email:</strong> {searchResult.customer.Email || 'N/A'}</p>
                                    <p style={{margin: '5px 0'}}><strong>Điểm tích lũy:</strong> {searchResult.customer.TongDiemTichLuy || 0} điểm</p>
                                </div>
                                
                                <h4 style={{marginBottom: '10px'}}>🐾 Chọn thú cưng cần khám/tiêm:</h4>
                                <div style={{display: 'grid', gap: '10px', marginBottom: '20px'}}>
                                    {searchResult.pets.map((pet) => (
                                        <div 
                                            key={pet.MaTC}
                                            onClick={() => handleSelectPet(pet)}
                                            style={{
                                                padding: '12px',
                                                border: selectedPet?.MaTC === pet.MaTC ? '3px solid #2196f3' : '1px solid #ddd',
                                                borderRadius: '8px',
                                                cursor: 'pointer',
                                                background: selectedPet?.MaTC === pet.MaTC ? '#e3f2fd' : 'white',
                                                transition: 'all 0.2s'
                                            }}
                                        >
                                            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                                                <div>
                                                    <div style={{fontWeight: 'bold', fontSize: '16px'}}>{pet.Ten}</div>
                                                    <div style={{color: '#666', fontSize: '13px'}}>
                                                        {pet.Loai} - {pet.Giong || 'N/A'} - {pet.GioiTinh} - 
                                                        Sinh: {pet.NgSinh ? dayjs(pet.NgSinh).format('DD/MM/YYYY') : 'N/A'}
                                                    </div>
                                                    <div style={{color: pet.TinhTrangSucKhoe === 'Tốt' ? 'green' : 'orange', fontSize: '12px', marginTop: '3px'}}>
                                                        Sức khỏe: {pet.TinhTrangSucKhoe || 'N/A'}
                                                    </div>
                                                </div>
                                                {selectedPet?.MaTC === pet.MaTC && <span style={{fontSize: '24px'}}>✅</span>}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                                
                                {/* LỊCH SỬ KHÁM */}
                                {searchResult.history.length > 0 && (
                                    <div style={{marginBottom: '20px'}}>
                                        <h4 style={{marginBottom: '10px'}}>📋 Lịch sử khám gần đây:</h4>
                                        <div style={{maxHeight: '150px', overflowY: 'auto', border: '1px solid #ddd', borderRadius: '5px', padding: '10px', fontSize: '13px'}}>
                                            {searchResult.history.map((item, idx) => (
                                                <div key={idx} style={{marginBottom: '8px', paddingBottom: '8px', borderBottom: idx < searchResult.history.length - 1 ? '1px solid #eee' : 'none'}}>
                                                    <div><strong>{dayjs(item.NgayKham).format('DD/MM/YYYY HH:mm')}</strong> - {item.LoaiDV}</div>
                                                    <div style={{color: '#666'}}>BS: {item.BacSi || 'N/A'} | Chẩn đoán: {item.ChanDoan}</div>
                                                    <div style={{color: '#999', fontSize: '11px'}}>Trạng thái: {item.TrangThai}</div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}
                                
                                {/* FORM DỊCH VỤ */}
                                {selectedPet && (
                                    <div style={{background: '#f5f5f5', padding: '15px', borderRadius: '8px'}}>
                                        <h4 style={{marginBottom: '10px'}}>📝 Thông tin dịch vụ:</h4>
                                        <select 
                                            value={walkInData.LoaiPhieu}
                                            onChange={(e) => setWalkInData({...walkInData, LoaiPhieu: e.target.value})}
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', marginBottom: '10px'}}
                                        >
                                            <option value="KB">Khám bệnh</option>
                                            <option value="TV">Tiêm vaccine</option>
                                        </select>
                                        
                                        {walkInData.LoaiPhieu === 'TV' && (
                                            <div style={{padding: '12px', background: '#e3f2fd', borderRadius: '5px', marginBottom: '10px', fontSize: '14px'}}>
                                                ℹ️ <strong>Lưu ý:</strong> Bác sĩ sẽ chọn vaccine/gói tiêm sau khi check-in
                                            </div>
                                        )}
                                        
                                        <textarea 
                                            placeholder="Triệu chứng / Ghi chú"
                                            value={walkInData.TrieuChung}
                                            onChange={(e) => setWalkInData({...walkInData, TrieuChung: e.target.value})}
                                            rows="3"
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', resize: 'vertical'}}
                                        />
                                    </div>
                                )}
                                
                                <div style={{display: 'flex', gap: '10px', marginTop: '20px'}}>
                                    <button onClick={resetWalkInModal} className="btn-cancel" style={{flex: 1}}>
                                        Hủy
                                    </button>
                                    <button 
                                        onClick={handleWalkInSubmit} 
                                        disabled={!selectedPet}
                                        className="btn-primary" 
                                        style={{flex: 1, opacity: !selectedPet ? 0.5 : 1, cursor: !selectedPet ? 'not-allowed' : 'pointer'}}
                                    >
                                        Tạo phiếu
                                    </button>
                                </div>
                            </div>
                        )}
                        
                        {/* BƯỚC 2B: KHÁCH MỚI - FORM ĐĂNG KÝ */}
                        {searchResult && !searchResult.found && (
                            <div>
                                <div style={{background: '#fff3e0', padding: '15px', borderRadius: '8px', marginBottom: '20px', textAlign: 'center'}}>
                                    <h4 style={{margin: '0 0 5px 0', color: '#e65100'}}>👋 Chào mừng khách hàng mới!</h4>
                                    <p style={{margin: '0', fontSize: '14px', color: '#666'}}>
                                        Số điện thoại <strong>{phoneSearch}</strong> chưa có trong hệ thống
                                    </p>
                                </div>
                                
                                <div style={{marginBottom: '20px'}}>
                                    <h4 style={{marginBottom: '15px', color: '#2c3e50'}}>📋 Thông tin khách hàng</h4>
                                    
                                    <div style={{marginBottom: '12px'}}>
                                        <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                            👤 Họ tên <span style={{color: 'red'}}>*</span>
                                        </label>
                                        <input 
                                            type="text"
                                            placeholder="Nhập họ tên khách hàng"
                                            value={newCustomerForm.hoTen}
                                            onChange={(e) => setNewCustomerForm({...newCustomerForm, hoTen: e.target.value})}
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                        />
                                    </div>
                                    
                                    <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '12px'}}>
                                        <div>
                                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                                📱 Số điện thoại <span style={{color: 'red'}}>*</span>
                                            </label>
                                            <input 
                                                type="text"
                                                placeholder="Nhập SĐT (10 số)"
                                                value={newCustomerForm.sdt || phoneSearch}
                                                onChange={(e) => setNewCustomerForm({...newCustomerForm, sdt: e.target.value})}
                                                maxLength="10"
                                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                            />
                                        </div>
                                        
                                        <div>
                                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                                ⚥ Giới tính <span style={{color: 'red'}}>*</span>
                                            </label>
                                            <select
                                                value={newCustomerForm.gioiTinhUser}
                                                onChange={(e) => setNewCustomerForm({...newCustomerForm, gioiTinhUser: e.target.value})}
                                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                            >
                                                <option value="Nam">Nam</option>
                                                <option value="Nữ">Nữ</option>
                                            </select>
                                        </div>
                                    </div>
                                    
                                    <div style={{marginBottom: '12px'}}>
                                        <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                            🏠 Địa chỉ
                                        </label>
                                        <input 
                                            type="text"
                                            placeholder="Nhập địa chỉ (tùy chọn)"
                                            value={newCustomerForm.diaChi}
                                            onChange={(e) => setNewCustomerForm({...newCustomerForm, diaChi: e.target.value})}
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                        />
                                    </div>
                                </div>
                                
                                <div style={{borderTop: '2px dashed #ddd', paddingTop: '20px', marginBottom: '20px'}}>
                                    <h4 style={{marginBottom: '15px', color: '#2c3e50'}}>🐾 Thông tin thú cưng</h4>
                                    
                                    <div style={{marginBottom: '12px'}}>
                                        <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                            🐶 Tên thú cưng <span style={{color: 'red'}}>*</span>
                                        </label>
                                        <input 
                                            type="text"
                                            placeholder="Nhập tên thú cưng"
                                            value={newCustomerForm.tenPet}
                                            onChange={(e) => setNewCustomerForm({...newCustomerForm, tenPet: e.target.value})}
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                        />
                                    </div>
                                    
                                    <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '12px'}}>
                                        <div>
                                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                                🦴 Loại <span style={{color: 'red'}}>*</span>
                                            </label>
                                            <select
                                                value={newCustomerForm.loaiPet}
                                                onChange={(e) => setNewCustomerForm({...newCustomerForm, loaiPet: e.target.value})}
                                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                            >
                                                <option value="">-- Chọn loại --</option>
                                                <option value="Chó">Chó</option>
                                                <option value="Mèo">Mèo</option>
                                                <option value="Khác">Khác</option>
                                            </select>
                                        </div>
                                        
                                        <div>
                                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                                ⚥ Giới tính <span style={{color: 'red'}}>*</span>
                                            </label>
                                            <select
                                                value={newCustomerForm.gioiTinhPet}
                                                onChange={(e) => setNewCustomerForm({...newCustomerForm, gioiTinhPet: e.target.value})}
                                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                            >
                                                <option value="Đực">Đực</option>
                                                <option value="Cái">Cái</option>
                                            </select>
                                        </div>
                                    </div>
                                    
                                    <div style={{marginBottom: '12px'}}>
                                        <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                            🧬 Giống
                                        </label>
                                        <input 
                                            type="text"
                                            placeholder="VD: Corgi, Munchkin..."
                                            value={newCustomerForm.giongPet}
                                            onChange={(e) => setNewCustomerForm({...newCustomerForm, giongPet: e.target.value})}
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                        />
                                    </div>
                                    
                                    <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '12px'}}>
                                        <div>
                                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                                🎂 Ngày sinh
                                            </label>
                                            <input 
                                                type="date"
                                                value={newCustomerForm.ngaySinhPet}
                                                onChange={(e) => setNewCustomerForm({...newCustomerForm, ngaySinhPet: e.target.value})}
                                                max={dayjs().format('YYYY-MM-DD')}
                                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                            />
                                        </div>
                                        
                                        <div>
                                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                                💪 Tình trạng sức khỏe
                                            </label>
                                            <select
                                                value={newCustomerForm.tinhTrangSucKhoe}
                                                onChange={(e) => setNewCustomerForm({...newCustomerForm, tinhTrangSucKhoe: e.target.value})}
                                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                            >
                                                <option value="Bình thường">Bình thường</option>
                                                <option value="Tốt">Tốt</option>
                                                <option value="Yếu">Yếu</option>
                                                <option value="Đang điều trị">Đang điều trị</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                
                                <div style={{borderTop: '2px dashed #ddd', paddingTop: '20px', marginBottom: '20px'}}>
                                    <h4 style={{marginBottom: '15px', color: '#2c3e50'}}>🏥 Thông tin dịch vụ</h4>
                                    
                                    <div style={{marginBottom: '12px'}}>
                                        <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                            📋 Loại dịch vụ <span style={{color: 'red'}}>*</span>
                                        </label>
                                        <select
                                            value={newCustomerForm.loaiPhieu}
                                            onChange={(e) => setNewCustomerForm({...newCustomerForm, loaiPhieu: e.target.value})}
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                                        >
                                            <option value="KB">🩺 Khám bệnh</option>
                                            <option value="TV">💉 Tiêm vaccine</option>
                                        </select>
                                    </div>
                                    
                                    {newCustomerForm.loaiPhieu === 'TV' && (
                                        <div style={{padding: '12px', background: '#e3f2fd', borderRadius: '5px', marginBottom: '12px', fontSize: '14px'}}>
                                            ℹ️ <strong>Lưu ý:</strong> Bác sĩ sẽ chọn vaccine/gói tiêm sau khi check-in
                                        </div>
                                    )}
                                    
                                    <div style={{marginBottom: '12px'}}>
                                        <label style={{display: 'block', marginBottom: '5px', fontWeight: '600', fontSize: '14px'}}>
                                            📝 Triệu chứng / Ghi chú
                                        </label>
                                        <textarea 
                                            placeholder="Mô tả triệu chứng, lý do đến khám..."
                                            value={newCustomerForm.trieuChung}
                                            onChange={(e) => setNewCustomerForm({...newCustomerForm, trieuChung: e.target.value})}
                                            rows="3"
                                            style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', resize: 'vertical', fontSize: '15px'}}
                                        />
                                    </div>
                                </div>
                                
                                <div style={{display: 'flex', gap: '10px'}}>
                                    <button onClick={resetWalkInModal} className="btn-cancel" style={{flex: 1}}>
                                        Hủy
                                    </button>
                                    <button 
                                        onClick={handleNewCustomerSubmit}
                                        disabled={loading || !newCustomerForm.hoTen || !(newCustomerForm.sdt || phoneSearch) || !newCustomerForm.tenPet || !newCustomerForm.loaiPet}
                                        className="btn-primary" 
                                        style={{
                                            flex: 2, 
                                            opacity: (!newCustomerForm.hoTen || !(newCustomerForm.sdt || phoneSearch) || !newCustomerForm.tenPet || !newCustomerForm.loaiPet) ? 0.5 : 1,
                                            cursor: (!newCustomerForm.hoTen || !(newCustomerForm.sdt || phoneSearch) || !newCustomerForm.tenPet || !newCustomerForm.loaiPet) ? 'not-allowed' : 'pointer'
                                        }}
                                    >
                                        {loading ? '⏳ Đang tạo...' : '✅ Tạo phiếu'}
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* MODAL XUẤT HÓA ĐƠN */}
            {showInvoiceModal && (
                <div className="modal-overlay" onClick={() => setShowInvoiceModal(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{maxWidth: '500px'}}>
                        <h3>💳 Xuất Hóa Đơn</h3>
                        <p style={{marginBottom: '15px', fontSize: '0.9rem', color: '#666'}}>
                            Phiếu: <strong>#{currentInvoiceTicket?.MaPhieu}</strong>
                        </p>

                        <div style={{marginBottom: '20px', background: '#f8f9fa', padding: '15px', borderRadius: '8px'}}>
                            <div style={{marginBottom: '10px'}}>
                                <strong>👤 Khách hàng:</strong> {currentInvoiceTicket?.TenKhachHang}
                            </div>
                            <div style={{marginBottom: '10px'}}>
                                <strong>🐾 Thú cưng:</strong> {currentInvoiceTicket?.TenThuCung || 'Chưa rõ'}
                            </div>
                            <div>
                                <strong>🏥 Dịch vụ:</strong> {currentInvoiceTicket?.LoaiDichVu}
                            </div>
                        </div>
                        
                        <div style={{marginBottom: '15px'}}>
                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600'}}>
                                🎯 Điểm tích lũy muốn sử dụng:
                                <span style={{color: '#27ae60', fontWeight: 'bold', marginLeft: '10px'}}>
                                    (Hiện có: {invoiceData.DiemHienCo || 0} điểm)
                                </span>
                            </label>
                            <input 
                                type="number"
                                min="0"
                                max={invoiceData.DiemHienCo || 0}
                                value={invoiceData.DiemMuonDung}
                                onChange={(e) => {
                                    const value = parseInt(e.target.value) || 0;
                                    const maxDiem = invoiceData.DiemHienCo || 0;
                                    setInvoiceData({...invoiceData, DiemMuonDung: Math.min(value, maxDiem)});
                                }}
                                placeholder={invoiceData.DiemHienCo > 0 ? "Nhập số điểm (1 điểm = 1.000 đ)" : "Không có điểm"}
                                disabled={!invoiceData.DiemHienCo || invoiceData.DiemHienCo === 0}
                                style={{
                                    width: '100%', 
                                    padding: '10px', 
                                    border: '1px solid #ddd', 
                                    borderRadius: '5px', 
                                    fontSize: '15px',
                                    background: (!invoiceData.DiemHienCo || invoiceData.DiemHienCo === 0) ? '#f0f0f0' : 'white',
                                    cursor: (!invoiceData.DiemHienCo || invoiceData.DiemHienCo === 0) ? 'not-allowed' : 'text'
                                }}
                            />
                            <small style={{color: '#7f8c8d', fontSize: '12px'}}>
                                {invoiceData.DiemHienCo > 0 
                                    ? `Lưu ý: 1 điểm = 1.000 đ giảm giá (Tối đa: ${invoiceData.DiemHienCo} điểm)` 
                                    : '⚠️ Khách hàng chưa có điểm tích lũy'}
                            </small>
                        </div>

                        <div style={{marginBottom: '20px'}}>
                            <label style={{display: 'block', marginBottom: '5px', fontWeight: '600'}}>
                                💵 Phương thức thanh toán:
                            </label>
                            <select
                                value={invoiceData.PhuongThucTT}
                                onChange={(e) => setInvoiceData({...invoiceData, PhuongThucTT: e.target.value})}
                                style={{width: '100%', padding: '10px', border: '1px solid #ddd', borderRadius: '5px', fontSize: '15px'}}
                            >
                                <option value="Tiền mặt">💵 Tiền mặt</option>
                                <option value="Chuyển khoản">🏦 Chuyển khoản</option>
                            </select>
                        </div>

                        <div className="modal-actions">
                            <button onClick={() => setShowInvoiceModal(false)} className="btn-cancel">Hủy</button>
                            <button 
                                onClick={confirmExportInvoice} 
                                disabled={loading} 
                                className="btn-check-in"
                                style={{background: '#27ae60'}}
                            >
                                {loading ? 'Đang xử lý...' : '✅ Xác nhận xuất'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ServiceBookings;