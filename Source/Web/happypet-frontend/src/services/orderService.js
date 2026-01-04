

import axios from 'axios';

const BASE_URL = 'https://happy-pet-fomc.onrender.com/api';

// --- 1. HELPER: Xử lý Token chuẩn chỉ ---
const getToken = () => {
  const token = localStorage.getItem('token');
  if (!token) {
     const altKeys = ['accessToken', 'jwt'];
     for (const k of altKeys) {
        const t = localStorage.getItem(k);
        if (t) {
           localStorage.setItem('token', t);
           return t;
        }
     }
  }
  return token;
};

const getAuthHeader = () => {
  const token = getToken();
  return token ? { headers: { Authorization: `Bearer ${token}` } } : {};
};

// --- 2. SERVICE CHÍNH ---
export const orderService = {

  // ✅ [CŨ] Lấy danh sách chi nhánh
  getBranches: async () => {
    try {
        const response = await axios.get(`${BASE_URL}/branches`);
        return response.data;
    } catch (error) {
        return [];
    }
  },

  // ✅ [CŨ] Tra cứu sản phẩm
  searchProducts: async (tuKhoa, loaiMH) => {
    const response = await axios.get(`${BASE_URL}/products`, {
        params: { tuKhoa, loaiMH }
    });
    return response.data;
  },

  // ✅ [CŨ] Tra cứu theo chi nhánh
  searchProductsByBranch: async (maCN, tuKhoa, loaiMH) => {
    const response = await axios.get(`${BASE_URL}/products/branch`, {
        params: { maCN, tuKhoa, loaiMH }
    });
    return response.data;
  },

  // ✅ [MỚI] Lấy danh sách sản phẩm
  getProducts: async (tuKhoa = '', loaiMH = '', maCN = '') => {
    const response = await axios.get(`${BASE_URL}/products`, {
      params: { tuKhoa, loaiMH, maCN }
    });
    return response.data;
  },

  // ✅ [MỚI] Lấy giỏ hàng
  // ✅ [SỬA LẠI] Lấy giỏ hàng (Chỉ dành cho User đã đăng nhập)
  // ✅ [SỬA LẠI] Lấy giỏ hàng (Gửi kèm mã phiếu cụ thể)
getCart: async () => {
    const token = getToken();
    if (!token) return { cart: null, items: [] };

    // 1. Lấy mã phiếu đang lưu trong máy
    const currentCode = localStorage.getItem('currentOrderCode');

    // 2. Gửi mã đó lên Backend (qua params)
    // Nếu không có mã (null) thì cứ gửi lên để Backend biết đường trả về rỗng
    const response = await axios.get(`${BASE_URL}/cart`, {
        ...getAuthHeader(),
        params: { maPhieu: currentCode } 
    });
    
    return response.data;
},

  addToCart: async (payload) => {
    try {
      const token = getToken();
      if (!token) throw new Error('Vui lòng đăng nhập để mua hàng.');
      if (!payload.maCN) throw new Error('Vui lòng chọn chi nhánh trước khi thêm.');

      const response = await axios.post(`${BASE_URL}/cart/add`, payload, getAuthHeader());

      if (response.data?.maPhieu) {
        localStorage.setItem('currentOrderCode', response.data.maPhieu);
      }
      return response.data;
    } catch (error) {
      throw error.response?.data?.message || error.message;
    }
  },

  // ✅ [MỚI] Xóa khỏi giỏ
  removeFromCart: async (maPhieu, maMH) => {
    const response = await axios.post(`${BASE_URL}/cart/remove`, { maPhieu, maMH }, getAuthHeader());
    return response.data;
  },

  // 🔥 [QUAN TRỌNG - ĐÃ SỬA] Chốt đơn (Thêm NgayNhanHang và DiaChi)
  completeOrder: async (maPhieu, diemDung = 0, ngayNhan, diaChi) => {
    const response = await axios.post(`${BASE_URL}/orders/complete`, { 
        MaPhieu: maPhieu, 
        DiemDung: diemDung,
        NgayNhanHang: ngayNhan, // Gửi ngày nhận xuống
        DiaChi: diaChi          // Gửi địa chỉ xuống
    }, getAuthHeader());
    return response.data;
  },

  // ✅ [MỚI] Lịch sử đơn hàng
  getOrderHistory: async () => {
    const token = getToken();
    if (!token) return []; 

    try {
      const response = await axios.get(`${BASE_URL}/orders/history`, getAuthHeader());
      return response.data;
    } catch (err) {
      if (err.response?.status === 401) {
        localStorage.removeItem('token');
        window.location.reload(); 
      }
      throw err;
    }
  },
  
  // ✅ [MỚI] Hủy đơn
  cancelOrder: async (maPhieu) => {
      const response = await axios.post(`${BASE_URL}/orders/cancel`, { maPhieu }, getAuthHeader());
      return response.data;
  },

  // ✅ [MỚI] Lấy thông tin cá nhân (để lấy Điểm tích lũy & Địa chỉ)
  getProfile: async () => {
    // ⚠️ LƯU Ý: Bà sửa '/users/profile' thành đúng cái API mà trang "Thông tin cá nhân" đang dùng nhé.
    // Ví dụ: /api/khachhang/detail, /api/auth/me, hoặc /api/users/profile
    const response = await axios.get(`${BASE_URL}/users/profile`, getAuthHeader());
    return response.data;
  }
};