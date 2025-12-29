
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2'; 
import './Booking.css'; 

const Booking = () => {
    const navigate = useNavigate();
    
    const [branches, setBranches] = useState([]);
    const [pets, setPets] = useState([]);
    const [selectedBranchInfo, setSelectedBranchInfo] = useState(null);
    const [timeSlots, setTimeSlots] = useState([]); 

    const [formData, setFormData] = useState({
        MaTC: '',
        MaCN: '',
        LoaiPhieu: '', // Để rỗng ban đầu, chờ chọn chi nhánh mới set
        NgayHen: '',
        GioHen: '',
        TrieuChung: ''
    });

    const [loading, setLoading] = useState(false);

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const token = localStorage.getItem('token');
            const [resBranches, resPets] = await Promise.all([
                axios.get('http://localhost:5000/api/booking/branches'),
                axios.get('http://localhost:5000/api/pets/my-pets', { headers: { Authorization: `Bearer ${token}` } })
            ]);

            setBranches(resBranches.data);
            setPets(resPets.data);
            
            if (resBranches.data.length > 0) {
                const first = resBranches.data[0];
                handleBranchSelect(first); 
            }
            if (resPets.data.length > 0) {
                setFormData(prev => ({ ...prev, MaTC: resPets.data[0].MaTC }));
            }
        } catch (error) {
            console.error("Lỗi:", error);
        }
    };

    const getSafeTime = (val) => {
        if (!val) return null;
        if (typeof val === 'object') return val.toISOString().split('T')[1].substring(0, 5);
        return val.toString().substring(0, 5);
    };

    const generateTimeSlots = (startStr, endStr) => {
        if (!startStr || !endStr) return;
        const parseTime = (str) => {
            const [h, m] = str.split(':').map(Number);
            return h * 60 + m; 
        };
        let s = getSafeTime(startStr);
        let e = getSafeTime(endStr);
        if(!s || !e) return;

        let start = parseTime(s);
        let end = parseTime(e);
        let slots = [];
        
        for (let time = start; time < end; time += 60) { 
            const h = Math.floor(time / 60).toString().padStart(2, '0');
            const m = (time % 60).toString().padStart(2, '0');
            slots.push(`${h}:${m}`);
        }
        setTimeSlots(slots);
    };

    // --- HÀM XỬ LÝ CHỌN CHI NHÁNH (LOGIC MỚI CỰC CHUẨN) ---
    const handleBranchSelect = (branch) => {
        setSelectedBranchInfo(branch);
        
        // 1. Tạo khung giờ
        const start = branch.GioMoCua || branch.Giomocua; 
        const end = branch.GioDongCua || branch.Giodongcua;
        generateTimeSlots(start, end);

        // 2. LOGIC TỰ ĐỘNG CHỌN DỊCH VỤ
        // Kiểm tra xem chi nhánh này có gì
        const servicesStr = branch.DichVuHoTro ? branch.DichVuHoTro.toLowerCase() : "";
        const hasKham = servicesStr.includes('khám');
        const hasTiem = servicesStr.includes('tiêm') || servicesStr.includes('vaccine');

        let defaultService = '';

        // Logic ưu tiên: 
        // Nếu có Khám -> Mặc định chọn Khám (KB)
        // Nếu không có Khám mà có Tiêm -> Chọn Tiêm (TV)
        // Nếu không có cả hai -> Để rỗng
        if (hasKham) {
            defaultService = 'KB';
        } else if (hasTiem) {
            defaultService = 'TV';
        }

        // Cập nhật State
        setFormData(prev => ({ 
            ...prev, 
            MaCN: branch.MaCN, 
            GioHen: '', 
            LoaiPhieu: defaultService // Tự động nhảy sang dịch vụ hợp lệ
        }));
    };

    const handleBranchChange = (e) => {
        const maCN = e.target.value;
        const branch = branches.find(b => b.MaCN === maCN);
        if (branch) handleBranchSelect(branch);
    };

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleViewDoctorSchedule = async () => {
        try {
            const maCNQuery = formData.MaCN ? `?MaCN=${formData.MaCN}` : '';
            const res = await axios.get(`http://localhost:5000/api/booking/doctors${maCNQuery}`);
            const doctors = res.data;

            if (doctors.length === 0) {
                Swal.fire('Thông báo', 'Chi nhánh này hiện chưa có thông tin bác sĩ.', 'info');
                return;
            }

            const htmlContent = `
                <div style="text-align: left; max-height: 300px; overflow-y: auto;">
                    <table style="width:100%; border-collapse: collapse; font-size: 14px;">
                        <thead style="position: sticky; top: 0; background: #f2f2f2;">
                            <tr>
                                <th style="padding:8px; border:1px solid #ddd;">Bác sĩ 👨‍⚕️</th>
                                <th style="padding:8px; border:1px solid #ddd;">Chi nhánh 🏥</th>
                                <th style="padding:8px; border:1px solid #ddd;">Ca làm việc ⏰</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${doctors.map(d => `
                                <tr>
                                    <td style="padding:8px; border:1px solid #ddd; vertical-align: middle;">
                                        <div style="font-weight:bold; color:#2c3e50; font-size: 15px;">
                                            ${d.TenBacSi || d.HoTen} 
                                        </div>
                                        
                                        <div style="color:#666; font-size: 12px; margin-top: 2px;">
                                            ${d.Chucvu || d.ChucVu || 'Bác sĩ thú y'}
                                        </div>
                                    </td>

                                    <td style="padding:8px; border:1px solid #ddd; vertical-align: middle;">
                                        ${d.ChiNhanh || d.TenCN || 'Chi nhánh hệ thống'}
                                    </td>
                                    
                                    <td style="padding:8px; border:1px solid #ddd; vertical-align: middle;">
                                        <div style="font-weight:bold; color: #2196f3;">
                                            ${d.GioBatDau} - ${d.GioKetThuc}
                                        </div>

                                        <div style="margin-top:4px; font-weight:bold; 
                                            color:${(d.TrangThaiHienTai === 'Đang trực' || d.TrangThaiHienTai === 'Đang trong ca trực') ? '#28a745' : '#dc3545'}">
                                            
                                            (${d.TrangThaiHienTai || 'Đã tan ca'})
                                        </div>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
            Swal.fire({ title: 'Danh Sách Bác Sĩ Trực', html: htmlContent, width: '600px', confirmButtonText: 'Đóng' });
        } catch (error) {
            Swal.fire('Lỗi', 'Không thể tải danh sách bác sĩ', 'error');
        }
    };

    const handleSubmit = async (e) => {
            e.preventDefault();
            setLoading(true);
            try {
                const token = localStorage.getItem('token');
                
                // Gọi API tạo phiếu
                const res = await axios.post('http://localhost:5000/api/booking/create', formData, {
                    headers: { Authorization: `Bearer ${token}` }
                });

                // --- XỬ LÝ CHUYỂN HƯỚNG ---
                if (formData.LoaiPhieu === 'TV') {
                    // TRƯỜNG HỢP 1: Tiêm Vaccine -> Chuyển qua trang chọn thuốc (Giữ nguyên logic cũ)
                    Swal.fire({
                        icon: 'success',
                        title: 'Tạo phiếu tiêm thành công!',
                        text: 'Chuyển đến bước chọn Vaccine...',
                        timer: 1500,
                        showConfirmButton: false
                    }).then(() => {
                        navigate('/select-vaccine', { state: { MaPhieu: res.data.MaPhieu } }); 
                    });

                } else {
                    // TRƯỜNG HỢP 2: Khám Bệnh -> CHUYỂN THẲNG QUA LỊCH SỬ
                    Swal.fire({
                        icon: 'success',
                        title: 'Đặt lịch thành công! 🎉',
                        text: 'Hệ thống sẽ chuyển đến trang quản lý lịch hẹn ngay bây giờ.',
                        timer: 2000, // Hiện thông báo 2 giây rồi tự chuyển
                        showConfirmButton: false
                    }).then(() => {
                        // 👇 DÒNG QUAN TRỌNG NHẤT NẰM Ở ĐÂY 👇
                        navigate('/my-bookings'); 
                    });
                }

            } catch (error) {
                const msg = error.response?.data?.message || "Đặt lịch thất bại";
                Swal.fire('Lỗi', msg, 'error');
            } finally {
                setLoading(false);
            }
        };
    const displayTime = (val) => {
        const t = getSafeTime(val);
        return t ? t : '-';
    }

    return (
        <div className="booking-container">
            <h2 className="booking-title">📅 Đặt Lịch Hẹn</h2>
            
            <form onSubmit={handleSubmit} className="booking-form">
                
                {/* 1. CHỌN BÉ CƯNG */}
                <div className="form-group">
                    <label>Chọn Bé Cưng: <span style={{color:'red'}}>*</span></label>
                    {pets.length === 0 ? (
                        <p style={{color:'red'}}>Bạn chưa có thú cưng nào.</p>
                    ) : (
                        <select name="MaTC" value={formData.MaTC} onChange={handleChange} required className="input-field">
                            {pets.map(pet => (
                                <option key={pet.MaTC} value={pet.MaTC}>
                                    {pet.Ten} - {pet.Loai} ({pet.Giong})
                                </option>
                            ))}
                        </select>
                    )}
                </div>

                {/* 2. CHỌN CHI NHÁNH */}
                <div className="form-group">
                    <div style={{display:'flex', justifyContent:'space-between', alignItems:'center'}}>
                        <label>Chọn Chi Nhánh: <span style={{color:'red'}}>*</span></label>
                        <button type="button" onClick={handleViewDoctorSchedule} style={{fontSize:'12px', padding:'2px 8px', cursor:'pointer', background:'#2196f3', color:'white', border:'none', borderRadius:'4px'}}>
                            👨‍⚕️ Xem lịch Bác sĩ
                        </button>
                    </div>
                    
                    <select name="MaCN" value={formData.MaCN} onChange={handleBranchChange} required className="input-field">
                        {branches.map(branch => (
                            <option key={branch.MaCN} value={branch.MaCN}>
                                {branch.TenCN}
                            </option>
                        ))}
                    </select>

                    {selectedBranchInfo && (
                        <div style={{marginTop: '10px', padding: '15px', backgroundColor: '#e3f2fd', borderRadius: '8px', borderLeft: '5px solid #2196f3', fontSize: '14px', color: '#333'}}>
                            <p style={{margin: '0 0 5px 0'}}>📍 <strong>Địa chỉ:</strong> {selectedBranchInfo.DiaChi}</p>
                            <p style={{margin: 0, color: '#d32f2f', fontWeight: 'bold'}}>
                                ⏰ Giờ mở cửa: {displayTime(selectedBranchInfo.GioMoCua || selectedBranchInfo.Giomocua)} - {displayTime(selectedBranchInfo.GioDongCua || selectedBranchInfo.Giodongcua)}
                            </p>
                        </div>
                    )}
                </div>

                {/* 3. DỊCH VỤ (CHỖ NÀY LÀ QUAN TRỌNG NHẤT NÈ) */}
                <div className="form-group">
                    <label>Dịch Vụ: <span style={{color:'red'}}>*</span></label>
                    <select name="LoaiPhieu" value={formData.LoaiPhieu} onChange={handleChange} required className="input-field">
                        
                        {/* Chỉ render option Khám nếu chi nhánh có chữ "Khám" */}
                        {selectedBranchInfo?.DichVuHoTro?.toLowerCase().includes('khám') && (
                            <option value="KB">Khám Bệnh 🩺</option>
                        )}
                        
                        {/* Chỉ render option Tiêm nếu chi nhánh có chữ "Tiêm" hoặc "Vaccine" */}
                        {(selectedBranchInfo?.DichVuHoTro?.toLowerCase().includes('tiêm') || selectedBranchInfo?.DichVuHoTro?.toLowerCase().includes('vaccine')) && (
                            <option value="TV">Tiêm Vaccine 💉</option>
                        )}

                    </select>
                </div>

                {/* 4. NGÀY GIỜ */}
                <div className="form-row">
                    <div className="form-group">
                        <label>Ngày Hẹn: <span style={{color:'red'}}>*</span></label>
                        <input type="date" name="NgayHen" value={formData.NgayHen} onChange={handleChange} required className="input-field" min={new Date().toISOString().split('T')[0]} />
                    </div>
                    <div className="form-group">
                        <label>Giờ Hẹn: <span style={{color:'red'}}>*</span></label>
                        <select name="GioHen" value={formData.GioHen} onChange={handleChange} required className="input-field">
                            <option value="">-- Chọn khung giờ --</option>
                            {timeSlots.map(slot => (
                                <option key={slot} value={slot}>{slot}</option>
                            ))}
                        </select>
                    </div>
                </div>

                {/* 5. TRIỆU CHỨNG */}
                <div className="form-group">
                    <label>Triệu chứng / Lý do khám: <span style={{color:'red'}}>*</span></label>
                    <textarea name="TrieuChung" value={formData.TrieuChung} onChange={handleChange} rows="3" className="input-field" required ></textarea>
                </div>

                <button type="submit" className="btn-submit" disabled={loading}>
                    {loading ? "Đang xử lý..." : "XÁC NHẬN ĐẶT LỊCH"}
                </button>
            </form>
        </div>
    );
};

export default Booking;