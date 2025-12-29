// import React from 'react';
// import { Link, useNavigate } from 'react-router-dom';
// import './Navbar.css';

// const Navbar = () => {
//     const navigate = useNavigate();
    
//     // Kiểm tra đăng nhập bằng tên hoặc token
//     const userName = localStorage.getItem('hoten');
//     const userRole = localStorage.getItem('role');

//     const handleLogout = () => {
//         localStorage.clear(); 
//         navigate('/login');
//     };

//     return (
//         <nav className="navbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 50px' }}>
            
//             {/* 1. LOGO */}
//             <Link to="/" className="nav-logo">
//                 <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style={{marginRight: '8px'}}>
//                    <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20Z" fill="#8B4513" fillOpacity="0.2"/>
//                    <path d="M12 16C13.6569 16 15 14.6569 15 13C15 11.3431 13.6569 10 12 10C10.3431 10 9 11.3431 9 13C9 14.6569 10.3431 16 12 16Z" fill="#8B4513"/>
//                 </svg>
//                 <span style={{ fontFamily: 'cursive', fontSize: '24px' }}>HappyPet</span>
//             </Link>

//             {/* 2. MENU BÊN PHẢI */}
//             <div className="nav-links" style={{ display: 'flex', alignItems: 'center', gap: '30px', marginLeft: 'auto' }}>
                
//                 {/* MENU CHÍNH */}
//                 <Link to="/" className="nav-item">Trang chủ</Link>
                
//                 {/* 🔥 [SỬA LẠI] Dịch vụ: Chuyển từ Dropdown sang Link trực tiếp 🔥 */}
//                 <Link to="/services" className="nav-item">Dịch vụ</Link>

//                 <Link to="/products" className="nav-item">Cửa hàng</Link>

//                 {/* MENU CHỨC NĂNG */}
//                 {userName && userRole !== 'NV' && userRole !== 'ADMIN' && (
//                     <>
//                         <Link to="/my-pets" className="nav-item" style={{color: '#d35400', fontWeight: '600'}}>
//                             🐾 Thú cưng
//                         </Link>
//                         <Link to="/booking" className="nav-item" style={{color: '#2e7d32', fontWeight: '600'}}>
//                             📅 Đặt Lịch
//                         </Link>
//                     </>
//                 )}

//                 {(userRole === 'NV' || userRole === 'ADMIN') && (
//                      <Link to="/admin/dashboard" className="nav-item" style={{color: 'red', fontWeight: 'bold', border: '1px solid red', padding: '5px 12px', borderRadius: '20px'}}>
//                         🛠️ Quản Trị
//                     </Link>
//                 )}

//                 {/* --- NHÓM TÀI KHOẢN & GIỎ HÀNG --- */}
                
//                 {/* Giỏ hàng: Chỉ hiện khi có userName (Đã đăng nhập) */}
//                 {userName && (
//                     <Link to="/cart" className="cart-nav-wrapper" style={{
//                         width: '40px', height: '40px', 
//                         borderRadius: '50%', 
//                         display: 'flex', justifyContent: 'center', alignItems: 'center',
//                         backgroundColor: '#fff3e0', 
//                         marginLeft: '0'
//                     }}>
//                         <span style={{fontSize: '18px'}}>🛒</span> 
//                         <span className="cart-dot" style={{top: '8px', right: '8px'}}></span>
//                     </Link>
//                 )}

//                 {/* Tài khoản hiển thị FULL TÊN */}
//                 <div className="dropdown">
//                     {/* 1. Phần hiển thị tên & Avatar */}
//                     <span className="nav-item user-menu-item" style={{
//                         display: 'flex', alignItems: 'center', gap: '10px',
//                         padding: '6px 15px', backgroundColor: '#f8f9fa', 
//                         borderRadius: '30px', border: '1px solid #eee'
//                     }}>
//                         <div style={{
//                             width: '28px', height: '28px', borderRadius: '50%', 
//                             background: '#8B4513', color: 'white',
//                             display: 'flex', justifyContent: 'center', alignItems: 'center', fontSize: '14px',
//                             flexShrink: 0
//                         }}>
//                             {userName ? userName.charAt(0).toUpperCase() : 'U'}
//                         </div>
//                         <span style={{fontWeight: '600', fontSize: '14px'}}>
//                             {userName ? userName : 'Tài khoản'} 
//                         </span>
//                     </span>
                    
