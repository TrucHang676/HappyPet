// import React from 'react';
// import { useNavigate } from 'react-router-dom';
// import './EmployeeDashboard.css';

// const EmployeeDashboard = () => {
//     const navigate = useNavigate();
//     const userName = localStorage.getItem('hoten') || 'Nhân viên';

//     return (
//         <div className="dashboard-container" style={{textAlign: 'center', padding: '50px 20px'}}>
//             <h1 style={{fontSize: '48px', marginBottom: '20px'}}> Chào mừng, {userName}!</h1>
//             <p style={{fontSize: '20px', color: '#7f8c8d', marginBottom: '50px'}}>
//                 Chọn chức năng bạn muốn làm việc
//             </p>

//             <div style={{display: 'flex', gap: '30px', justifyContent: 'center', flexWrap: 'wrap'}}>
//                 <div 
//                     onClick={() => navigate('/employee/bookings')}
//                     style={{
//                         width: '300px', padding: '40px', 
//                         backgroundColor: '#e3f2fd', borderRadius: '15px',
//                         cursor: 'pointer', transition: 'transform 0.2s',
//                         boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
//                     }}
//                     onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
//                     onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
//                 >
//                     <div style={{fontSize: '64px', marginBottom: '20px'}}></div>
//                     <h2 style={{color: '#2196f3', marginBottom: '10px'}}>Lịch Hẹn</h2>
//                     <p style={{color: '#666'}}>Quản lý phiếu khám bệnh và tiêm vaccine</p>
//                 </div>

//                 <div 
//                     onClick={() => navigate('/employee/orders')}
//                     style={{
//                         width: '300px', padding: '40px', 
//                         backgroundColor: '#fff3e0', borderRadius: '15px',
//                         cursor: 'pointer', transition: 'transform 0.2s',
//                         boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
//                     }}
//                     onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
//                     onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
//                 >
//                     <div style={{fontSize: '64px', marginBottom: '20px'}}></div>
//                     <h2 style={{color: '#ff9800', marginBottom: '10px'}}>Đơn Hàng</h2>
//                     <p style={{color: '#666'}}>Quản lý đơn hàng và xác nhận giao hàng</p>
//                 </div>

//                 <div 
//                     onClick={() => navigate('/employee/direct-sale')}
//                     style={{
//                         width: '300px', padding: '40px', 
//                         backgroundColor: '#f3e5f5', borderRadius: '15px',
//                         cursor: 'pointer', transition: 'transform 0.2s',
//                         boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
//                     }}
//                     onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
//                     onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
//                 >
//                     <div style={{fontSize: '64px', marginBottom: '20px'}}>💰</div>
//                     <h2 style={{color: '#9c27b0', marginBottom: '10px'}}>Bán Hàng Trực Tiếp</h2>
//                     <p style={{color: '#666'}}>Khách vãng lai mua hàng (không cần thú cưng)</p>
//                 </div>

//                 <div 
//                     onClick={() => navigate('/employee/recheck-reminder')}
//                     style={{
//                         width: '300px', padding: '40px', 
//                         backgroundColor: '#fce4ec', borderRadius: '15px',
//                         cursor: 'pointer', transition: 'transform 0.2s',
//                         boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
//                     }}
//                     onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
//                     onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
//                 >
//                     <div style={{fontSize: '64px', marginBottom: '20px'}}>🔔</div>
//                     <h2 style={{color: '#e91e63', marginBottom: '10px'}}>Tái Khám</h2>
//                     <p style={{color: '#666'}}>Nhắc nhở khách hàng tái khám</p>
//                 </div>

//                 <div 
//                     onClick={() => navigate('/products')}
//                     style={{
//                         width: '300px', padding: '40px', 
//                         backgroundColor: '#e8f5e9', borderRadius: '15px',
//                         cursor: 'pointer', transition: 'transform 0.2s',
//                         boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
//                     }}
//                     onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
//                     onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
//                 >
//                     <div style={{fontSize: '64px', marginBottom: '20px'}}></div>
//                     <h2 style={{color: '#4caf50', marginBottom: '10px'}}>Sản Phẩm</h2>
//                     <p style={{color: '#666'}}>Xem danh sách sản phẩm và thuốc</p>
//                 </div>
//             </div>
//         </div>
//     );
// };

