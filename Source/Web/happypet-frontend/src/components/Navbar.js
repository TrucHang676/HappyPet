import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import logoImg from '../assets/logo-happypet.png';
import './Navbar.css';
import {
    FaHome, FaStethoscope, FaStore, FaPaw, FaCalendarAlt, FaShoppingCart, FaUserCircle,
    FaClipboardList, FaCashRegister, FaBoxOpen, FaBell, FaChartLine, FaBuilding, FaSyringe, FaUserMd
} from 'react-icons/fa';

const Navbar = () => {
    const navigate = useNavigate();

    const userName = localStorage.getItem('hoten');
    const userRole = localStorage.getItem('role');

    const handleLogout = () => {
        localStorage.clear();
        navigate('/login');
    };

    // --- ĐỊNH NGHĨA CÁC NHÓM QUYỀN ---

    // 1. Nhóm Nhân viên thường (Tiếp tân, Bán hàng, NV, ADMIN hệ thống cũ)
    const isStaff = ['Nhân viên Tiếp tân', 'Nhân viên bán hàng', 'NV', 'ADMIN'].includes(userRole);

    // 2. Nhóm Quản lý / Sếp (Gồm: Quản lý chi nhánh, Admin cấp cao, Giám đốc)
    const isDirector = userRole === 'Giám đốc';
    const isManager = userRole === 'Quản lý chi nhánh' || userRole === 'Admin';
    const isManagerGroup = isDirector || isManager;

    // 3. Nhóm Nội bộ (Gồm tất cả nhân viên + bác sĩ + sếp) -> Để tách biệt với Khách hàng
    const isInternalUser = isStaff || isManagerGroup || userRole === 'Bác sĩ thú y';

    // --- XÁC ĐỊNH LINK LOGO ---
    // Sếp thì về Dashboard quản lý, Nhân viên về Dashboard nhân viên, Khách về Trang chủ
    const logoLink = isManagerGroup ? '/manager/dashboard' : (isInternalUser ? '/employee/dashboard' : '/');

    return (
        <nav className="navbar">
            <div className="navbar-container">

                {/* --- 1. LOGO --- */}
                <Link to={logoLink} className="nav-logo">
                    <img src={logoImg} alt="HappyPet Logo" />
                </Link>


                {/* ================================================================= */}
                {/* PHẦN A: DÀNH RIÊNG CHO NGƯỜI NỘI BỘ (KHÔNG PHẢI KHÁCH HÀNG)       */}
                {/* ================================================================= */}
                {isInternalUser && (
                    <>
                        {isStaff ? (
                            // --- GIAO DIỆN NHÂN VIÊN (GIỮ NGUYÊN - Dồn phải) ---
                            <div className="nav-right-section">
                                <div className="nav-menu-links">
                                    <Link to="/employee/dashboard" className="nav-item">
                                        <FaHome /> Trang nhân viên
                                    </Link>
                                    <Link to="/employee/bookings" className="nav-item">
                                        <FaClipboardList /> Lịch Hẹn
                                    </Link>
                                    <Link to="/employee/orders" className="nav-item">
                                        <FaCashRegister /> Bán Hàng
                                    </Link>
                                    <Link to="/products" className="nav-item">
                                        <FaBoxOpen /> Sản Phẩm
                                    </Link>
                                    <Link to="/recheck-reminder" className="nav-item">
                                        <FaBell /> Nhắc tái khám
                                    </Link>
                                </div>

                                <div className="nav-user-actions">
                                    <div className="dropdown">
                                        <div className="user-info">
                                            <div className="avatar-circle">
                                                {userName ? userName.charAt(0).toUpperCase() : 'U'}
                                            </div>
                                            <span className="user-name">{userName}</span>
                                        </div>
                                        <div className="dropdown-menu">
                                            {/* <Link to="/profile">Hồ sơ cá nhân</Link> */}
                                            <button className="btn-logout-text" onClick={handleLogout}>Đăng xuất</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ) : (
                            // --- GIAO DIỆN SẾP (GIÁM ĐỐC / QUẢN LÝ) & BÁC SĨ ---
                            <>
                                {/* Menu Giữa: TRỐNG */}
                                <div className="nav-menu-links">
                                </div>

                                {/* Menu Phải: Các nút chức năng + Avatar */}
                                <div className="nav-user-actions" style={{ gap: '20px', display: 'flex', alignItems: 'center' }}>

                                    {/* Link TRANG BÁC SĨ (Chỉ hiện cho Bác sĩ) */}
                                    {(userRole === 'Bác sĩ thú y') && (
                                        <Link to="/doctor/dashboard" className="nav-item" style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '16px', color: '#333', fontWeight: '500', textDecoration: 'none' }}>
                                            <FaUserMd /> Trang Bác Sĩ
                                        </Link>
                                    )}

                                    {/* Link THUỐC VÀ VACCINE (Chỉ hiện cho Bác sĩ - Đã bỏ style nút xanh) */}
                                    {(userRole === 'Bác sĩ thú y') && (
                                        <Link
                                            to="/doctor/medicines"
                                            className="nav-item"
                                            style={{
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: '8px',
                                                fontSize: '16px',
                                                color: '#333', // Màu chữ đen như menu thường
                                                fontWeight: '500',
                                                textDecoration: 'none'
                                            }}
                                        >
                                            <FaSyringe /> Thuốc và Vaccine
                                        </Link>
                                    )}

                                    {/* NÚT QUẢN LÝ (Chỉ hiện cho nhóm ManagerGroup - Giữ nguyên style nổi bật cho Sếp) */}
                                    {isManagerGroup && (
                                        <Link
                                            to="/manager/dashboard"
                                            className="nav-item"
                                            style={{
                                                backgroundColor: isDirector ? '#c0392b' : '#8e44ad',
                                                color: 'white',
                                                padding: '8px 20px',
                                                borderRadius: '30px',
                                                fontWeight: 'bold',
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: '10px',
                                                boxShadow: '0 4px 12px rgba(0,0,0, 0.2)',
                                                textDecoration: 'none',
                                                transition: 'all 0.3s ease',
                                                border: '2px solid white'
                                            }}
                                            onMouseEnter={(e) => {
                                                e.currentTarget.style.transform = 'translateY(-2px)';
                                                e.currentTarget.style.filter = 'brightness(1.1)';
                                            }}
                                            onMouseLeave={(e) => {
                                                e.currentTarget.style.transform = 'translateY(0)';
                                                e.currentTarget.style.filter = 'brightness(1)';
                                            }}
                                        >
                                            {isDirector ? <FaBuilding style={{ fontSize: '1.1rem' }} /> : <FaChartLine style={{ fontSize: '1.1rem' }} />}
                                            {isDirector ? 'Quản lý công ty' : 'Quản lý chi nhánh'}
                                        </Link>
                                    )}

                                    {/* Avatar Tài khoản */}
                                    <div className="dropdown">
                                        <div className="user-info">
                                            <div className="avatar-circle">
                                                {userName ? userName.charAt(0).toUpperCase() : 'U'}
                                            </div>
                                            <span className="user-name">{userName}</span>
                                        </div>
                                        <div className="dropdown-menu">
                                            {/* <Link to="/profile">Hồ sơ cá nhân</Link> */}
                                            <button className="btn-logout-text" onClick={handleLogout}>Đăng xuất</button>
                                        </div>
                                    </div>
                                </div>
                            </>
                        )}
                    </>
                )}


                {/* ================================================================= */}
                {/* PHẦN B: DÀNH RIÊNG CHO KHÁCH HÀNG (GIỮ NGUYÊN)                    */}
                {/* ================================================================= */}
                {!isInternalUser && (
                    <div className="nav-right-section">
                        <div className="nav-menu-links">
                            <Link to="/" className="nav-item"><FaHome /> Trang chủ</Link>
                            <Link to="/services" className="nav-item"><FaStethoscope /> Dịch vụ</Link>
                            <Link to="/products" className="nav-item"><FaStore /> Cửa hàng</Link>
                            {userName && <Link to="/my-pets" className="nav-item"><FaPaw /> Thú cưng</Link>}
                            {userName && <Link to="/booking" className="nav-item"><FaCalendarAlt /> Đặt lịch</Link>}
                        </div>

                        <div className="nav-user-actions">
                            <Link to="/cart" className="cart-nav-wrapper">
                                <FaShoppingCart />
                                <span className="cart-badge"></span>
                            </Link>

                            <div className="dropdown">
                                <div className="user-info">
                                    <div className="avatar-circle">
                                        {userName ? userName.charAt(0).toUpperCase() : <FaUserCircle />}
                                    </div>
                                    <span className="user-name">{userName || 'Tài khoản'}</span>
                                </div>
                                <div className="dropdown-menu">
                                    {userName ? (
                                        <>
                                            <Link to="/profile">Hồ sơ cá nhân</Link>
                                            <Link to="/history">Lịch sử đơn hàng</Link>
                                            <Link to="/my-bookings">Lịch sử đặt hẹn</Link>
                                            <hr className="menu-divider" />
                                            <button className="btn-logout-text" onClick={handleLogout}>Đăng xuất</button>
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
                    </div>
                )}

            </div>
        </nav>
    );
};

export default Navbar;