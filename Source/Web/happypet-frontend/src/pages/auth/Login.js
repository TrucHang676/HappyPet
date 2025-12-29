// // import React, { useState } from 'react';
// // import axios from 'axios';
// // import { useNavigate, Link } from 'react-router-dom';
// // import { GoogleLogin } from '@react-oauth/google'; 
// // import './Login.css';


// // const Login = () => {
// //     const [formData, setFormData] = useState({ TenDangNhap: '', MatKhau: '' });
// //     const [error, setError] = useState('');
// //     const [loading, setLoading] = useState(false);
// //     const navigate = useNavigate();

// //     const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

// //     // 1. XỬ LÝ ĐĂNG NHẬP THƯỜNG
// //     // Xử lý đăng nhập thường
// //     const handleSubmit = async (e) => {
// //         e.preventDefault();
// //         setLoading(true);
// //         setError('');
// //         try {
// //             const res = await axios.post('http://localhost:5000/api/auth/login', formData);
            
// //             localStorage.setItem('token', res.data.token);
// //             localStorage.setItem('role', res.data.Role);
// //             localStorage.setItem('hoten', res.data.HoTen);
// //             if(res.data.MaUser) localStorage.setItem('MaUser', res.data.MaUser);
            
// //             // 🔥 THÊM DÒNG NÀY VÀO NÈ MOM:
// //             alert("Đăng nhập thành công! Chào mừng " + res.data.HoTen); 

// //             // (Nhờ cái code trong App.js, cái alert này sẽ tự biến thành Toast màu xanh)

// //             if (res.data.Role === 'ADMIN' || res.data.Role === 'NV') {
// //                 navigate('/admin/dashboard');
// //             } else {
// //                 navigate('/');
// //             }
// //         } catch (err) {
// //             setError(err.response?.data?.message || "Lỗi kết nối server!");
// //         } finally {
// //             setLoading(false);
// //         }
// //     };

// //     // 2. XỬ LÝ KHI GOOGLE ĐĂNG NHẬP THÀNH CÔNG
// //     const handleGoogleLoginSuccess = async (googleToken) => {
// //         setLoading(true);
// //         try {
// //             // Gửi token về server check
// //             const res = await axios.post('http://localhost:5000/api/auth/google-login', {
// //                 token: googleToken
// //             });

// //             if (res.data.isNewUser) {
// //                 // 🔥 TRƯỜNG HỢP KHÁCH MỚI: Chuyển sang trang bổ sung thông tin
// //                 // Mang theo Email, Tên, Avatar qua trang kia
// //                 navigate('/complete-profile', { 
// //                     state: { 
// //                         email: res.data.email, 
// //                         name: res.data.name,
// //                         photo: res.data.photo
// //                     } 
// //                 });
// //             } else {
// //                 // 🔥 TRƯỜNG HỢP KHÁCH CŨ: Lưu token và vào luôn
// //                 localStorage.setItem('token', res.data.token);
// //                 localStorage.setItem('role', res.data.Role);
// //                 localStorage.setItem('hoten', res.data.HoTen);
// //                 if(res.data.MaUser) localStorage.setItem('MaUser', res.data.MaUser);
                
// //                 alert("🎉 Đăng nhập Google thành công!");
// //                 navigate('/');
// //             }
// //         } catch (err) {
// //             console.error(err);
// //             setError(err.response?.data?.message || "Lỗi xử lý Google Login");
// //         } finally {
// //             setLoading(false);
// //         }
// //     };

// //     return (
// //         <div className="login-container">
// //             <div className="login-box">
// //                 <h2 className="login-title">CHÀO MỪNG TRỞ LẠI! 👋</h2>
// //                 <p className="login-subtitle">Vui lòng đăng nhập để tiếp tục</p>