//                     {/* 2. Menu sổ xuống */}
//                     <div className="dropdown-content" style={{ minWidth: '220px', right: 0 }}>
//                         {userName ? (
//                             <>
//                                 <Link to="/profile">Hồ sơ cá nhân</Link>
                                
//                                 {userRole !== 'NV' && userRole !== 'ADMIN' && (
//                                     <>
//                                         <Link to="/history">Lịch sử đơn hàng</Link>
//                                         <Link to="/my-bookings">Lịch sử đặt hẹn</Link>
//                                     </>
//                                 )}
                                
//                                 <hr style={{margin: '5px 0', border: 'none', borderTop: '1px solid #eee'}}/>
                                
//                                 <button className="btn-logout-text" onClick={handleLogout}>
//                                     Đăng xuất
//                                 </button>
//                             </>
//                         ) : (
//                             <>
//                                 <Link to="/login">Đăng nhập</Link>
//                                 <Link to="/register">Đăng ký</Link>
//                             </>
//                         )}
//                     </div>
//                 </div>
//             </div>
//         </nav>
//     );
// };

// export default Navbar;

import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Navbar.css';

const Navbar = () => {
    const navigate = useNavigate();
    
    const userName = localStorage.getItem('hoten');
    const userRole = localStorage.getItem('role');

    const handleLogout = () => {
        localStorage.clear(); 
        navigate('/login');
    };

    return (
        <nav className="navbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 50px' }}>
            
            {/* 1. LOGO */}
            <Link to={(userRole === 'Nhân viên Tiếp tân' || userRole === 'Nhân viên bán hàng' || userRole === 'NV' || userRole === 'ADMIN') ? '/employee/dashboard' : '/'} className="nav-logo">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style={{marginRight: '8px'}}>
                   <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20Z" fill="#8B4513" fillOpacity="0.2"/>
                   <path d="M12 16C13.6569 16 15 14.6569 15 13C15 11.3431 13.6569 10 12 10C10.3431 10 9 11.3431 9 13C9 14.6569 10.3431 16 12 16Z" fill="#8B4513"/>
                </svg>
                <span style={{ fontFamily: 'cursive', fontSize: '24px' }}>HappyPet</span>
            </Link>

            {/* 2. MENU BÊN PHẢI */}
            <div className="nav-links" style={{ display: 'flex', alignItems: 'center', gap: '30px', marginLeft: 'auto' }}>
                
                <Link to={(userRole === 'Nhân viên Tiếp tân' || userRole === 'Nhân viên bán hàng' || userRole === 'NV' || userRole === 'ADMIN') ? '/employee/dashboard' : '/'} className="nav-item">
                    {(userRole === 'Nhân viên Tiếp tân' || userRole === 'Nhân viên bán hàng' || userRole === 'NV' || userRole === 'ADMIN') ? 'Trang nhân viên' : 'Trang chủ'}
                </Link>
                
                {/* CHỈ HIỆN DỊCH VỤ & CỬA HÀNG CHO KHÁCH HÀNG */}
                {userRole !== 'Bác sĩ thú y' && userRole !== 'NV' && userRole !== 'ADMIN' && userRole !== 'Nhân viên Tiếp tân' && userRole !== 'Nhân viên bán hàng' && (
                    <>
                        <Link to="/services" className="nav-item">Dịch vụ</Link>
                        <Link to="/products" className="nav-item">Cửa hàng</Link>
                    </>
                )}

                {/* MENU CHỨC NĂNG CHO KHÁCH HÀNG - BỎ THÚ CƯNG VÀ ĐẶT LỊCH CHO NHÂN VIÊN */}
                {userName && userRole !== 'NV' && userRole !== 'ADMIN' && userRole !== 'Bác sĩ thú y' && userRole !== 'Nhân viên Tiếp tân' && userRole !== 'Nhân viên bán hàng' && (
                    <>
                        <Link to="/my-pets" className="nav-item" style={{color: '#d35400', fontWeight: '600'}}>
                            🐾 Thú cưng
                        </Link>
                        <Link to="/booking" className="nav-item" style={{color: '#2e7d32', fontWeight: '600'}}>
                            📅 Đặt Lịch
                        </Link>
                    </>
                )}

                {/* MENU RIÊNG CHO BÁC SĨ */}
                {userRole === 'Bác sĩ thú y' && (
                    <Link to="/doctor" className="nav-item" style={{color: '#2e7d32', fontWeight: 'bold', border: '2px solid #2e7d32', padding: '5px 12px', borderRadius: '20px'}}>
                        👨‍⚕️ Trang Bác Sĩ
                    </Link>
                )}

                {/* MENU QUẢN TRỊ */}
                {(userRole === 'NV' || userRole === 'ADMIN' || userRole === 'Nhân viên Tiếp tân' || userRole === 'Nhân viên bán hàng') && (
                     <>
                        <Link to="/employee/bookings" className="nav-item" style={{color: '#2196f3', fontWeight: '600'}}>
                            🏥 Lịch Hẹn
                        </Link>
                        <Link to="/employee/orders" className="nav-item" style={{color: '#ff9800', fontWeight: '600'}}>
                            🛒 Bán Hàng
                        </Link>
                        <Link to="/products" className="nav-item" style={{color: '#4caf50', fontWeight: '600'}}>
                            📦 Sản Phẩm
                        </Link>
                        <Link to="/recheck-reminder" className="nav-item" style={{color: '#e67e22', fontWeight: '600'}}>
                            🔔 Nhắc tái khám
                        </Link>
                    </>
                )}

                {/* 🔥 CHẶN GIỎ HÀNG: Chỉ hiện khi có userName VÀ KHÔNG PHẢI Bác sĩ/Nhân viên */}
                {userName && userRole !== 'Bác sĩ thú y' && userRole !== 'NV' && userRole !== 'ADMIN' && userRole !== 'Nhân viên Tiếp tân' && userRole !== 'Nhân viên bán hàng' && (
                    <Link to="/cart" className="cart-nav-wrapper" style={{
                        width: '40px', height: '40px', 
                        borderRadius: '50%', 
                        display: 'flex', justifyContent: 'center', alignItems: 'center',
                        backgroundColor: '#fff3e0', 
                        marginLeft: '0'
                    }}>
                        <span style={{fontSize: '18px'}}>🛒</span> 
                        <span className="cart-dot" style={{top: '8px', right: '8px'}}></span>
                    </Link>
                )}

                {/* TÀI KHOẢN */}
                <div className="dropdown">
                    <span className="nav-item user-menu-item" style={{
                        display: 'flex', alignItems: 'center', gap: '10px',
                        padding: '6px 15px', backgroundColor: '#f8f9fa', 
                        borderRadius: '30px', border: '1px solid #eee'
                    }}>
                        <div style={{
                            width: '28px', height: '28px', borderRadius: '50%', 
                            background: '#8B4513', color: 'white',
                            display: 'flex', justifyContent: 'center', alignItems: 'center', fontSize: '14px',
                            flexShrink: 0
                        }}>
                            {userName ? userName.charAt(0).toUpperCase() : 'U'}
                        </div>
                        <span style={{fontWeight: '600', fontSize: '14px'}}>
                            {userName ? userName : 'Tài khoản'} 
                        </span>
                    </span>
                    
                    <div className="dropdown-content" style={{ minWidth: '220px', right: 0 }}>
                        {userName ? (
                            <>
                                <Link to="/profile">Hồ sơ cá nhân</Link>
                                
                                {userRole !== 'NV' && userRole !== 'ADMIN' && userRole !== 'Bác sĩ thú y' && (
                                    <>
                                        <Link to="/history">Lịch sử đơn hàng</Link>
                                        <Link to="/my-bookings">Lịch sử đặt hẹn</Link>
                                        <Link to="/recheck-reminder">🔔 Nhắc tái khám</Link>
                                    </>
                                )}
                                
                                <hr style={{margin: '5px 0', border: 'none', borderTop: '1px solid #eee'}}/>
                                
                                <button className="btn-logout-text" onClick={handleLogout}>
                                    Đăng xuất
                                </button>
                            </>
                        ) : (
                            <>
                                <Link to="/login">Đăng nhập</Link>
                                <Link to="/register">Đăng ký</Link>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;