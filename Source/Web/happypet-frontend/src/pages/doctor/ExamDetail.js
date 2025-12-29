import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import Swal from 'sweetalert2';
import './Doctor.css';

const ExamDetail = () => {
    const { maPhieu } = useParams();
    const navigate = useNavigate();
    
    const [patientInfo, setPatientInfo] = useState(null);
    const [medicines, setMedicines] = useState([]);
    const [availableMedicines, setAvailableMedicines] = useState([]);
    const [prescription, setPrescription] = useState([]);
    
    const [chanDoan, setChanDoan] = useState('');
    const [ngayHenTaiKham, setNgayHenTaiKham] = useState('');
    
    const [selectedMedicine, setSelectedMedicine] = useState('');
    const [soLuong, setSoLuong] = useState(1);
    const [lieuLuong, setLieuLuong] = useState('');
    
    const [loading, setLoading] = useState(false);
    const [showHistory, setShowHistory] = useState(false);
    const [medicalHistory, setMedicalHistory] = useState([]);

    useEffect(() => {
        fetchPatientInfo();
        fetchAvailableMedicines();
        fetchPrescription();
    }, [maPhieu]);

    const fetchPatientInfo = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get(`http://localhost:5000/api/doctor/patient-info/${maPhieu}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setPatientInfo(res.data);
            console.log('✅ Patient info loaded:', res.data);
        } catch (err) {
            console.error('❌ Error loading patient info:', err);
            Swal.fire('Lỗi', 'Không thể tải thông tin bệnh nhân!', 'error');
        }
    };

    const fetchAvailableMedicines = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get('http://localhost:5000/api/doctor/medicines', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setAvailableMedicines(res.data);
            console.log('✅ Medicines loaded:', res.data.length, 'items');
        } catch (err) {
            console.error('❌ Error loading medicines:', err);
        }
    };

    const fetchPrescription = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get(`http://localhost:5000/api/doctor/prescription/${maPhieu}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setPrescription(res.data);
            console.log('✅ Prescription loaded:', res.data.length, 'items');
        } catch (err) {
            console.error('❌ Error loading prescription:', err);
        }
    };

    const fetchMedicalHistory = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get(`http://localhost:5000/api/doctor/medical-history/${maPhieu}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setMedicalHistory(res.data);
            setShowHistory(true);
        } catch (err) {
            console.error('❌ Error loading medical history:', err);
            Swal.fire('Lỗi', 'Không thể tải lịch sử khám!', 'error');
        }
    };

    const handleUpdateDiagnosis = async () => {
        if (!chanDoan.trim()) {
            Swal.fire('Thông báo', 'Vui lòng nhập chẩn đoán!', 'warning');
            return;
        }

        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/doctor/update-diagnosis', {
                MaPhieu: maPhieu,
                ChanDoan: chanDoan,
                NgayHenTaiKham: ngayHenTaiKham || null
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            Swal.fire('Thành công', 'Đã cập nhật chẩn đoán!', 'success');
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Cập nhật thất bại!', 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleAddMedicine = async () => {
        if (!selectedMedicine || soLuong <= 0 || !lieuLuong.trim()) {
            Swal.fire('Thông báo', 'Vui lòng điền đầy đủ thông tin thuốc!', 'warning');
            return;
        }

        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/doctor/add-medicine', {
                MaPhieu: maPhieu,
                MaThuoc: selectedMedicine,
                SoLuong: parseInt(soLuong),
                LieuLuong: lieuLuong
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            Swal.fire('Thành công', 'Đã thêm thuốc vào đơn!', 'success');
            fetchPrescription();
            
            // Reset form
            setSelectedMedicine('');
            setSoLuong(1);
            setLieuLuong('');
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Thêm thuốc thất bại!', 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleRemoveMedicine = async (maThuoc) => {
        const confirm = await Swal.fire({
            title: 'Xác nhận xóa?',
            text: 'Thuốc sẽ bị xóa khỏi đơn và hoàn lại kho',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Xóa',
            cancelButtonText: 'Hủy'
        });

        if (!confirm.isConfirmed) return;

        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/doctor/remove-medicine', {
                MaPhieu: maPhieu,
                MaThuoc: maThuoc
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            Swal.fire('Thành công', 'Đã xóa thuốc!', 'success');
            fetchPrescription();
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Xóa thất bại!', 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleFinishExam = async () => {
        if (!chanDoan.trim()) {
            Swal.fire('Thông báo', 'Vui lòng nhập chẩn đoán trước khi kết thúc!', 'warning');
            return;
        }

        const confirm = await Swal.fire({
            title: 'Xác nhận hoàn tất khám?',
            text: 'Phiếu sẽ chuyển sang trạng thái hoàn tất',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Hoàn tất',
            cancelButtonText: 'Hủy'
        });

        if (!confirm.isConfirmed) return;

        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/doctor/finish-exam', {
                MaPhieu: maPhieu
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            Swal.fire('Thành công', 'Đã hoàn tất khám bệnh!', 'success');
            navigate('/doctor/dashboard');
        } catch (err) {
            Swal.fire('Lỗi', err.response?.data?.message || 'Hoàn tất thất bại!', 'error');
        } finally {
            setLoading(false);
        }
    };

    const formatMoney = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0);

    if (!patientInfo) {
        return <div className="loading-container">⏳ Đang tải thông tin...</div>;
    }

    return (
        <div className="exam-detail-container">
            <div className="exam-header">
                <button className="btn-back" onClick={() => navigate('/doctor/dashboard')}>
                    ← Quay lại
                </button>
                <h2>🩺 Khám Bệnh - #{maPhieu}</h2>
            </div>

            {/* THÔNG TIN BỆNH NHÂN */}
            <div className="patient-info-card">
                <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                    <h3>👤 Thông Tin Bệnh Nhân</h3>
                    <button className="btn-history" onClick={fetchMedicalHistory}>
                        📋 Xem lịch sử khám
                    </button>
                </div>
                <div className="info-grid">
                    <div><strong>Thú cưng:</strong> {patientInfo.TenThuCung}</div>
                    <div><strong>Loại:</strong> {patientInfo.LoaiThuCung}</div>
                    <div><strong>Giống:</strong> {patientInfo.GiongThuCung}</div>
                    <div><strong>Chủ nuôi:</strong> {patientInfo.ChuNuoi}</div>
                    {patientInfo.SDT && <div><strong>SĐT:</strong> {patientInfo.SDT}</div>}
                </div>
            </div>

            {/* CHẨN ĐOÁN */}
            <div className="diagnosis-card">
                <h3>📋 Chẩn Đoán</h3>
                <textarea
                    className="diagnosis-input"
                    placeholder="Nhập chẩn đoán bệnh..."
                    value={chanDoan}
                    onChange={(e) => setChanDoan(e.target.value)}
                    rows={4}
                />
                <div className="follow-up">
                    <label>Ngày hẹn tái khám (nếu có):</label>
                    <input
                        type="date"
                        value={ngayHenTaiKham}
                        onChange={(e) => setNgayHenTaiKham(e.target.value)}
                        min={new Date().toISOString().split('T')[0]}
                    />
                </div>
                <button className="btn-primary" onClick={handleUpdateDiagnosis} disabled={loading}>
                    💾 Lưu chẩn đoán
                </button>
            </div>

            {/* ĐƠN THUỐC */}
            <div className="prescription-card">
                <h3>💊 Đơn Thuốc</h3>
                
                {/* THÊM THUỐC */}
                <div className="add-medicine-form">
                    <select
                        value={selectedMedicine}
                        onChange={(e) => setSelectedMedicine(e.target.value)}
                        className="select-medicine"
                    >
                        <option value="">-- Chọn thuốc --</option>
                        {availableMedicines.map(med => (
                            <option key={med.MaThuoc} value={med.MaThuoc}>
                                {med.TenThuoc} (Tồn: {med.SoLuongTon}) - {formatMoney(med.DonGia)}
                            </option>
                        ))}
                    </select>
                    <input
                        type="number"
                        placeholder="Số lượng"
                        value={soLuong}
                        onChange={(e) => setSoLuong(e.target.value)}
                        min="1"
                        className="input-quantity"
                    />
                    <input
                        type="text"
                        placeholder="Liều lượng (VD: 2 viên/ngày)"
                        value={lieuLuong}
                        onChange={(e) => setLieuLuong(e.target.value)}
                        className="input-dosage"
                    />
                    <button className="btn-add" onClick={handleAddMedicine} disabled={loading}>
                        + Thêm
                    </button>
                </div>

                {/* DANH SÁCH THUỐC ĐÃ KÊ */}
                {prescription.length === 0 ? (
                    <p className="empty-message">Chưa có thuốc nào trong đơn</p>
                ) : (
                    <table className="medicine-table">
                        <thead>
                            <tr>
                                <th>Thuốc</th>
                                <th>Số lượng</th>
                                <th>Liều lượng</th>
                                <th>Thành tiền</th>
                                <th>Hành động</th>
                            </tr>
                        </thead>
                        <tbody>
                            {prescription.map(item => (
                                <tr key={item.MaThuoc}>
                                    <td>{item.TenThuoc}</td>
                                    <td>{item.SoLuong}</td>
                                    <td>{item.LieuLuong}</td>
                                    <td>{formatMoney(item.ThanhTien)}</td>
                                    <td>
                                        <button className="btn-delete" onClick={() => handleRemoveMedicine(item.MaThuoc)}>
                                            🗑️
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {/* HOÀN TẤT */}
            <div className="exam-footer">
                <button className="btn-finish" onClick={handleFinishExam} disabled={loading}>
                    ✅ Hoàn Tất Khám Bệnh
                </button>
            </div>

            {/* MODAL LỊCH SỬ KHÁM */}
            {showHistory && (
                <div className="modal-overlay" onClick={() => setShowHistory(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{maxWidth: '900px'}}>
                        <div className="modal-header">
                            <h3>📋 Lịch Sử Khám Bệnh</h3>
                            <button className="modal-close" onClick={() => setShowHistory(false)}>✕</button>
                        </div>
                        
                        <div className="modal-body">
                            {medicalHistory.length === 0 ? (
                                <div style={{textAlign: 'center', padding: '40px', color: '#999'}}>
                                    Chưa có lịch sử khám bệnh trước đây
                                </div>
                            ) : (
                                <table className="medicine-table">
                                    <thead>
                                        <tr>
                                            <th>Ngày khám</th>
                                            <th>Bác sĩ</th>
                                            <th>Chẩn đoán</th>
                                            <th>Trạng thái</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {medicalHistory.map((item, idx) => (
                                            <tr key={idx}>
                                                <td>{new Date(item.TG_ThucHienDV).toLocaleDateString('vi-VN')}</td>
                                                <td>{item.BacSi || 'N/A'}</td>
                                                <td style={{maxWidth: '300px'}}>{item.ChanDoan || 'Chưa có chẩn đoán'}</td>
                                                <td>
                                                    <span className={`status-badge ${item.TrangThai === 'HT' ? 'status-done' : 'status-processing'}`}>
                                                        {item.TrangThai === 'HT' ? '✅ Hoàn tất' : '⏳ Đang xử lý'}
                                                    </span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ExamDetail;