// //                 <form onSubmit={handleSubmit}>
// //                     <div className="input-group">
// //                         <label>Tên đăng nhập</label>
// //                         <input 
// //                             type="text" 
// //                             name="TenDangNhap" 
// //                             value={formData.TenDangNhap} 
// //                             onChange={handleChange} 
// //                             placeholder="Nhập tên đăng nhập..." 
// //                             required 
// //                         />
// //                     </div>
// //                     <div className="input-group">
// //                         <label>Mật khẩu</label>
// //                         <input 
// //                             type="password" 
// //                             name="MatKhau" 
// //                             value={formData.MatKhau} 
// //                             onChange={handleChange} 
// //                             placeholder="Nhập mật khẩu..." 
// //                             required 
// //                         />
// //                     </div>

// //                     {error && <div className="error-message">⚠️ {error}</div>}

// //                     <div className="forgot-pass">
// //                         <Link to="/forgot-password">Quên mật khẩu?</Link>
// //                     </div>

// //                     <button type="submit" className="btn-login" disabled={loading}>
// //                         {loading ? 'Đang kiểm tra...' : 'ĐĂNG NHẬP'}
// //                     </button>
// //                 </form>

// //                 <div className="divider"><span>Hoặc đăng nhập với</span></div>

// //                 {/* --- NÚT GOOGLE CHÍNH CHỦ --- */}
// //                 <div id="google-btn-container" style={{display:'flex', justifyContent:'center', marginTop:'10px'}}>
// //                     <GoogleLogin
// //                         onSuccess={credentialResponse => {
// //                             console.log("Google Token:", credentialResponse);
// //                             handleGoogleLoginSuccess(credentialResponse.credential);
// //                         }}
// //                         onError={() => {
// //                             console.log('Login Failed');
// //                             alert("Đăng nhập Google thất bại");
// //                         }}
// //                         useOneTap // Tự động hiện popup gợi ý đăng nhập (bao xịn)
// //                     />
// //                 </div>

// //                 <p className="register-link">
// //                     Chưa có tài khoản? <Link to="/register">Đăng ký ngay</Link>
// //                 </p>

// //                 {/* Link đăng nhập nội bộ */}
// //                 <div style={{marginTop: '20px', borderTop: '1px solid #eee', paddingTop: '15px'}}>
// //                     <p style={{fontSize: '14px', color: '#555'}}>
// //                         Bạn là nhân viên? <Link to="/admin/login" style={{color: '#d32f2f', fontWeight: 'bold', textDecoration:'underline'}}>Đăng nhập nội bộ</Link>
// //                     </p>
// //                 </div>
// //             </div>
// //         </div>
// //     );
// // };

// // export default Login;

// // // import React, { useState } from 'react';
// // // import axios from 'axios';
// // // import { useNavigate, Link } from 'react-router-dom';
// // // import { GoogleLogin } from '@react-oauth/google'; 
// // // import { toast } from 'react-toastify'; // Import toast để thông báo đẹp hơn
// // // import './Login.css';

// // // const Login = () => {
// // //     const [formData, setFormData] = useState({ TenDangNhap: '', MatKhau: '' });
// // //     const [error, setError] = useState('');
// // //     const [loading, setLoading] = useState(false);
// // //     const navigate = useNavigate();

// // //     const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

// // //     // 1. XỬ LÝ ĐĂNG NHẬP THƯỜNG
// // //     const handleSubmit = async (e) => {
// // //         e.preventDefault();
// // //         setLoading(true);
// // //         setError('');
        
// // //         try {
// // //             const res = await axios.post('http://localhost:5000/api/auth/login', formData);
            
// // //             // 1. Lưu Token & Thông tin User
// // //             localStorage.setItem('token', res.data.token);
            
// // //             // Lưu nguyên object user để tiện dùng (bao gồm role chuẩn từ backend)
// // //             localStorage.setItem('user', JSON.stringify(res.data.user)); 

