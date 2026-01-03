// import React, { useEffect } from 'react';
// import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

// // 1. Import các thành phần phụ trợ
// import Navbar from './components/Navbar';
// import { ToastContainer, toast } from 'react-toastify';
// import 'react-toastify/dist/ReactToastify.css';
// import ProtectedRoute from './components/ProtectedRoute';

// // 2. Import các trang (Pages)
// import Login from './pages/auth/Login';
// import Register from './pages/auth/Register';
// import Home from './pages/Home';
// import MyPets from './pages/customer/MyPets';
// import Profile from './pages/Profile';
// import Booking from './pages/customer/Booking';
// import SelectVaccine from './pages/customer/SelectVaccine';
// import CompleteProfile from './pages/auth/CompleteProfile';
// import MyBookings from './pages/customer/MyBooking';
// import Products from './pages/customer/Products';
// import Cart from './pages/customer/Cart';
// import History from './pages/customer/History';
// import Services from './pages/Services';

// // Import trang nội bộ
// import DoctorDashboard from './pages/doctor/DoctorDashboard';
// import EmployeeDashboard from './pages/employee/EmployeeDashboard'; 

// function App() {

//   // --- VIETSUB LỖI ---
//   useEffect(() => {
//     const originalAlert = window.alert;
//     window.alert = (message) => {
//       let msg = String(message);
//       if (msg.includes('Violation of PRIMARY KEY')) msg = "Dữ liệu này đã tồn tại!";
//       else if (msg.includes('REFERENCE constraint')) msg = "Dữ liệu đang được liên kết, không thể xóa!";
//       else if (msg.includes('Network Error')) msg = "Lỗi kết nối máy chủ!";
//       else if (msg.includes('String or binary data would be truncated')) msg = "Dữ liệu nhập quá dài!";

//       const lowerMsg = msg.toLowerCase();
//       if (lowerMsg.includes('thành công') || lowerMsg.includes('success')) toast.success(msg);
//       else if (lowerMsg.includes('lỗi') || lowerMsg.includes('thất bại') || lowerMsg.includes('error')) toast.error(msg); 
//       else toast.info(msg);
//     };
//     return () => { window.alert = originalAlert; };
//   }, []);

//   return (
//     <Router>
//       <Navbar />
//       <ToastContainer position="top-right" autoClose={3000} theme="colored" />

//       <Routes>
//           {/* --- KHÁCH HÀNG & CHUNG --- */}
//           <Route path="/" element={<Home />} />
//           <Route path="/login" element={<Login />} />
//           <Route path="/register" element={<Register />} />
//           <Route path="/services" element={<Services />} />
//           <Route path="/products" element={<Products />} />

//           {/* Các route khách hàng cần đăng nhập mới thấy */}
//           <Route path="/my-pets" element={<MyPets />} />
//           <Route path="/profile" element={<Profile />} />
//           <Route path="/booking" element={<Booking />} />
//           <Route path="/complete-profile" element={<CompleteProfile />} />
//           <Route path="/select-vaccine" element={<SelectVaccine />} />
//           <Route path="/my-bookings" element={<MyBookings />} />
//           <Route path="/cart" element={<Cart />} />
//           <Route path="/history" element={<History />} />

//           {/* --- 🔥 KHU VỰC BÁC SĨ --- */}
//           <Route element={<ProtectedRoute allowedRoles={['Bác sĩ thú y', 'BS']} />}>
//               <Route path="/doctor/dashboard" element={<DoctorDashboard />} />
//           </Route>

//           {/* --- 🔥 KHU VỰC TIẾP TÂN VÀ BÁN HÀNG --- */}
//           {/* Bà xem trong DB bà ghi là 'Tiếp tân' hay 'Lễ tân' hay 'Nhân viên' thì điền vào đây */}
//           <Route element={<ProtectedRoute allowedRoles={['Nhân viên tiếp tân', 'Nhân viên bán hàng', 'NV tiếp tân', 'NV']} />}>
//               <Route path="/employee/dashboard" element={<EmployeeDashboard />} />
//           </Route>

//       </Routes>
//     </Router>
//   );
// }

// export default App;


import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

// 1. Import các thành phần phụ trợ
import Navbar from './components/Navbar';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import ProtectedRoute from './components/ProtectedRoute'; // 🔥 PHẢI CÓ CÁI NÀY

// 2. Import các trang (Pages)
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';
import Home from './pages/Home';
import MyPets from './pages/customer/MyPets';
import Profile from './pages/Profile';
import Booking from './pages/customer/Booking';
import SelectVaccine from './pages/customer/SelectVaccine';
import CompleteProfile from './pages/auth/CompleteProfile';
import MyBookings from './pages/customer/MyBooking';
import Products from './pages/customer/Products';
import Cart from './pages/customer/Cart';
import History from './pages/customer/History';
import Services from './pages/Services';
import RecheckReminder from './pages/customer/RecheckReminder';

