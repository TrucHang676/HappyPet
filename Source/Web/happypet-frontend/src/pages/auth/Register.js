// src/pages/auth/Register.js
import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const Register = () => {
    const navigate = useNavigate();

    // State lưu dữ liệu nhập vào
    const [formData, setFormData] = useState({
        TenDangNhap: '',
        MatKhau: '',
        HoTen: '',
        NgaySinh: '',
        GioiTinh: 'Nam', // Mặc định là Nam
        SDT: '',
        Email: '',
        CCCD: ''
    });

    // State lưu lỗi (để tô đỏ ô nhập)
    const [errors, setErrors] = useState({});

    // Hàm xử lý khi gõ phím
    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({
            ...formData,
            [name]: value
        });
        
        // Gõ tới đâu xóa lỗi đỏ tới đó cho đỡ ngứa mắt
        if (errors[name]) {
            setErrors({
                ...errors,
                [name]: ''
            });
        }
    };

    // Hàm kiểm tra hợp lệ trước khi gửi
    const validateForm = () => {
        let newErrors = {};
        let isValid = true;

        // 1. Kiểm tra các trường BẮT BUỘC
        if (!formData.TenDangNhap.trim()) {
            newErrors.TenDangNhap = "Vui lòng nhập tên đăng nhập";
            isValid = false;
        }

        if (!formData.MatKhau) {
            newErrors.MatKhau = "Vui lòng nhập mật khẩu";
            isValid = false;
        }

        if (!formData.HoTen.trim()) {
            newErrors.HoTen = "Vui lòng nhập họ tên";
            isValid = false;
        }

        if (!formData.NgaySinh) {
            newErrors.NgaySinh = "Vui lòng chọn ngày sinh";
            isValid = false;
        }

        if (!formData.SDT.trim()) {
            newErrors.SDT = "Vui lòng nhập số điện thoại";
            isValid = false;
        } else if (!/^[0][0-9]{9}$/.test(formData.SDT)) {
            // Check luôn định dạng SĐT ở đây cho xịn
            newErrors.SDT = "SĐT phải bắt đầu bằng 0 và đủ 10 số";
            isValid = false;
        }

        // Email và CCCD không bắt buộc -> Không check
        // (Trừ khi bà muốn check định dạng Email nếu người ta lỡ nhập bậy)
        if (formData.Email && !/\S+@\S+\.\S+/.test(formData.Email)) {
             newErrors.Email = "Email không đúng định dạng";
             isValid = false;
        }

        setErrors(newErrors);
        return isValid;
    };

    const handleRegister = async (e) => {
        e.preventDefault();

        // Chạy kiểm tra, nếu lỗi thì dừng lại, không gửi API
        if (!validateForm()) return;

        try {
            // Chuẩn bị dữ liệu (Biến rỗng thành null)
            const payload = {
                ...formData,
                Email: formData.Email || null,
                CCCD: formData.CCCD || null
            };

            await axios.post('http://localhost:5000/api/auth/register', payload);
            
            alert('Đăng ký thành công! Bạn có thể đăng nhập ngay.');
            navigate('/login');
        } catch (err) {
            // Nếu lỗi từ Backend trả về (ví dụ trùng Tên đăng nhập)
            alert(err.response?.data?.message || 'Đăng ký thất bại');
        }
    };

    // Style cho dấu sao đỏ
    const starStyle = { color: 'red', marginLeft: '5px' };
    
    // Style cho thông báo lỗi nhỏ dưới ô input
    const errorMsgStyle = { color: 'red', fontSize: '12px', marginTop: '2px', display: 'block' };

    return (
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: '50px' }}>
            <div style={{ width: '400px', padding: '30px', border: '1px solid #ddd', borderRadius: '10px', boxShadow: '0 0 10px rgba(0,0,0,0.1)' }}>
                <h2 style={{ textAlign: 'center', color: '#8B4513' }}>Đăng Ký Thành Viên 🐶</h2>
                
                <form onSubmit={handleRegister}>
                    
                    {/* TÊN ĐĂNG NHẬP */}
                    <div style={{ marginBottom: '15px' }}>
                        <label>Tên đăng nhập <span style={starStyle}>*</span></label>
                        <input
                            type="text"
                            name="TenDangNhap"
                            value={formData.TenDangNhap}
                            onChange={handleChange}
                            style={{ 
                                ...inputStyle, 
                                border: errors.TenDangNhap ? '1px solid red' : '1px solid #ccc' 
                            }}
                            placeholder="Nhập tên đăng nhập"
                        />
                        {errors.TenDangNhap && <span style={errorMsgStyle}>{errors.TenDangNhap}</span>}
                    </div>

                    {/* MẬT KHẨU */}
                    <div style={{ marginBottom: '15px' }}>
                        <label>Mật khẩu <span style={starStyle}>*</span></label>
                        <input
                            type="password"
                            name="MatKhau"
                            value={formData.MatKhau}
                            onChange={handleChange}
                            style={{ 
                                ...inputStyle, 
                                border: errors.MatKhau ? '1px solid red' : '1px solid #ccc' 
                            }}
                            placeholder="Nhập mật khẩu"
                        />
                        {errors.MatKhau && <span style={errorMsgStyle}>{errors.MatKhau}</span>}
                    </div>

                    {/* HỌ TÊN */}
                    <div style={{ marginBottom: '15px' }}>
                        <label>Họ và tên <span style={starStyle}>*</span></label>
                        <input
                            type="text"
                            name="HoTen"
                            value={formData.HoTen}
                            onChange={handleChange}
                            style={{ 
                                ...inputStyle, 
                                border: errors.HoTen ? '1px solid red' : '1px solid #ccc' 
                            }}
                            placeholder="Nguyễn Văn A"
                        />
                        {errors.HoTen && <span style={errorMsgStyle}>{errors.HoTen}</span>}
                    </div>

                    {/* NGÀY SINH & GIỚI TÍNH (Xếp ngang hàng) */}
                    <div style={{ display: 'flex', gap: '10px', marginBottom: '15px' }}>
                        <div style={{ flex: 2 }}>
                            <label>Ngày sinh <span style={starStyle}>*</span></label>
                            <input
                                type="date"
                                name="NgaySinh"
                                value={formData.NgaySinh}
                                onChange={handleChange}
                                style={{ 
                                    ...inputStyle, 
                                    border: errors.NgaySinh ? '1px solid red' : '1px solid #ccc' 
                                }}
                            />
                            {errors.NgaySinh && <span style={errorMsgStyle}>{errors.NgaySinh}</span>}
                        </div>
                        <div style={{ flex: 1 }}>
                            <label>Giới tính <span style={starStyle}>*</span></label>
                            <select
                                name="GioiTinh"
                                value={formData.GioiTinh}
                                onChange={handleChange}
                                style={inputStyle}
                            >
                                <option value="Nam">Nam</option>
                                <option value="Nữ">Nữ</option>
                            </select>
                        </div>
                    </div>

                    {/* SỐ ĐIỆN THOẠI */}
                    <div style={{ marginBottom: '15px' }}>
                        <label>Số điện thoại <span style={starStyle}>*</span></label>
                        <input
                            type="text"
                            name="SDT"
                            value={formData.SDT}
                            onChange={handleChange}
                            style={{ 
                                ...inputStyle, 
                                border: errors.SDT ? '1px solid red' : '1px solid #ccc' 
                            }}
                            placeholder="090xxxxxxx"
                        />
                        {errors.SDT && <span style={errorMsgStyle}>{errors.SDT}</span>}
                    </div>

                    {/* EMAIL (KHÔNG BẮT BUỘC) */}
                    <div style={{ marginBottom: '15px' }}>
                        <label>Email (Tùy chọn)</label>
                        <input
                            type="email"
                            name="Email"
                            value={formData.Email}
                            onChange={handleChange}
                            style={{ 
                                ...inputStyle, 
                                border: errors.Email ? '1px solid red' : '1px solid #ccc' 
                            }}
                            placeholder="abc@example.com"
                        />
                        {errors.Email && <span style={errorMsgStyle}>{errors.Email}</span>}
                    </div>

                    {/* CCCD (KHÔNG BẮT BUỘC) */}
                    <div style={{ marginBottom: '20px' }}>
                        <label>CCCD/CMND (Tùy chọn)</label>
                        <input
                            type="text"
                            name="CCCD"
                            value={formData.CCCD}
                            onChange={handleChange}
                            style={inputStyle}
                            placeholder="Nhập số CCCD"
                        />
                    </div>

                    <button type="submit" style={btnStyle}>ĐĂNG KÝ NGAY</button>
                    
                    <p style={{ marginTop: '15px', textAlign: 'center' }}>
                        Đã có tài khoản? <a href="/login" style={{ color: '#8B4513', fontWeight: 'bold' }}>Đăng nhập</a>
                    </p>
                </form>
            </div>
        </div>
    );
};

// CSS chung cho gọn code
const inputStyle = {
    width: '100%',
    padding: '10px',
    marginTop: '5px',
    borderRadius: '5px',
    boxSizing: 'border-box',
    outline: 'none'
};

const btnStyle = {
    width: '100%',
    padding: '12px',
    backgroundColor: '#8B4513',
    color: 'white',
    border: 'none',
    borderRadius: '5px',
    cursor: 'pointer',
    fontSize: '16px',
    fontWeight: 'bold',
    marginTop: '10px'
};

export default Register;