import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import axios from 'axios';
import './Login.css'; // Xài chung CSS cho đẹp

const CompleteProfile = () => {
    const location = useLocation();
    const navigate = useNavigate();
    
    // Lấy dữ liệu Google truyền qua
    const googleData = location.state || {};

    const [formData, setFormData] = useState({
        Email: googleData.email || '',
        HoTen: googleData.name || '',
        SDT: '',
        DiaChi: '',
        GioiTinh: 'Nam',
        NgaySinh: '',
        CCCD: '' // Nếu cần
    });

    useEffect(() => {
        if (!googleData.email) {
            alert("Vui lòng đăng nhập Google trước!");
            navigate('/login');
        }
    }, [googleData, navigate]);

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            // Gọi API hoàn tất đăng ký
            const res = await axios.post('http://localhost:5000/api/auth/google-register', formData);
            
            // Lưu token (Đăng nhập luôn)
            localStorage.setItem('token', res.data.token);
            localStorage.setItem('role', res.data.Role);
            localStorage.setItem('hoten', res.data.HoTen);
            localStorage.setItem('MaUser', res.data.MaUser);

            alert("✅ Tạo tài khoản thành công! Chào mừng đến với HappyPet.");
            navigate('/');
        } catch (err) {
            alert("❌ Lỗi: " + (err.response?.data?.message || err.message));
        }
    };

    return (
        <div className="login-container">
            <div className="login-box" style={{maxWidth: '500px'}}>
                <h2 className="login-title">📝 BỔ SUNG THÔNG TIN</h2>
                <p className="login-subtitle">Chỉ còn 1 bước nữa thôi!</p>

                {/* Hiện cái Avatar Google cho nó uy tín */}
                {googleData.photo && <img src={googleData.photo} alt="Avatar" style={{width: 60, borderRadius: '50%', marginBottom: 15}} />}

                <form onSubmit={handleSubmit}>
                    <div className="input-group">
                        <label>Email (Từ Google)</label>
                        <input type="text" name="Email" value={formData.Email} disabled style={{backgroundColor: '#e9ecef'}} />
                    </div>

                    <div className="input-group">
                        <label>Họ và Tên</label>
                        <input type="text" name="HoTen" value={formData.HoTen} onChange={handleChange} required />
                    </div>

                    <div className="input-group">
                        <label>Số Điện Thoại (*)</label>
                        <input type="text" name="SDT" value={formData.SDT} onChange={handleChange} placeholder="Nhập SĐT để shop liên hệ..." required />
                    </div>
                    
                    {/* Thêm mấy trường bắt buộc khác của DB bà */}
                    <div style={{display:'flex', gap:'10px'}}>
                        <div className="input-group" style={{flex:1}}>
                            <label>Giới tính</label>
                            <select name="GioiTinh" value={formData.GioiTinh} onChange={handleChange} className="input-field" style={{width:'100%', padding:'10px', borderRadius:'8px', border:'1px solid #ddd'}}>
                                <option value="Nam">Nam</option>
                                <option value="Nữ">Nữ</option>
                            </select>
                        </div>
                         <div className="input-group" style={{flex:1}}>
                            <label>Ngày Sinh</label>
                            <input type="date" name="NgaySinh" value={formData.NgaySinh} onChange={handleChange} />
                        </div>
                    </div>

                    <button type="submit" className="btn-login" style={{marginTop:'10px'}}>
                        HOÀN TẤT ĐĂNG KÝ
                    </button>
                </form>
            </div>
        </div>
    );
};

export default CompleteProfile;