// src/pages/Profile.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const Profile = () => {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(true);
    
    // State thông tin cá nhân
    const [userData, setUserData] = useState({
        HoTen: '', NgaySinh: '', GioiTinh: 'Nam', Email: '', CCCD: '', 
        SDT: '', TenDangNhap: '', 
        DiemTichLuy: 0, HangThanhVien: '', MaHang: ''
    });

    // State đổi mật khẩu
    const [passData, setPassData] = useState({ MatKhauCu: '', MatKhauMoi: '', XacNhan: '' });

    // State chứa lỗi chung cho cả 2 form
    const [errors, setErrors] = useState({});

    useEffect(() => {
        fetchProfile();
    }, []);

    const fetchProfile = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get('http://localhost:5000/api/users/profile', {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            const data = res.data;
            if(data.NgaySinh) data.NgaySinh = data.NgaySinh.split('T')[0];
            if(data.GioiTinh) data.GioiTinh = data.GioiTinh.trim(); // Trim lúc load về

            setUserData(data);
            setLoading(false);
        } catch (err) {
            alert('Không thể tải thông tin cá nhân');
        }
    };

    // --- HÀM XỬ LÝ NHẬP LIỆU (Xóa lỗi khi gõ) ---
    const handleInputChange = (field, value) => {
        setUserData({ ...userData, [field]: value });
        if (errors[field]) setErrors({ ...errors, [field]: null });
    };

    const handlePassInputChange = (field, value) => {
        setPassData({ ...passData, [field]: value });
        if (errors[field]) setErrors({ ...errors, [field]: null });
    };

    // --- VALIDATION ---
    const validateProfile = () => {
        let newErrors = {};
        let isValid = true;

        if (!userData.HoTen || userData.HoTen.trim() === '') {
            newErrors.HoTen = "Vui lòng nhập họ tên!";
            isValid = false;
        }
        if (!userData.NgaySinh) {
            newErrors.NgaySinh = "Vui lòng chọn ngày sinh!";
            isValid = false;
        }

        setErrors(newErrors);
        return isValid;
    };

    const validatePassword = () => {
        let newErrors = {};
        let isValid = true;

        if (!passData.MatKhauCu) {
            newErrors.MatKhauCu = "Nhập mật khẩu cũ";
            isValid = false;
        }
        if (!passData.MatKhauMoi) {
            newErrors.MatKhauMoi = "Nhập mật khẩu mới";
            isValid = false;
        }
        if (!passData.XacNhan) {
            newErrors.XacNhan = "Nhập lại mật khẩu";
            isValid = false;
        } else if (passData.MatKhauMoi !== passData.XacNhan) {
            newErrors.XacNhan = "Mật khẩu xác nhận không khớp";
            isValid = false;
        }

        setErrors(newErrors);
        return isValid;
    };

    // --- CẬP NHẬT THÔNG TIN ---
    const handleUpdateInfo = async (e) => {
        e.preventDefault();
        if (!validateProfile()) return; 

        try {
            const token = localStorage.getItem('token');
            await axios.put('http://localhost:5000/api/users/profile/update', {
                HoTen: userData.HoTen,  // Giữ nguyên, KHÔNG trim()
                NgaySinh: userData.NgaySinh,
                GioiTinh: userData.GioiTinh.trim(), // Trim cái này để fix lỗi độ dài
                Email: userData.Email ? userData.Email.trim() : '',
                CCCD: userData.CCCD ? userData.CCCD.trim() : ''
            }, { headers: { Authorization: `Bearer ${token}` } });
            
            alert('Cập nhật thành công!');
            localStorage.setItem('hoten', userData.HoTen); 
        } catch (err) {
            alert(err.response?.data?.message || "Lỗi cập nhật");
        }
    };

    // --- ĐỔI MẬT KHẨU ---
    const handleChangePass = async (e) => {
        e.preventDefault();
        if (!validatePassword()) return; // Gọi hàm check lỗi pass

        try {
            const token = localStorage.getItem('token');
            await axios.post('http://localhost:5000/api/auth/change-password', {
                TenDangNhap: userData.TenDangNhap,
                MatKhauCu: passData.MatKhauCu,
                MatKhauMoi: passData.MatKhauMoi
            }, { headers: { Authorization: `Bearer ${token}` } });
            
            alert("Đổi pass thành công! Đăng nhập lại nhé.");
            localStorage.clear();
            navigate('/login');
        } catch (err) {
            alert("Thất bại: " + (err.response?.data?.message || err.message));
        }
    };

    if (loading) return <div>Đang tải...</div>;

    return (
        <div>
            <div style={{ padding: '30px', maxWidth: '1000px', margin: '0 auto', display: 'flex', gap: '30px' }}>
                
                {/* --- CỘT TRÁI: THÔNG TIN --- */}
                <div style={{ flex: 1.5 }}>
                    <div style={{ background: '#e3f2fd', padding: '15px', borderRadius: '10px', marginBottom: '20px' }}>
                        <h2 style={{ margin: 0, color: '#1565c0' }}>🎖 {userData.HangThanhVien || 'Thành viên'}</h2>
                        <p>Điểm tích lũy: <strong>{userData.DiemTichLuy || 0} điểm</strong></p>
                    </div>

                    <h3>Thông tin cá nhân</h3>
                    <form onSubmit={handleUpdateInfo} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                        
                        {/* Họ tên & Giới tính */}
                        <div style={{display:'flex', gap: '10px'}}>
                            <div style={{flex:1}}>
                                <label>Họ tên: <span style={{color:'red'}}>*</span></label>
                                <input 
                                    className={`input-field ${errors.HoTen ? 'input-error' : ''}`} 
                                    value={userData.HoTen} 
                                    onChange={e => handleInputChange('HoTen', e.target.value)} 
                                />
                                {errors.HoTen && <span className="error-text">{errors.HoTen}</span>}
                            </div>
                            <div style={{width:'150px'}}>
                                <label>Giới tính: <span style={{color:'red'}}>*</span></label>
                                <select className="input-field" value={userData.GioiTinh} 
                                    onChange={e => setUserData({...userData, GioiTinh: e.target.value})}>
                                    <option value="Nam">Nam</option>
                                    <option value="Nữ">Nữ</option>
                                </select>
                            </div>
                        </div>

                        {/* Ngày sinh */}
                        <div>
                            <label>Ngày sinh: <span style={{color:'red'}}>*</span></label>
                            <input 
                                type="date" 
                                className={`input-field ${errors.NgaySinh ? 'input-error' : ''}`} 
                                value={userData.NgaySinh} 
                                onChange={e => handleInputChange('NgaySinh', e.target.value)} 
                            />
                            {errors.NgaySinh && <span className="error-text">{errors.NgaySinh}</span>}
                        </div>

                        {/* Email & CCCD & SĐT */}
                        <div>
                            <label>Email (Tùy chọn):</label>
                            <input type="email" className="input-field" value={userData.Email || ''} 
                                onChange={e => setUserData({...userData, Email: e.target.value})} placeholder="Nhập email..." />
                        </div>
                        <div>
                            <label>CCCD (Tùy chọn):</label>
                            <input className="input-field" value={userData.CCCD || ''} 
                                onChange={e => setUserData({...userData, CCCD: e.target.value})} placeholder="Nhập CCCD..." />
                        </div>
                        <div>
                            <label>SĐT (Không thể sửa):</label>
                            <input className="input-field" value={userData.SDT} disabled style={{background: '#eee'}} />
                        </div>

                        <button type="submit" className="btn-save">LƯU THAY ĐỔI</button>
                    </form>
                </div>

                {/* --- CỘT PHẢI: ĐỔI MẬT KHẨU (ĐÃ SỬA GIAO DIỆN) --- */}
                <div style={{ flex: 1, borderLeft: '1px solid #ddd', paddingLeft: '30px' }}>
                    <h3>Đổi mật khẩu</h3>
                    <form onSubmit={handleChangePass} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                        
                        <div>
                            <label>Mật khẩu cũ: <span style={{color:'red'}}>*</span></label>
                            <input 
                                type="password" 
                                className={`input-field ${errors.MatKhauCu ? 'input-error' : ''}`}
                                placeholder="Nhập mật khẩu cũ"
                                value={passData.MatKhauCu}
                                onChange={e => handlePassInputChange('MatKhauCu', e.target.value)} 
                            />
                            {errors.MatKhauCu && <span className="error-text">{errors.MatKhauCu}</span>}
                        </div>

                        <div>
                            <label>Mật khẩu mới: <span style={{color:'red'}}>*</span></label>
                            <input 
                                type="password" 
                                className={`input-field ${errors.MatKhauMoi ? 'input-error' : ''}`}
                                placeholder="Nhập mật khẩu mới"
                                value={passData.MatKhauMoi}
                                onChange={e => handlePassInputChange('MatKhauMoi', e.target.value)} 
                            />
                            {errors.MatKhauMoi && <span className="error-text">{errors.MatKhauMoi}</span>}
                        </div>

                        <div>
                            <label>Nhập lại mật khẩu mới: <span style={{color:'red'}}>*</span></label>
                            <input 
                                type="password" 
                                className={`input-field ${errors.XacNhan ? 'input-error' : ''}`}
                                placeholder="Xác nhận lại mật khẩu"
                                value={passData.XacNhan}
                                onChange={e => handlePassInputChange('XacNhan', e.target.value)} 
                            />
                            {errors.XacNhan && <span className="error-text">{errors.XacNhan}</span>}
                        </div>

                        <button type="submit" className="btn-pass">ĐỔI MẬT KHẨU</button>
                    </form>
                </div>
            </div>
            
            <style>{`
                .input-field { width: 100%; padding: 8px; margin-top: 5px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
                .input-error { border: 1px solid red; background-color: #fffafa; } 
                .error-text { color: red; fontSize: 12px; marginTop: 2px; display: block; }
                .btn-save { margin-top: 20px; padding: 10px; background: #2e7d32; color: white; border: none; cursor: pointer; border-radius: 4px; width: 100%; }
                .btn-pass { margin-top: 20px; padding: 10px; background: #c62828; color: white; border: none; cursor: pointer; border-radius: 4px; width: 100%; }
            `}</style>
        </div>
    );
};

export default Profile;