// Import trang nội bộ (Bác sĩ & Nhân viên) -> 🔥 NÃY BÀ THIẾU 2 DÒNG NÀY
import DoctorDashboard from './pages/doctor/DoctorDashboard';
import ExamDetail from './pages/doctor/ExamDetail';
import VaccineDetail from './pages/doctor/VaccineDetail'; // 🔥 MỚI
import Medicines from './pages/doctor/Medicines'; // 💊 Trang thuốc & vaccine
import EmployeeDashboard from './pages/employee/EmployeeDashboard';
import ServiceBookings from './pages/employee/ServiceBookings';
import OrderManagement from './pages/employee/OrderManagement';
import TestAutoHuy from './pages/employee/TestAutoHuy';
import EmployeeRecheckReminder from './pages/employee/RecheckReminder'; // 🔥 MỚI
import DirectSale from './pages/employee/DirectSale'; // 🔥 BÁN HÀNG TRỰC TIẾP
import ManagerDashboard from './pages/manager/ManagerDashboard'; // 🔥 GIÁM ĐỐC (Dashboard đẹp)
import BranchManagerDashboard from './pages/manager/BranchManagerDashboard'; // 🔥 QUẢN LÝ CHI NHÁNH

function App() {

  // --- VIETSUB LỖI (Giữ nguyên đoạn code xịn của bà) ---
  useEffect(() => {
    const originalAlert = window.alert;
    window.alert = (message) => {
      let msg = String(message);
      if (msg.includes('Violation of PRIMARY KEY') || msg.includes('duplicate key')) {
          msg = "Thao tác thất bại: Dữ liệu này đã tồn tại trong hệ thống.";
      } else if (msg.includes('REFERENCE constraint')) {
          msg = "Không thể xóa: Dữ liệu này đang được sử dụng ở nơi khác.";
      } else if (msg.includes('Network Error')) {
          msg = "Lỗi kết nối máy chủ. Vui lòng thử lại sau.";
      } else if (msg.includes('String or binary data would be truncated')) {
          msg = "Dữ liệu nhập vào quá dài.";
      }

      const lowerMsg = msg.toLowerCase();
      if (lowerMsg.includes('thành công') || lowerMsg.includes('success')) {
         toast.success(msg);
      } else if (lowerMsg.includes('lỗi') || lowerMsg.includes('thất bại') || lowerMsg.includes('error')) {
         toast.error(msg);
      } else {
         toast.info(msg);
      }
    };
    return () => { window.alert = originalAlert; };
  }, []);

  return (
    <Router>
      <Navbar />
      
      <ToastContainer position="top-right" autoClose={3000} theme="colored" />

      <Routes>
          {/* --- KHÁCH HÀNG & CHUNG --- */}
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/services" element={<Services />} />
          <Route path="/products" element={<Products />} />

          {/* Các route khách hàng cần đăng nhập (Tốt nhất là bọc ProtectedRoute luôn nếu muốn) */}
          <Route path="/my-pets" element={<MyPets />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/booking" element={<Booking />} />
          <Route path="/complete-profile" element={<CompleteProfile />} />
          <Route path="/select-vaccine" element={<SelectVaccine />} />
          <Route path="/my-bookings" element={<MyBookings />} />
          <Route path="/cart" element={<Cart />} />
          <Route path="/history" element={<History />} />
          <Route path="/recheck-reminder" element={<RecheckReminder />} />

          {/* --- 🔥 KHU VỰC NHÂN VIÊN (QUAN TRỌNG) --- */}
          {/* Phải có cái này thì đăng nhập xong mới vào Dashboard được */}
          <Route element={<ProtectedRoute allowedRoles={['Nhân viên Tiếp tân', 'Nhân viên bán hàng', 'Quản lý chi nhánh', 'NV']} />}>
              <Route path="/employee/dashboard" element={<EmployeeDashboard />} />
              <Route path="/employee/bookings" element={<ServiceBookings />} />
              <Route path="/employee/orders" element={<OrderManagement />} />
              <Route path="/employee/test-auto-huy" element={<TestAutoHuy />} />
              <Route path="/employee/recheck-reminder" element={<EmployeeRecheckReminder />} />
              <Route path="/employee/direct-sale" element={<DirectSale />} />
          </Route>

          {/* --- 🔥 KHU VỰC BÁC SĨ (QUAN TRỌNG) --- */}
          <Route element={<ProtectedRoute allowedRoles={['Bác sĩ', 'Bác sĩ thú y', 'Quản lý chi nhánh', 'BS']} />}>
              <Route path="/doctor/dashboard" element={<DoctorDashboard />} />
              <Route path="/doctor/exam/:maPhieu" element={<ExamDetail />} />
              <Route path="/doctor/vaccine/:maPhieu" element={<VaccineDetail />} />
              <Route path="/doctor/medicines" element={<Medicines />} /> {/* 💊 Danh sách thuốc & vaccine */}
          </Route>

          {/* --- 🔥 KHU VỰC GIÁM ĐỐC (CHỈ GIÁM ĐỐC) --- */}
          <Route element={<ProtectedRoute allowedRoles={['Giám đốc', 'Admin']} />}>
              <Route path="/manager/dashboard" element={<ManagerDashboard />} />
          </Route>

          {/* --- 🔥 KHU VỰC QUẢN LÝ CHI NHÁNH --- */}
          <Route element={<ProtectedRoute allowedRoles={['Quản lý chi nhánh', 'Admin']} />}>
              <Route path="/branch-manager/dashboard" element={<BranchManagerDashboard />} />
          </Route>

      </Routes>
    </Router>
  );
}

export default App;