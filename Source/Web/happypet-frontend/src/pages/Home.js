
// src/pages/Home.js
import React from 'react';
import { useNavigate } from 'react-router-dom';

const Home = () => {
    const navigate = useNavigate(); 

    // --- HÀM XỬ LÝ CLICK ĐẶT LỊCH (MỚI THÊM) ---
    const handleBookingClick = () => {
        const token = localStorage.getItem('token'); // Lấy token từ bộ nhớ
        
        if (token) {
            // Trường hợp 1: Đã có token (Đã đăng nhập) -> Cho qua đặt lịch
            navigate('/booking');
        } else {
            // Trường hợp 2: Chưa có token (Khách vãng lai) -> Bắt đăng nhập
            alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
            navigate('/login');
        }
    };

    return (
        <div style={{ textAlign: 'center', padding: '50px' }}>
            {/* 1. TIÊU ĐỀ & MÔ TẢ (GIỮ NGUYÊN) */}
            <h1 style={{ color: '#8B4513', marginBottom: '15px' }}>
                Chào mừng đến với HappyPet! 🐶🐱
            </h1>
            <p style={{ fontSize: '18px', color: '#555', marginBottom: '30px' }}>
                Nơi cung cấp các dịch vụ spa và chăm sóc thú cưng tốt nhất cho Boss của bạn.
            </p>
            
            {/* 2. NÚT ĐẶT LỊCH (SỬA ONCLICK) */}
            <button 
                onClick={handleBookingClick} // <--- Thay đổi dòng này (Gọi hàm kiểm tra)
                style={{
                    padding: '15px 30px',
                    fontSize: '18px',
                    backgroundColor: '#ff6f00',
                    color: 'white',
                    border: 'none',
                    borderRadius: '30px',
                    cursor: 'pointer',
                    marginBottom: '40px', 
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                    transition: '0.3s'
                }}
                onMouseOver={(e) => e.target.style.backgroundColor = '#e65100'} 
                onMouseOut={(e) => e.target.style.backgroundColor = '#ff6f00'}
            >
                📅 ĐẶT LỊCH NGAY
            </button>

            {/* 3. HÌNH ẢNH (GIỮ NGUYÊN) */}
            <div style={{ display: 'block' }}>
                <img 
                    src="https://img.freepik.com/free-vector/cute-pets-illustration_53876-112522.jpg" 
                    alt="Happy Pets" 
                    style={{ 
                        maxWidth: '80%', 
                        height: 'auto', 
                        borderRadius: '15px',
                        boxShadow: '0 5px 15px rgba(0,0,0,0.1)'
                    }}
                />
            </div>
        </div>
    );
};

export default Home;