// // //             // Lưu lẻ các biến nếu cần dùng nhanh ở chỗ khác (Optional)
// // //             localStorage.setItem('role', res.data.user.role); 
// // //             if(res.data.user.MaUser) localStorage.setItem('MaUser', res.data.user.MaUser);
            
// // //             // Thông báo thành công
// // //             toast.success("Đăng nhập thành công! Chào mừng " + res.data.user.HoTen); 

// // //             // 2. PHÂN LUỒNG ĐIỀU HƯỚNG DỰA TRÊN ROLE
// // //             const role = res.data.user.role; // Role này Backend đã trả về chuẩn (VD: 'Bác sĩ', 'Nhân viên Tiếp tân')

// // //             if (['Bác sĩ', 'Bác sĩ thú y', 'BS'].includes(role)) {
// // //                 navigate('/doctor/dashboard');
// // //             } 
// // //             else if (['Nhân viên Tiếp tân', 'Nhân viên bán hàng', 'Quản lý chi nhánh', 'NV'].includes(role)) {
// // //                 navigate('/employee/dashboard');
// // //             } 
// // //             else {
// // //                 // Khách hàng hoặc role khác -> Về trang chủ
// // //                 navigate('/');
// // //             }

// // //         } catch (err) {
// // //             const msg = err.response?.data?.message || "Lỗi kết nối server!";
// // //             setError(msg);
// // //             toast.error(msg);
// // //         } finally {
// // //             setLoading(false);
// // //         }
// // //     };

// // //     // 2. XỬ LÝ KHI GOOGLE ĐĂNG NHẬP THÀNH CÔNG
// // //     const handleGoogleLoginSuccess = async (googleToken) => {
// // //         setLoading(true);
// // //         try {
// // //             // Gửi token về server check
// // //             const res = await axios.post('http://localhost:5000/api/auth/google-login', {
// // //                 token: googleToken
// // //             });

// // //             if (res.data.isNewUser) {
// // //                 // 🔥 TRƯỜNG HỢP KHÁCH MỚI: Chuyển sang trang bổ sung thông tin
// // //                 navigate('/complete-profile', { 
// // //                     state: { 
// // //                         email: res.data.email, 
// // //                         name: res.data.name,
// // //                         photo: res.data.photo
// // //                     } 
// // //                 });
// // //             } else {
// // //                 // 🔥 TRƯỜNG HỢP KHÁCH CŨ: Lưu token và vào luôn
// // //                 localStorage.setItem('token', res.data.token);
// // //                 localStorage.setItem('user', JSON.stringify(res.data.user));
// // //                 localStorage.setItem('role', res.data.user.role);
                
// // //                 toast.success("🎉 Đăng nhập Google thành công!");
// // //                 navigate('/');
// // //             }
// // //         } catch (err) {
// // //             console.error(err);
// // //             const msg = err.response?.data?.message || "Lỗi xử lý Google Login";
// // //             setError(msg);
// // //             toast.error(msg);
// // //         } finally {
// // //             setLoading(false);
// // //         }
// // //     };

// // //     return (
// // //         <div className="login-container">
// // //             <div className="login-box">
// // //                 <h2 className="login-title">CHÀO MỪNG TRỞ LẠI! 👋</h2>
// // //                 <p className="login-subtitle">Vui lòng đăng nhập để tiếp tục</p>

// // //                 <form onSubmit={handleSubmit}>
// // //                     <div className="input-group">
// // //                         <label>Tên đăng nhập</label>
// // //                         <input 
// // //                             type="text" 
// // //                             name="TenDangNhap" 
// // //                             value={formData.TenDangNhap} 
// // //                             onChange={handleChange} 
// // //                             placeholder="Nhập tên đăng nhập..." 
// // //                             required 
// // //                         />
// // //                     </div>
// // //                     <div className="input-group">
// // //                         <label>Mật khẩu</label>
// // //                         <input 
// // //                             type="password" 
// // //                             name="MatKhau" 
// // //                             value={formData.MatKhau} 
// // //                             onChange={handleChange} 
// // //                             placeholder="Nhập mật khẩu..." 
// // //                             required 
// // //                         />
// // //                     </div>

