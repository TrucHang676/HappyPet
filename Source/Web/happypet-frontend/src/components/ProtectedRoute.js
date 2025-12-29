import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';

const ProtectedRoute = ({ allowedRoles }) => {
    // Lấy user từ localStorage (lưu nguyên cục object user)
    const user = localStorage.getItem('user') ? JSON.parse(localStorage.getItem('user')) : null;
    const token = localStorage.getItem('token');

    // 1. Nếu chưa đăng nhập -> Đá về Login
    if (!token || !user) {
        return <Navigate to="/login" replace />;
    }

    // 2. Kiểm tra quyền
    // user.role lúc này sẽ là "Bác sĩ", "Nhân viên Tiếp tân" (viết hoa/thường y chang Database)
    if (allowedRoles && !allowedRoles.includes(user.role)) {
        console.warn(`⛔ Bị chặn! Role hiện tại: ${user.role}. Yêu cầu: ${allowedRoles}`);
        return <Navigate to="/" replace />; // Không đủ quyền thì về Home
    }

    // 3. Cho phép đi tiếp
    return <Outlet />;
};

export default ProtectedRoute;