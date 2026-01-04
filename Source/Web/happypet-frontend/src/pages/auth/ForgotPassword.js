import React, { useState } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';
import './ForgotPassword.css';

const ForgotPassword = () => {
  const [step, setStep] = useState(1);
  const [tenTK, setTenTK] = useState('');
  const [masked, setMasked] = useState('');
  const [sdtFull, setSdtFull] = useState('');
  const [newPass, setNewPass] = useState('');
  const [confirmPass, setConfirmPass] = useState('');

  const handleCheckUser = async () => {
    try {
      const res = await axios.get(`https://happy-pet-fomc.onrender.com/api/auth/check-account?TenDangNhap=${tenTK}`);
      setMasked(res.data.maskedPhone);
      // Reset các giá trị nhập trước khi qua bước 2 để tránh bị dính dữ liệu cũ
      setSdtFull('');
      setNewPass('');
      setConfirmPass('');
      setStep(2);
    } catch (err) {
      Swal.fire('Thất bại', err.response?.data?.message || 'Không tìm thấy tài khoản!', 'error');
    }
  };

  const handleReset = async () => {
    if (sdtFull.length !== 10) {
      return Swal.fire('Lưu ý', 'Bà phải nhập đúng 10 số điện thoại xác thực!', 'warning');
    }
    if (newPass !== confirmPass) {
      return Swal.fire('Lỗi', 'Mật khẩu xác nhận không khớp!', 'error');
    }
    if (newPass.length < 6) {
      return Swal.fire('Lưu ý', 'Mật khẩu phải trên 6 ký tự!', 'warning');
    }

    try {
      await axios.post('https://happy-pet-fomc.onrender.com/api/auth/forgot-password', {
        TenDangNhap: tenTK,
        SdtNhapVao: sdtFull,
        MatKhauMoi: newPass
      });
      Swal.fire('Thành công', 'Mật khẩu đã được cập nhật!', 'success');
      window.location.href = '/login';
    } catch (err) {
      Swal.fire('Lỗi', err.response?.data?.message || 'Xác thực thất bại!', 'error');
    }
  };

  return (
    <div className="forgot-wrapper">
      <div className="forgot-card">
        <h2 className="happypet-title">Quên Mật Khẩu 🐾</h2>
        {step === 1 ? (
          <div className="form-step">
            <p>Nhập tên tài khoản khách hàng:</p>
            <input 
              type="text" 
              placeholder="Tên đăng nhập..." 
              value={tenTK} 
              onChange={(e) => setTenTK(e.target.value)} 
            />
            <button className="btn-happypet" onClick={handleCheckUser}>Kiểm tra</button>
          </div>
        ) : (
          <div className="form-step">
            <p>SĐT xác thực: <span className="masked-txt">{masked}</span></p>
            
            {/* Thêm autoComplete="off" để trình duyệt không tự điền tên TK vào đây */}
            <input 
              type="text" 
              placeholder="Nhập đủ 10 số điện thoại" 
              autoComplete="off"
              value={sdtFull} 
              onChange={(e) => setSdtFull(e.target.value)} 
            />
            
            <input 
              type="password" 
              placeholder="Mật khẩu mới" 
              autoComplete="new-password"
              value={newPass} 
              onChange={(e) => setNewPass(e.target.value)} 
            />
            
            <input 
              type="password" 
              placeholder="Xác nhận mật khẩu mới" 
              autoComplete="new-password"
              value={confirmPass} 
              onChange={(e) => setConfirmPass(e.target.value)} 
            />
            
            <button className="btn-happypet" onClick={handleReset}>Đổi mật khẩu</button>
            <button className="btn-back" onClick={() => setStep(1)}>Quay lại</button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ForgotPassword;