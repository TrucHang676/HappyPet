import { useState, useEffect } from 'react';
import { orderService } from '../../services/orderService';
import Swal from 'sweetalert2';
import './Cart.css';
import { useNavigate } from 'react-router-dom';

const Cart = () => {
    // --- 1. KHỞI TẠO STATE ---
    
    const initialOrderCode = (() => {
        const v = localStorage.getItem('currentOrderCode');
        if (!v || v === 'undefined' || v === 'null') return null;
        return String(v).replace(/\+/g, '').trim(); 
    })();

    const [maPhieu, setMaPhieu] = useState(initialOrderCode);
    const [cartInfo, setCartInfo] = useState({ TongThanhTien: 0, PhiGiaoHang: 0, TongThanhTienSC: 0, TongDiemTichLuy: 0 });
    const [cartDetails, setCartDetails] = useState([]);
    const [diemDung, setDiemDung] = useState(0);
    const [loading, setLoading] = useState(true);
    
    const [ngayNhan, setNgayNhan] = useState('');
    const [diaChi, setDiaChi] = useState(''); 
    const [phiShip, setPhiShip] = useState(0); 

    const navigate = useNavigate();
    const DEFAULT_PET_IMG = 'https://placehold.co/80x80?text=Pet+Shop';

    // --- 2. CÁC HÀM XỬ LÝ LOGIC ---

    const defaultTomorrow = () => {
        const d = new Date();
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() + 1); 
        return d.toISOString().split('T')[0];
    };

    const calculateShippingFee = (dateVal) => {
        if (!dateVal) return 0;
        const today = new Date(); today.setHours(0,0,0,0);
        const selectedDate = new Date(dateVal); selectedDate.setHours(0,0,0,0);
        const diffTime = selectedDate - today;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays <= 1) return 35000; 
        if (diffDays === 2) return 25000; 
        return 15000;                     
    };

    const handleDateChange = (e) => {
        const dateVal = e.target.value;
        setNgayNhan(dateVal);
        setPhiShip(calculateShippingFee(dateVal));
    };

    // 🔥 LOGIC ĐIỂM TÍCH LŨY (Chặn nếu điểm = 0)
    const handlePointChange = (e) => {
        const maxPoints = cartInfo?.TongDiemTichLuy || 0;
        if (maxPoints === 0) return; // Không cho nhập nếu không có điểm

        let val = parseInt(e.target.value) || 0;
        if (val < 0) val = 0;
        if (val > maxPoints) val = maxPoints; // Không cho nhập lố
        setDiemDung(val);
    };

    const normalizeStr = (str) => {
        if (!str) return '';
        return str.normalize("NFD")
                  .replace(/[\u0300-\u036f]/g, "")
                  .replace(/đ/g, "d").replace(/Đ/g, "D")
                  .toLowerCase().trim();
    };

    // --- 3. LOAD GIỎ HÀNG ---
    const loadCart = async () => {
        setLoading(true);
        try {
            const currentCode = localStorage.getItem('currentOrderCode')?.replace(/\+/g, '').trim();
            
            // 🔥 NẾU KHÔNG CÓ CODE => GIỎ TRỐNG (Vừa login mới hoặc đã checkout)
            if (!currentCode) {
                setCartDetails([]);
                setCartInfo({ TongThanhTien: 0, PhiGiaoHang: 0, TongThanhTienSC: 0, TongDiemTichLuy: 0 });
                setPhiShip(0);
                setDiemDung(0);
                setLoading(false);
                return;
            }
            
            const data = await orderService.getCart(currentCode);
            
            let dbItems = [];
            if (data && Array.isArray(data.items)) dbItems = data.items;
            else if (Array.isArray(data)) dbItems = data;

            const cartItems = dbItems.map(it => ({
                MaMatHang: it.MaMatHang || it.id,
                TenMatHang: it.TenMatHang || it.name,
                SoLuong: it.SoLuong || 1,
                DonGia: Number(it.DonGia || 0),
                ThanhTien: Number(it.ThanhTien) || (Number(it.DonGia || 0) * (it.SoLuong || 1)),
                LinkAnh: DEFAULT_PET_IMG 
            }));

            // Lấy Profile User & Điểm tích lũy
            let currentPoints = 0;
            let currentAddress = '';
            if (localStorage.getItem('token')) {
                try {
                    const profile = await orderService.getProfile();
                    currentPoints = profile.TongDiemTichLuy || profile.tongDiemTichLuy || 0;
                    currentAddress = profile.DiaChi || profile.diaChi || '';
                } catch (err) { console.error("Lỗi profile:", err); }
            }

            if (currentAddress && !diaChi) setDiaChi(currentAddress);

            setCartDetails(cartItems);
            const total = cartItems.reduce((s, it) => s + it.ThanhTien, 0);
            
            setCartInfo({ 
                TongThanhTien: total, 
                PhiGiaoHang: 0, 
                TongThanhTienSC: total,
                TongDiemTichLuy: currentPoints
            });
            
            if (ngayNhan) setPhiShip(calculateShippingFee(ngayNhan));
            
        } catch (e) {
            console.error("Lỗi loadCart:", e);
        } finally {
            setTimeout(() => setLoading(false), 300);
        }
    };

    const handleRemoveItem = async (maMH, skipConfirm = false) => {
        if (!skipConfirm) {
            const confirm = await Swal.fire({
                title: 'Xóa món này?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Xóa',
                cancelButtonText: 'Hủy'
            });
            if (!confirm.isConfirmed) return;
        }
        try {
            const code = localStorage.getItem('currentOrderCode')?.replace(/\+/g, '').trim();
            await orderService.removeFromCart(code, maMH);
            await loadCart(); 
        } catch (e) { Swal.fire('Lỗi', 'Không xóa được', 'error'); }
    };

    const handleQuantityChange = async (maMH, delta) => {
        const item = cartDetails.find(it => it.MaMatHang === maMH);
        if (!item) return;
        const newQty = item.SoLuong + delta;
        if (newQty <= 0) { handleRemoveItem(maMH); return; }

        try {
            const branch = localStorage.getItem('shipBranch'); 
            const payload = {
                maMH: maMH, soLuong: delta, maCN: branch, diaChi: '',
                maPhieuHienTai: localStorage.getItem('currentOrderCode')?.replace(/\+/g, '').trim()
            };
            await orderService.addToCart(payload);
            await loadCart();
        } catch (e) { Swal.fire('Lỗi', 'Không cập nhật được', 'error'); }
    };

    useEffect(() => { loadCart(); }, []);

    const formatMoney = (v) => Number(v || 0).toLocaleString('vi-VN') + 'đ';
    const finalTotal = (cartInfo.TongThanhTien || 0) + phiShip - (diemDung * 1000);

    // --- 4. XỬ LÝ THANH TOÁN (CHECK ĐỊA CHỈ KỸ CÀNG) ---
    // --- 4. XỬ LÝ THANH TOÁN (ĐÃ THÊM NAVIGATE & DỌN DẸP MÃ ĐƠN) ---
    const handleCheckout = async () => {
        if (cartDetails.length === 0) return;
        if (!diaChi) { Swal.fire('Lỗi', 'Vui lòng nhập địa chỉ!', 'warning'); return; }
        if (!ngayNhan) { Swal.fire('Lỗi', 'Vui lòng chọn ngày!', 'warning'); return; }

        // CHECK ĐỊA CHỈ TRÙNG KHỚP CHI NHÁNH
        const shipCity = localStorage.getItem('shipCity'); 
        if (shipCity) {
            const addrNorm = normalizeStr(diaChi);
            const cityNorm = normalizeStr(shipCity);
            if (!addrNorm.includes(cityNorm)) {
                Swal.fire({
                    icon: 'error',
                    title: 'Sai khu vực giao hàng!',
                    html: `Bạn đang chọn chi nhánh tại <b>${shipCity}</b>.<br/>Vui lòng nhập địa chỉ thuộc <b>${shipCity}</b>.`
                });
                return;
            }
        }

        setLoading(true);
        try {
            const points = parseInt(diemDung || 0, 10);
            const code = localStorage.getItem('currentOrderCode')?.replace(/\+/g, '').trim();
            
            // 1. Gọi API hoàn tất đơn hàng
            await orderService.completeOrder(code, points, ngayNhan, diaChi);

            // 2. 🔥 QUAN TRỌNG: Xóa mã phiếu cũ ngay lập tức để giỏ hàng trống sạch sẽ
            localStorage.removeItem('currentOrderCode'); 

            // 3. Thông báo thành công
            await Swal.fire({
                icon: 'success',
                title: 'Đặt hàng thành công!',
                text: 'Đơn hàng đã được đặt và đang chờ xử lý.',
                timer: 2000,
                showConfirmButton: false
            });

            // 4. 🔥 CHUYỂN TRANG: Đưa khách sang trang lịch sử đơn hàng ngay
            // Bà kiểm tra xem App.js đang để đường dẫn là /history hay /order-history nha
            navigate('/history'); 

        } catch (error) {
            Swal.fire('Lỗi', error?.message || "Lỗi thanh toán", 'error');
        } finally {
            setLoading(false);
        }
    };

    if (loading) return <div className="empty-cart"><h2>⏳ Đang tải...</h2></div>;

    if (cartDetails.length === 0) return (
        <div className="empty-cart">
            <div className="empty-icon">🛒</div>
            <h2>Giỏ hàng đang trống!</h2>
            <button onClick={() => navigate('/products')}>ĐI MUA SẮM NGAY</button>
        </div>
    );

    return (
        <div className="cart-page-new">
            <h2 className="cart-title-main">🛒 Giỏ Hàng Của Bạn</h2>
            <div className="cart-flex-container">
                <div className="cart-items-column">
                    <div className="cart-card">
                        <h3 className="section-subtitle">Các sản phẩm đã chọn</h3>
                        {cartDetails.map((it, i) => (
                            <div key={i} className="cart-item-modern">
                                <div className="modern-item-left">
                                    <div className="modern-img-box">
                                        <img src={DEFAULT_PET_IMG} alt={it.TenMatHang} />
                                    </div>
                                    <div className="modern-info">
                                        <div className="modern-name">{it.TenMatHang}</div>
                                        <div className="modern-qty-box">
                                            <button className="qty-btn" onClick={() => handleQuantityChange(it.MaMatHang, -1)}>−</button>
                                            <input type="text" className="qty-input-small" value={it.SoLuong} readOnly />
                                            <button className="qty-btn" onClick={() => handleQuantityChange(it.MaMatHang, 1)}>+</button>
                                        </div>
                                        <div className="modern-unit-price">Đơn giá: {formatMoney(it.DonGia)}</div>
                                    </div>
                                </div>
                                <div className="modern-item-right">
                                    <div className="modern-total-price">{formatMoney(it.ThanhTien)}</div>
                                    <button className="modern-remove-btn" onClick={() => handleRemoveItem(it.MaMatHang)}>×</button>
                                </div>
                            </div>
                        ))}
                        
                        <div className="modern-points-section">
                            <div className="points-label">
                                🎁 <span>Dùng điểm tích lũy (Có: <strong>{cartInfo.TongDiemTichLuy}</strong>)</span>
                            </div>
                            <div className="points-input-group">
                                <input 
                                    type="number" 
                                    className="points-field"
                                    value={diemDung} 
                                    onChange={handlePointChange} 
                                    min="0"
                                    max={cartInfo.TongDiemTichLuy}
                                    // 🔥 KHÓA Ô NHẬP NẾU KHÔNG CÓ ĐIỂM
                                    disabled={cartInfo.TongDiemTichLuy <= 0} 
                                    style={{ 
                                        backgroundColor: cartInfo.TongDiemTichLuy <= 0 ? '#f0f0f0' : '#fff',
                                        cursor: cartInfo.TongDiemTichLuy <= 0 ? 'not-allowed' : 'text'
                                    }}
                                />
                                <span className="points-convert-text">
                                    {cartInfo.TongDiemTichLuy > 0 
                                        ? `Điểm (= ${formatMoney(diemDung * 1000)})` 
                                        : '(Bạn chưa có điểm để dùng)'}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="cart-summary-column">
                    <div className="summary-card">
                        <h3 className="section-subtitle">Thông tin thanh toán</h3>
                        <div className="summary-shipping-info">
                            <div className="shipping-policy-box">
                                <b>ℹ️ Quy định phí ship:</b>
                                <ul>
                                    <li>Giao gấp (ngày mai): 35.000đ</li>
                                    <li>Giao nhanh (2 ngày): 25.000đ</li>
                                    <li>Tiết kiệm (&gt;2 ngày): 15.000đ</li>
                                </ul>
                            </div>
                        </div>

                        <div className="form-group-modern">
                            <label>📍 Địa chỉ nhận hàng:</label>
                            <textarea 
                                className="modern-textarea"
                                value={diaChi} 
                                onChange={(e) => setDiaChi(e.target.value)}
                                placeholder={`Nhập địa chỉ giao hàng tại ${localStorage.getItem('shipCity') || '...'}`}
                            ></textarea>
                        </div>

                        <div className="form-group-modern">
                            <label>📅 Ngày muốn nhận:</label>
                            <input 
                                type="date" 
                                className="modern-date-input"
                                min={defaultTomorrow()} 
                                value={ngayNhan} 
                                onChange={handleDateChange} 
                            />
                        </div>

                        <div className="summary-divider"></div>
                        <div className="summary-row"><span>Tạm tính:</span><span>{formatMoney(cartInfo.TongThanhTien)}</span></div>
                        <div className="summary-row"><span>Phí ship:</span><span>{formatMoney(phiShip)}</span></div>
                        {diemDung > 0 && (
                            <div className="summary-row text-green">
                                <span>Giảm giá:</span><span>-{formatMoney(diemDung * 1000)}</span>
                            </div>
                        )}
                        <div className="summary-row-total">
                            <span>TỔNG CỘNG:</span>
                            <span className="final-price">{formatMoney(finalTotal > 0 ? finalTotal : 0)}</span>
                        </div>
                        <button className="modern-checkout-btn" onClick={handleCheckout} disabled={loading}>
                            {loading ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN ĐẶT HÀNG'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};
export default Cart;