// // //                     {error && <div className="error-message">⚠️ {error}</div>}

// // //                     <div className="forgot-pass">
// // //                         <Link to="/forgot-password">Quên mật khẩu?</Link>
// // //                     </div>

// // //                     <button type="submit" className="btn-login" disabled={loading}>
// // //                         {loading ? 'Đang kiểm tra...' : 'ĐĂNG NHẬP'}
// // //                     </button>
// // //                 </form>

// // //                 <div className="divider"><span>Hoặc đăng nhập với</span></div>

// // //                 {/* --- NÚT GOOGLE CHÍNH CHỦ --- */}
// // //                 <div id="google-btn-container" style={{display:'flex', justifyContent:'center', marginTop:'10px'}}>
// // //                     <GoogleLogin
// // //                         onSuccess={credentialResponse => {
// // //                             handleGoogleLoginSuccess(credentialResponse.credential);
// // //                         }}
// // //                         onError={() => {
// // //                             toast.error("Đăng nhập Google thất bại");
// // //                         }}
// // //                         useOneTap 
// // //                     />
// // //                 </div>

// // //                 <p className="register-link">
// // //                     Chưa có tài khoản? <Link to="/register">Đăng ký ngay</Link>
// // //                 </p>

// // //                 {/* Link đăng nhập nội bộ (Có thể bỏ nếu form trên đã hỗ trợ login nội bộ) */}
// // //                 {/* <div style={{marginTop: '20px', borderTop: '1px solid #eee', paddingTop: '15px'}}>
// // //                     <p style={{fontSize: '14px', color: '#555'}}>
// // //                         Bạn là nhân viên? <Link to="/admin/login" style={{color: '#d32f2f', fontWeight: 'bold', textDecoration:'underline'}}>Đăng nhập nội bộ</Link>
// // //                     </p>
// // //                 </div> 
// // //                 */}
// // //             </div>
// // //         </div>
// // //     );
// // // };

// // // export default Login;

// import React, { useState } from 'react';
// import axios from 'axios';
// import { useNavigate, Link } from 'react-router-dom';
// import { GoogleLogin } from '@react-oauth/google'; 
// import { toast } from 'react-toastify'; // Dùng toast cho đẹp
// import './Login.css';

// const Login = () => {
//     const [formData, setFormData] = useState({ TenDangNhap: '', MatKhau: '' });
//     const [loading, setLoading] = useState(false);
//     const navigate = useNavigate();

//     const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

//     // --- XỬ LÝ ĐĂNG NHẬP (LOGIC MỚI) ---
//     const handleSubmit = async (e) => {
//         e.preventDefault();
//         setLoading(true);
        
//         try {
//             // 1. Gọi API
//             const res = await axios.post('http://localhost:5000/api/auth/login', formData);
            
//             // 2. Lưu thông tin (Lưu chuẩn theo Backend mới sửa)
//             localStorage.setItem('token', res.data.token);
//             // Lưu nguyên cục user (chứa role, hoten, macn...)
//             localStorage.setItem('user', JSON.stringify(res.data.user)); 
                        // 🔥 Xóa giỏ hàng cũ khi đăng nhập mới
            localStorage.removeItem('currentOrderCode');
            //             // 3. Thông báo
//             toast.success(`🎉 Chào mừng ${res.data.user.HoTen} trở lại!`);

//             // 4. PHÂN LUỒNG ĐIỀU HƯỚNG (QUAN TRỌNG 🔥)
//             // Lấy role từ trong cục user ra check
//             const role = res.data.user.role; 