// export default EmployeeDashboard;

import React from 'react';
import { useNavigate } from 'react-router-dom';
import './EmployeeDashboard.css';

const EmployeeDashboard = () => {
    const navigate = useNavigate();
    const userName = localStorage.getItem('hoten') || 'Nhân viên';

    return (
        <div className="dashboard-container" style={{textAlign: 'center', padding: '50px 20px'}}>
            <h1 style={{fontSize: '48px', marginBottom: '20px'}}> Chào mừng, {userName}!</h1>
            <p style={{fontSize: '20px', color: '#7f8c8d', marginBottom: '50px'}}>
                Chọn chức năng bạn muốn làm việc
            </p>

            <div style={{display: 'flex', gap: '30px', justifyContent: 'center', flexWrap: 'wrap'}}>
                
                {/* 1. LỊCH HẸN */}
                <div 
                    onClick={() => navigate('/employee/bookings')}
                    style={{
                        width: '300px', padding: '40px', 
                        backgroundColor: '#e3f2fd', borderRadius: '15px',
                        cursor: 'pointer', transition: 'transform 0.2s',
                        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                >
                    {/* Icon Lịch */}
                    <div style={{fontSize: '64px', marginBottom: '20px'}}>📅</div>
                    <h2 style={{color: '#2196f3', marginBottom: '10px'}}>Lịch Hẹn</h2>
                    <p style={{color: '#666'}}>Quản lý phiếu khám bệnh và tiêm vaccine</p>
                </div>

                {/* 2. ĐƠN HÀNG */}
                <div 
                    onClick={() => navigate('/employee/orders')}
                    style={{
                        width: '300px', padding: '40px', 
                        backgroundColor: '#fff3e0', borderRadius: '15px',
                        cursor: 'pointer', transition: 'transform 0.2s',
                        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                >
                    {/* Icon Hộp hàng */}
                    <div style={{fontSize: '64px', marginBottom: '20px'}}>📦</div>
                    <h2 style={{color: '#ff9800', marginBottom: '10px'}}>Đơn Hàng</h2>
                    <p style={{color: '#666'}}>Quản lý đơn hàng và xác nhận giao hàng</p>
                </div>

                {/* 3. BÁN HÀNG TRỰC TIẾP */}
                <div 
                    onClick={() => navigate('/employee/direct-sale')}
                    style={{
                        width: '300px', padding: '40px', 
                        backgroundColor: '#f3e5f5', borderRadius: '15px',
                        cursor: 'pointer', transition: 'transform 0.2s',
                        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                >
                    {/* Đổi icon thành Túi mua sắm */}
                    <div style={{fontSize: '64px', marginBottom: '20px'}}>🛍️</div>
                    <h2 style={{color: '#9c27b0', marginBottom: '10px'}}>Bán Hàng</h2>
                    <p style={{color: '#666'}}>Khách hàng mua trực tiếp tại cửa hàng</p>
                </div>

                {/* 4. TÁI KHÁM */}
                <div 
                    onClick={() => navigate('/employee/recheck-reminder')}
                    style={{
                        width: '300px', padding: '40px', 
                        backgroundColor: '#fce4ec', borderRadius: '15px',
                        cursor: 'pointer', transition: 'transform 0.2s',
                        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                >
                    {/* Icon Chuông */}
                    <div style={{fontSize: '64px', marginBottom: '20px'}}>🔔</div>
                    <h2 style={{color: '#e91e63', marginBottom: '10px'}}>Tái Khám</h2>
                    <p style={{color: '#666'}}>Nhắc nhở khách hàng tái khám</p>
                </div>

            </div>
        </div>
    );
};

export default EmployeeDashboard;