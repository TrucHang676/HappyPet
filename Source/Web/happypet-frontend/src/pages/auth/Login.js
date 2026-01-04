import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';
import { GoogleLogin } from '@react-oauth/google'; 
import { toast } from 'react-toastify';
import './Login.css';

const Login = () => {
    const [formData, setFormData] = useState({ TenDangNhap: '', MatKhau: '' });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const res = await axios.post('https://happy-pet-fomc.onrender.com/api/auth/login', formData);
            
            localStorage.removeItem('currentOrderCode');
            localStorage.removeItem('shipBranch');
            localStorage.removeItem('shipCity');
            
            localStorage.setItem('token', res.data.token);
            localStorage.setItem('role', res.data.Role);
            localStorage.setItem('hoten', res.data.HoTen);
            if(res.data.MaUser) localStorage.setItem('MaUser', res.data.MaUser);
            if(res.data.ChucVuCuThe) localStorage.setItem('ChucVuCuThe', res.data.ChucVuCuThe);
            if(res.data.MaCN) localStorage.setItem('MaCN', res.data.MaCN);
            
            const userForAuth = { role: res.data.Role, hoten: res.data.HoTen, ChucVuCuThe: res.data.ChucVuCuThe };
            localStorage.setItem('user', JSON.stringify(userForAuth));

            toast.success("Đăng nhập thành công! Chào " + res.data.HoTen); 

            const role = res.data.Role;
            const chucVuCuThe = res.data.ChucVuCuThe;
            console.log("Role nhận được là:", role, "- ChucVuCuThe:", chucVuCuThe);

            if (chucVuCuThe === 'Giám đốc') {
                navigate('/manager/dashboard');
            }
            else if (chucVuCuThe === 'Quản lý chi nhánh') {
                navigate('/branch-manager/dashboard');
            }
            else if (role === 'Bác sĩ' || role === 'Bác sĩ thú y' || role === 'BS') {
                navigate('/doctor/dashboard');
            } 
            else if (role === 'Nhân viên Tiếp tân' || role === 'Nhân viên bán hàng' || role === 'NV') {
                navigate('/employee/dashboard');
            } 
            else {
                navigate('/');
            }

        } catch (err) {
            console.error("Lỗi đăng nhập:", err);
            setError(err.response?.data?.message || "Lỗi kết nối server!");
            toast.error(err.response?.data?.message || "Đăng nhập thất bại");
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleLoginSuccess = async (googleToken) => {
        setLoading(true);
        try {
            const res = await axios.post('https://happy-pet-fomc.onrender.com/api/auth/google-login', { token: googleToken });

            if (res.data.isNewUser) {
                navigate('/complete-profile', { 
                    state: { email: res.data.email, name: res.data.name, photo: res.data.photo } 
                });
            } else {
                localStorage.setItem('token', res.data.token);
                localStorage.setItem('role', res.data.Role);
                localStorage.setItem('user', JSON.stringify({ role: res.data.Role }));
                
                toast.success("Đăng nhập Google thành công!");
                navigate('/');
            }
        } catch (err) {
            setError("Lỗi xử lý Google Login");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="login-container">
            <div className="login-box">
                <h2 className="login-title">CHÀO MỪNG TRỞ LẠI! </h2>
                <p className="login-subtitle">Vui lòng đăng nhập để tiếp tục</p>

                <form onSubmit={handleSubmit}>
                    <div className="input-group">
                        <label>Tên đăng nhập</label>
                        <input type="text" name="TenDangNhap" value={formData.TenDangNhap} onChange={handleChange} placeholder="Nhập tên đăng nhập..." required />
                    </div>
                    <div className="input-group">
                        <label>Mật khẩu</label>
                        <input type="password" name="MatKhau" value={formData.MatKhau} onChange={handleChange} placeholder="Nhập mật khẩu..." required />
                    </div>

                    {error && <div className="error-message"> {error}</div>}

                    <div className="forgot-pass"><Link to="/forgot-password">Quên mật khẩu?</Link></div>

                    <button type="submit" className="btn-login" disabled={loading}>
                        {loading ? 'Đang kiểm tra...' : 'ĐĂNG NHẬP'}
                    </button>
                </form>

                <div className="divider"><span>Hoặc đăng nhập với</span></div>

                <div id="google-btn-container" style={{display:'flex', justifyContent:'center', marginTop:'10px'}}>
                    <GoogleLogin
                        onSuccess={credentialResponse => handleGoogleLoginSuccess(credentialResponse.credential)}
                        onError={() => toast.error("Đăng nhập Google thất bại")}
                        useOneTap
                    />
                </div>

                <p className="register-link">Chưa có tài khoản? <Link to="/register">Đăng ký ngay</Link></p>
            </div>
        </div>
    );
};

export default Login;