//             // Nếu là Bác sĩ -> Vào trang Bác sĩ
//             if (['Bác sĩ', 'Bác sĩ thú y', 'BS'].includes(role)) {
//                 navigate('/doctor/dashboard');
//             } 
//             // Nếu là Nhân viên -> Vào trang Nhân viên
//             else if (['Nhân viên Tiếp tân', 'Nhân viên bán hàng', 'Quản lý chi nhánh', 'NV'].includes(role)) {
//                 navigate('/employee/dashboard');
//             } 
//             // Khách hàng -> Về trang chủ
//             else {
//                 navigate('/');
//             }

//         } catch (err) {
//             // Báo lỗi chuẩn
//             const msg = err.response?.data?.message || "Lỗi kết nối hoặc sai thông tin!";
//             toast.error(msg);
//         } finally {
//             setLoading(false);
//         }
//     };

//     // --- XỬ LÝ GOOGLE LOGIN ---
//     const handleGoogleLoginSuccess = async (googleToken) => {
//         setLoading(true);
//         try {
//             const res = await axios.post('http://localhost:5000/api/auth/google-login', { token: googleToken });
            
//             if (res.data.isNewUser) {
//                 navigate('/complete-profile', { state: { email: res.data.email, name: res.data.name, photo: res.data.photo } });
//             } else {
//                 localStorage.setItem('token', res.data.token);
//                 localStorage.setItem('user', JSON.stringify(res.data.user));
//                 toast.success("Đăng nhập Google thành công!");
//                 navigate('/');
//             }
//         } catch (err) {
//             toast.error("Lỗi đăng nhập Google!");
//         } finally {
//             setLoading(false);
//         }
//     };

//     return (
//         <div className="login-container">
//             <div className="login-box">
//                 <h2 className="login-title">CHÀO MỪNG TRỞ LẠI! 👋</h2>
//                 <p className="login-subtitle">Hệ thống HappyPet</p>

//                 <form onSubmit={handleSubmit}>
//                     <div className="input-group">
//                         <label>Tên đăng nhập</label>
//                         <input 
//                             type="text" name="TenDangNhap" 
//                             value={formData.TenDangNhap} onChange={handleChange} 
//                             placeholder="Nhập tên đăng nhập..." required 
//                         />
//                     </div>
//                     <div className="input-group">
//                         <label>Mật khẩu</label>
//                         <input 
//                             type="password" name="MatKhau" 
//                             value={formData.MatKhau} onChange={handleChange} 
//                             placeholder="Nhập mật khẩu..." required 
//                         />
//                     </div>

//                     <div className="forgot-pass"><Link to="/forgot-password">Quên mật khẩu?</Link></div>

//                     <button type="submit" className="btn-login" disabled={loading}>
//                         {loading ? 'Đang xử lý...' : 'ĐĂNG NHẬP'}
//                     </button>
//                 </form>

//                 <div className="divider"><span>Hoặc</span></div>

//                 <div style={{display:'flex', justifyContent:'center', marginTop:'10px'}}>
//                     <GoogleLogin 
//                         onSuccess={res => handleGoogleLoginSuccess(res.credential)} 
//                         onError={() => toast.error("Lỗi Google Login")} 
//                         useOneTap 
//                     />
//                 </div>

//                 <p className="register-link">
//                     Chưa có tài khoản? <Link to="/register">Đăng ký ngay</Link>
//                 </p>
//             </div>
//         </div>
//     );
// };

// export default Login;

import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';
import { GoogleLogin } from '@react-oauth/google'; 
import { toast } from 'react-toastify'; // Import thêm cái này cho đẹp nha
import './Login.css';

