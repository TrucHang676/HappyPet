import React, { useState } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';

const MedicalRecord = ({ maPhieu, thongTinThuCung }) => {
    const [chanDoan, setChanDoan] = useState('');
    const [ngayTaiKham, setNgayTaiKham] = useState('');
    const [donThuoc, setDonThuoc] = useState([]);

    // Lưu chẩn đoán (SP 1)
    const handleSaveInfo = async () => {
        try {
            await axios.post('/api/doctor/update-exam', {
                MaPhieu: maPhieu,
                ChanDoan: chanDoan,
                NgayHenTaiKham: ngayTaiKham
            });
            Swal.fire('Thành công', 'Đã lưu chẩn đoán chuyên môn', 'success');
        } catch (err) { Swal.fire('Lỗi', err.response.data.message, 'error'); }
    };

    // Kết thúc khám (SP 4)
    const handleComplete = async () => {
        const confirm = await Swal.fire({
            title: 'Hoàn tất khám?',
            text: "Phiếu sẽ chuyển sang bộ phận thanh toán!",
            icon: 'question', showCancelButton: true
        });
        if (confirm.isConfirmed) {
            await axios.post('/api/doctor/complete-exam', { MaPhieu: maPhieu });
            window.location.reload(); 
        }
    };

    return (
        <div className="doctor-card" style={{padding: '20px', background: '#fff', borderRadius: '10px'}}>
            <h3>📋 Phiếu Khám: {maPhieu}</h3>
            <p>🐾 Bệnh nhân: <b>{thongTinThuCung.Ten}</b></p>
            <hr/>
            
            <div className="form-group">
                <label>👨‍⚕️ Chẩn đoán bệnh:</label>
                <textarea 
                    className="form-control" 
                    value={chanDoan} 
                    onChange={(e) => setChanDoan(e.target.value)}
                    placeholder="Nhập tình trạng bệnh..."
                />
            </div>

            <div className="form-group" style={{marginTop: '15px'}}>
                <label>📅 Hẹn tái khám (nếu có):</label>
                <input type="date" className="form-control" value={ngayTaiKham} onChange={(e) => setNgayTaiKham(e.target.value)} />
            </div>

            <button onClick={handleSaveInfo} className="btn btn-primary" style={{marginTop: '15px'}}>💾 Lưu kết quả</button>

            <div className="prescription-section" style={{marginTop: '30px'}}>
                <h4>💊 Đơn thuốc</h4>
                {/* Ở đây bà code thêm phần tìm kiếm thuốc và bảng danh sách thuốc đã kê */}
            </div>

            <button onClick={handleComplete} className="btn btn-success" style={{width: '100%', marginTop: '40px', fontWeight: 'bold'}}>
                🏁 HOÀN TẤT & CHUYỂN THANH TOÁN
            </button>
        </div>
    );
};