const Login = () => {
    const [formData, setFormData] = useState({ TenDangNhap: '', MatKhau: '' });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    // 1. XỬ LÝ ĐĂNG NHẬP (Dựa trên code gốc của bà)
    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            // Gọi API y chang code cũ của bà
            const res = await axios.post('http://localhost:5000/api/auth/login', formData);
            
            // 🔥 XÓA GIỎ HÀNG CŨ KHI ĐĂNG NHẬP MỚI
            localStorage.removeItem('currentOrderCode');
            localStorage.removeItem('shipBranch');
            localStorage.removeItem('shipCity');
            
            // --- GIỮ NGUYÊN CÁCH LƯU CŨ CỦA BÀ ---
            localStorage.setItem('token', res.data.token);
            localStorage.setItem('role', res.data.Role);
            localStorage.setItem('hoten', res.data.HoTen);
            if(res.data.MaUser) localStorage.setItem('MaUser', res.data.MaUser);
            
            // 🔥 THÊM DÒNG NÀY ĐỂ "KHỚP LỆNH" VỚI CÁI PROTECTED ROUTE
            // (Vì bên kia nó tìm cái cục tên là 'user' nên mình tạo giả cho nó)
            const userForAuth = { role: res.data.Role, hoten: res.data.HoTen };
            localStorage.setItem('user', JSON.stringify(userForAuth));

            // Hiện thông báo
            toast.success("Đăng nhập thành công! Chào " + res.data.HoTen); 

            // 🔥 PHẦN QUAN TRỌNG: CHIA ĐƯỜNG ĐI (LOGIC MỚI) 🔥
            const role = res.data.Role; // Lấy cái Role mà bà đã lấy được
            console.log("Role nhận được là:", role); // In ra để soi nếu cần

            // 1. Nếu là Bác sĩ
            if (role === 'Bác sĩ' || role === 'Bác sĩ thú y' || role === 'BS') {
                navigate('/doctor/dashboard');
            } 
            // 2. Nếu là Nhân viên hoặc Quản lý
            else if (role === 'Nhân viên Tiếp tân' || role === 'Nhân viên bán hàng' || role === 'Quản lý chi nhánh' || role === 'NV') {
                navigate('/employee/dashboard');
            } 
            // 3. Khách hàng
            else {
                navigate('/');
            }

        } catch (err) {
            console.error("Lỗi đăng nhập:", err);
            // Giữ nguyên cách báo lỗi của bà
            setError(err.response?.data?.message || "Lỗi kết nối server!");
            toast.error(err.response?.data?.message || "Đăng nhập thất bại");
        } finally {
            setLoading(false);
        }
    };

    // 2. XỬ LÝ GOOGLE (Giữ nguyên y chang code bà gửi)
    const handleGoogleLoginSuccess = async (googleToken) => {
        setLoading(true);
        try {
            const res = await axios.post('http://localhost:5000/api/auth/google-login', { token: googleToken });

            if (res.data.isNewUser) {
                navigate('/complete-profile', { 
                    state: { email: res.data.email, name: res.data.name, photo: res.data.photo } 
                });
            } else {
                localStorage.setItem('token', res.data.token);
                localStorage.setItem('role', res.data.Role);
                localStorage.setItem('user', JSON.stringify({ role: res.data.Role })); // Thêm dòng này cho chắc
                
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
                <h2 className="login-title">CHÀO MỪNG TRỞ LẠI! 👋</h2>
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

                    {error && <div className="error-message">⚠️ {error}</div>}

                    <div className="forgot-pass"><Link to="/forgot-password">Quên mật khẩu?</Link></div>

                    <button type="submit" className="btn-login" disabled={loading}>
                        {loading ? 'Đang kiểm tra...' : 'ĐĂNG NHẬP'}
                    </button>
                </form>

                <div className="divider"><span>Hoặc đăng nhập với</span></div>

                <div id="google-btn-container" style={{display:'flex', justifyContent:'center', marginTop:'10px'}}>
                    <GoogleLogin
                        onSuccess={credentialResponse => handleGoogleLoginSuccess(credentialResponse.credential)}
                        onError={() => alert("Đăng nhập Google thất bại")}
                        useOneTap
                    />
                </div>

                <p className="register-link">Chưa có tài khoản? <Link to="/register">Đăng ký ngay</Link></p>
            </div>
        </div>
    );
};

export default Login;