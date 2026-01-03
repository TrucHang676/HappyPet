import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Swal from 'sweetalert2';
import '../customer/Products.css';

const DirectSale = () => {
    const [step, setStep] = useState(1);
    
    // State khách hàng
    const [phoneSearch, setPhoneSearch] = useState('');
    const [customerInfo, setCustomerInfo] = useState(null);
    const [isNewCustomer, setIsNewCustomer] = useState(false);
    const [newCustomerData, setNewCustomerData] = useState({
        hoTen: '',
        sdt: '',
        gioiTinh: 'Nam',
        diaChi: ''
    });
    
    // State sản phẩm
    const [products, setProducts] = useState([]);
    const [selectedProducts, setSelectedProducts] = useState([]);
    const [searchProduct, setSearchProduct] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('');
    
    // State thanh toán
    const [diemMuonDung, setDiemMuonDung] = useState(0);
    const [phuongThucTT, setPhuongThucTT] = useState('Tiền mặt');
    const [invoiceData, setInvoiceData] = useState(null);
    
    const CATEGORIES = [
        { key: '', label: 'Tất cả', icon: '🐾' },
        { key: 'TA', label: 'Thức ăn', icon: '🍲' },
        { key: 'SPK', label: 'Phụ kiện', icon: '🦴' },
        { key: 'T', label: 'Thuốc', icon: '💊' },
        { key: 'QA', label: 'Quần áo', icon: '👕' }
    ];
    
    const FALLBACK_IMG = 'https://placehold.co/300x300?text=HappyPet';
    
    // Load sản phẩm khi chuyển sang bước 2
    useEffect(() => {
        if (step === 2) {
            loadProducts();
        }
    }, [step]);
    
    const loadProducts = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get('http://localhost:5000/api/employee/products', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setProducts(res.data);
        } catch (error) {
            Swal.fire('Lỗi', 'Không thể tải danh sách sản phẩm', 'error');
        }
    };
    
    const handleSearchCustomer = async () => {
        if (!phoneSearch || phoneSearch.length < 10) {
            Swal.fire('Lỗi', 'Vui lòng nhập đúng số điện thoại', 'warning');
            return;
        }
        
        try {
            const token = localStorage.getItem('token');
            const res = await axios.get(`http://localhost:5000/api/employee/search-customer?sdt=${phoneSearch}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            
            if (res.data.found && res.data.customer) {
                setCustomerInfo(res.data.customer);
                setIsNewCustomer(false);
                Swal.fire('Tìm thấy!', `Khách hàng: ${res.data.customer.HoTen}`, 'success');
            } else {
                setIsNewCustomer(true);
                setNewCustomerData({ ...newCustomerData, sdt: phoneSearch });
                Swal.fire('Khách mới', 'Vui lòng nhập thông tin khách hàng', 'info');
            }
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể tìm kiếm', 'error');
        }
    };
    
    const handleCreateCustomer = async () => {
        const { hoTen, sdt, gioiTinh } = newCustomerData;
        
        if (!hoTen || !sdt) {
            Swal.fire('Lỗi', 'Vui lòng nhập đầy đủ Họ tên và SĐT', 'warning');
            return;
        }
        
        try {
            const token = localStorage.getItem('token');
            const res = await axios.post('http://localhost:5000/api/employee/create-customer-simple', 
                {
                    HoTen: hoTen,
                    SDT: sdt,
                    GioiTinh: gioiTinh,
                    DiaChi: newCustomerData.diaChi || ''
                }, 
                { headers: { Authorization: `Bearer ${token}` } }
            );
            
            setCustomerInfo(res.data.customer);
            setIsNewCustomer(false);
            Swal.fire('Thành công!', 'Đã tạo khách hàng mới', 'success');
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể tạo khách hàng', 'error');
        }
    };
    
    const goToSelectProducts = () => {
        if (!customerInfo) {
            Swal.fire('Lỗi', 'Vui lòng chọn/tạo khách hàng trước', 'warning');
            return;
        }
        setStep(2);
    };
    
    const addProduct = (product) => {
        if (product.SoLuongTon <= 0) {
            Swal.fire('Hết hàng', 'Sản phẩm này hiện đã hết', 'warning');
            return;
        }
        
        const existing = selectedProducts.find(p => p.MaMatHang === product.MaMatHang);
        
        if (existing) {
            if (existing.SoLuong >= product.SoLuongTon) {
                Swal.fire('Cảnh báo', `Chỉ còn ${product.SoLuongTon} sản phẩm`, 'warning');
                return;
            }
            setSelectedProducts(selectedProducts.map(p => 
                p.MaMatHang === product.MaMatHang 
                    ? { ...p, SoLuong: p.SoLuong + 1, ThanhTien: (p.SoLuong + 1) * p.DonGia }
                    : p
            ));
        } else {
            setSelectedProducts([...selectedProducts, { 
                ...product, 
                SoLuong: 1,
                ThanhTien: product.DonGia 
            }]);
        }
        
        Swal.fire({
            toast: true,
            position: 'top-end',
            icon: 'success',
            title: `Đã thêm ${product.TenMatHang}`,
            showConfirmButton: false,
            timer: 1500
        });
    };
    
    const removeProduct = (maMatHang) => {
        setSelectedProducts(selectedProducts.filter(p => p.MaMatHang !== maMatHang));
    };
    
    const updateQuantity = (maMatHang, newQty) => {
        if (newQty < 1) return;
        
        const product = products.find(p => p.MaMatHang === maMatHang);
        if (newQty > product?.SoLuongTon) {
            Swal.fire('Cảnh báo', `Chỉ còn ${product.SoLuongTon} sản phẩm`, 'warning');
            return;
        }
        
        setSelectedProducts(selectedProducts.map(p => 
            p.MaMatHang === maMatHang 
                ? { ...p, SoLuong: newQty, ThanhTien: p.DonGia * newQty }
                : p
        ));
    };
    
    const goToPayment = () => {
        if (selectedProducts.length === 0) {
            Swal.fire('Lỗi', 'Vui lòng chọn ít nhất một sản phẩm', 'warning');
            return;
        }
        setStep(3);
    };
    
    const handleCreateOrder = async () => {
        if (selectedProducts.length === 0) {
            Swal.fire('Lỗi', 'Chưa có sản phẩm nào', 'warning');
            return;
        }
        
        const tongTien = selectedProducts.reduce((sum, p) => sum + p.ThanhTien, 0);
        const maxDiem = Math.floor(tongTien / 1000);
        
        if (diemMuonDung > customerInfo.TongDiemTichLuy) {
            Swal.fire('Lỗi', `Khách chỉ có ${customerInfo.TongDiemTichLuy} điểm`, 'warning');
            return;
        }
        
        if (diemMuonDung > maxDiem) {
            Swal.fire('Lỗi', `Chỉ được dùng tối đa ${maxDiem} điểm cho đơn này`, 'warning');
            return;
        }
        
        try {
            const token = localStorage.getItem('token');
            const res = await axios.post('http://localhost:5000/api/employee/direct-sale', 
                {
                    MaKH: customerInfo.MaKH,
                    sanPham: selectedProducts.map(p => ({
                        MaMatHang: p.MaMatHang,
                        SoLuong: p.SoLuong
                    })),
                    DiemMuonDung: diemMuonDung,
                    PhuongThucTT: phuongThucTT
                }, 
                { headers: { Authorization: `Bearer ${token}` } }
            );
            
            setInvoiceData(res.data.invoice);
            Swal.fire('Thành công!', 'Đã tạo đơn hàng và xuất hóa đơn', 'success');
        } catch (error) {
            Swal.fire('Lỗi', error.response?.data?.message || 'Không thể tạo đơn', 'error');
        }
    };
    
    const resetAndStartNew = () => {
        setStep(1);
        setPhoneSearch('');
        setCustomerInfo(null);
        setIsNewCustomer(false);
        setNewCustomerData({ hoTen: '', sdt: '', gioiTinh: 'Nam', diaChi: '' });
        setSelectedProducts([]);
        setSearchProduct('');
        setSelectedCategory('');
        setDiemMuonDung(0);
        setPhuongThucTT('Tiền mặt');
        setInvoiceData(null);
    };
    
    // Filter sản phẩm
    const filteredProducts = products.filter(p => {
        const matchCategory = selectedCategory === '' || p.LoaiMH === selectedCategory;
        const matchSearch = p.TenMatHang?.toLowerCase().includes(searchProduct.toLowerCase());
        return matchCategory && matchSearch;
    });
    
    const tongTien = selectedProducts.reduce((sum, p) => sum + p.ThanhTien, 0);
    const giamTruDiem = diemMuonDung * 1000;
    const thanhToan = Math.max(tongTien - giamTruDiem, 0);
    
    return (
        <div style={{ padding: '20px', maxWidth: '1400px', margin: '0 auto', background: '#f5f5f5', minHeight: '100vh' }}>
            <h2 style={{ fontSize: '32px', marginBottom: '10px' }}>🛒 Bán hàng trực tiếp</h2>
            <p style={{ color: '#666', marginBottom: '30px' }}>Khách vãng lai mua hàng không cần thú cưng</p>
            
            {/* Progress Steps */}
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '30px', gap: '15px' }}>
                {[
                    { num: 1, title: 'Khách hàng' },
                    { num: 2, title: 'Chọn sản phẩm' },
                    { num: 3, title: 'Thanh toán' }
                ].map(s => (
                    <div key={s.num} style={{ 
                        padding: '12px 25px', 
                        background: step >= s.num ? '#4CAF50' : '#ddd',
                        color: step >= s.num ? 'white' : '#999',
                        borderRadius: '8px',
                        fontWeight: step === s.num ? 'bold' : 'normal',
                        fontSize: '16px',
                        boxShadow: step === s.num ? '0 4px 12px rgba(76, 175, 80, 0.4)' : 'none'
                    }}>
                        {s.num}. {s.title}
                    </div>
                ))}
            </div>
            
            {/* BƯỚC 1: TÌM/TẠO KHÁCH HÀNG */}
            {step === 1 && (
                <div style={{ background: 'white', padding: '30px', borderRadius: '12px', boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
                    <h3 style={{ fontSize: '24px', marginBottom: '20px' }}>🔍 Tìm kiếm khách hàng</h3>
                    <div style={{ display: 'flex', gap: '10px', marginBottom: '25px' }}>
                        <input 
                            type="text"
                            placeholder="Nhập số điện thoại khách hàng..."
                            value={phoneSearch}
                            onChange={(e) => setPhoneSearch(e.target.value)}
                            onKeyPress={(e) => e.key === 'Enter' && handleSearchCustomer()}
                            style={{ 
                                flex: 1, 
                                padding: '12px 15px', 
                                fontSize: '16px', 
                                borderRadius: '8px', 
                                border: '2px solid #e0e0e0',
                                outline: 'none'
                            }}
                        />
                        <button 
                            onClick={handleSearchCustomer}
                            style={{ 
                                padding: '12px 35px', 
                                background: '#2196F3', 
                                color: 'white', 
                                border: 'none', 
                                borderRadius: '8px', 
                                cursor: 'pointer',
                                fontSize: '16px',
                                fontWeight: '600'
                            }}
                        >
                            🔍 Tìm kiếm
                        </button>
                    </div>
                    
                    {/* Hiển thị thông tin khách tìm thấy */}
                    {customerInfo && !isNewCustomer && (
                        <div style={{ background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%)', padding: '25px', borderRadius: '10px', marginBottom: '20px', border: '2px solid #4CAF50' }}>
                            <h4 style={{ fontSize: '20px', marginBottom: '15px', color: '#2e7d32' }}>✅ Đã tìm thấy khách hàng</h4>
                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '12px', marginBottom: '20px' }}>
                                <div><strong>Họ tên:</strong> {customerInfo.HoTen}</div>
                                <div><strong>SĐT:</strong> {customerInfo.SDT}</div>
                                <div><strong>Điểm tích lũy:</strong> <span style={{ color: '#ff6b00', fontWeight: 'bold' }}>{customerInfo.TongDiemTichLuy || 0}</span> điểm</div>
                            </div>
                            <button 
                                onClick={goToSelectProducts}
                                style={{ 
                                    padding: '14px 40px', 
                                    background: '#4CAF50', 
                                    color: 'white', 
                                    border: 'none', 
                                    borderRadius: '8px', 
                                    cursor: 'pointer', 
                                    fontSize: '16px',
                                    fontWeight: 'bold'
                                }}
                            >
                                Tiếp tục chọn sản phẩm →
                            </button>
                        </div>
                    )}
                    
                    {/* Form tạo khách mới */}
                    {isNewCustomer && (
                        <div style={{ background: 'linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%)', padding: '25px', borderRadius: '10px', border: '2px solid #FF9800' }}>
                            <h4 style={{ fontSize: '20px', marginBottom: '20px', color: '#e65100' }}>➕ Đăng ký khách hàng mới</h4>
                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '15px', marginBottom: '20px' }}>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Họ tên <span style={{ color: 'red' }}>*</span></label>
                                    <input 
                                        type="text"
                                        value={newCustomerData.hoTen}
                                        onChange={(e) => setNewCustomerData({...newCustomerData, hoTen: e.target.value})}
                                        style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>SĐT <span style={{ color: 'red' }}>*</span></label>
                                    <input 
                                        type="text"
                                        value={newCustomerData.sdt}
                                        onChange={(e) => setNewCustomerData({...newCustomerData, sdt: e.target.value})}
                                        style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Giới tính</label>
                                    <select 
                                        value={newCustomerData.gioiTinh}
                                        onChange={(e) => setNewCustomerData({...newCustomerData, gioiTinh: e.target.value})}
                                        style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                                    >
                                        <option value="Nam">Nam</option>
                                        <option value="Nữ">Nữ</option>
                                    </select>
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Địa chỉ</label>
                                    <input 
                                        type="text"
                                        value={newCustomerData.diaChi}
                                        onChange={(e) => setNewCustomerData({...newCustomerData, diaChi: e.target.value})}
                                        placeholder="Tùy chọn"
                                        style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                                    />
                                </div>
                            </div>
                            <button 
                                onClick={handleCreateCustomer}
                                style={{ 
                                    padding: '14px 40px', 
                                    background: '#FF9800', 
                                    color: 'white', 
                                    border: 'none', 
                                    borderRadius: '8px', 
                                    cursor: 'pointer', 
                                    fontSize: '16px',
                                    fontWeight: 'bold'
                                }}
                            >
                                Đăng ký & Tiếp tục →
                            </button>
                        </div>
                    )}
                </div>
            )}
            
            {/* BƯỚC 2: CHỌN SẢN PHẨM */}
            {step === 2 && (
                <div style={{ display: 'flex', gap: '20px', alignItems: 'flex-start' }}>
                    {/* Danh sách sản phẩm */}
                    <div style={{ flex: 3, background: 'white', padding: '25px', borderRadius: '12px', boxShadow: '0 2px 12px rgba(0,0,0,0.08)' }}>
                        <h3 style={{ fontSize: '24px', marginBottom: '20px' }}>📦 Danh sách sản phẩm</h3>
                        
                        {/* Categories */}
                        <div style={{ display: 'flex', gap: '10px', marginBottom: '20px', flexWrap: 'wrap' }}>
                            {CATEGORIES.map(cat => (
                                <button 
                                    key={cat.key}
                                    onClick={() => setSelectedCategory(cat.key)}
                                    style={{
                                        padding: '10px 20px',
                                        background: selectedCategory === cat.key ? '#4CAF50' : '#f5f5f5',
                                        color: selectedCategory === cat.key ? 'white' : '#333',
                                        border: 'none',
                                        borderRadius: '25px',
                                        cursor: 'pointer',
                                        fontSize: '14px',
                                        fontWeight: '600'
                                    }}
                                >
                                    {cat.icon} {cat.label}
                                </button>
                            ))}
                        </div>
                        
                        {/* Search */}
                        <input 
                            type="text"
                            placeholder="🔍 Tìm sản phẩm..."
                            value={searchProduct}
                            onChange={(e) => setSearchProduct(e.target.value)}
                            style={{ 
                                width: '100%', 
                                padding: '12px', 
                                marginBottom: '20px', 
                                borderRadius: '8px', 
                                border: '2px solid #e0e0e0',
                                fontSize: '15px'
                            }}
                        />
                        
                        {/* Product Grid */}
                        <div style={{ 
                            display: 'grid', 
                            gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', 
                            gap: '20px',
                            maxHeight: '600px',
                            overflowY: 'auto',
                            padding: '10px'
                        }}>
                            {filteredProducts.map(product => (
                                <div key={product.MaMatHang} style={{
                                    background: 'white',
                                    borderRadius: '10px',
                                    overflow: 'hidden',
                                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                                    transition: 'transform 0.3s, box-shadow 0.3s',
                                    cursor: 'pointer'
                                }}>
                                    <img 
                                        src={FALLBACK_IMG}
                                        alt={product.TenMatHang}
                                        style={{ width: '100%', height: '180px', objectFit: 'cover' }}
                                    />
                                    <div style={{ padding: '15px' }}>
                                        <h4 style={{ 
                                            fontSize: '15px', 
                                            marginBottom: '8px', 
                                            height: '40px', 
                                            overflow: 'hidden'
                                        }}>
                                            {product.TenMatHang}
                                        </h4>
                                        <div style={{ color: '#FF6B00', fontSize: '17px', fontWeight: 'bold', marginBottom: '10px' }}>
                                            {product.DonGia?.toLocaleString()} đ
                                        </div>
                                        <div style={{ color: product.SoLuongTon > 0 ? '#4CAF50' : '#f44336', fontSize: '13px', marginBottom: '10px' }}>
                                            {product.SoLuongTon > 0 ? `Còn ${product.SoLuongTon} sp` : 'Hết hàng'}
                                        </div>
                                        <button 
                                            onClick={() => addProduct(product)}
                                            disabled={product.SoLuongTon <= 0}
                                            style={{ 
                                                width: '100%',
                                                padding: '10px', 
                                                background: product.SoLuongTon > 0 ? '#4CAF50' : '#ccc', 
                                                color: 'white', 
                                                border: 'none', 
                                                borderRadius: '6px', 
                                                cursor: product.SoLuongTon > 0 ? 'pointer' : 'not-allowed',
                                                fontWeight: '600'
                                            }}
                                        >
                                            {product.SoLuongTon > 0 ? '+ Thêm vào giỏ' : 'Hết hàng'}
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                        
                        {filteredProducts.length === 0 && (
                            <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
                                Không tìm thấy sản phẩm nào
                            </div>
                        )}
                    </div>
                    
                    {/* Giỏ hàng */}
                    <div style={{ 
                        flex: 1, 
                        minWidth: '320px',
                        background: 'white', 
                        padding: '25px', 
                        borderRadius: '12px', 
                        boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
                        position: 'sticky',
                        top: '20px'
                    }}>
                        <h3 style={{ fontSize: '20px', marginBottom: '20px' }}>🛒 Giỏ hàng ({selectedProducts.length})</h3>
                        
                        <div style={{ maxHeight: '400px', overflowY: 'auto', marginBottom: '15px' }}>
                            {selectedProducts.length === 0 ? (
                                <div style={{ textAlign: 'center', padding: '30px', color: '#999' }}>
                                    Chưa có sản phẩm nào
                                </div>
                            ) : (
                                selectedProducts.map(product => (
                                    <div key={product.MaMatHang} style={{ 
                                        padding: '12px',
                                        marginBottom: '10px',
                                        background: '#f9f9f9',
                                        borderRadius: '8px',
                                        border: '1px solid #e0e0e0'
                                    }}>
                                        <div style={{ fontWeight: '600', marginBottom: '8px', fontSize: '14px' }}>
                                            {product.TenMatHang}
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                <button 
                                                    onClick={() => updateQuantity(product.MaMatHang, product.SoLuong - 1)}
                                                    style={{ 
                                                        padding: '5px 10px', 
                                                        background: '#f44336', 
                                                        color: 'white', 
                                                        border: 'none', 
                                                        borderRadius: '5px',
                                                        cursor: 'pointer',
                                                        fontSize: '14px'
                                                    }}
                                                >
                                                    -
                                                </button>
                                                <span style={{ minWidth: '30px', textAlign: 'center', fontWeight: 'bold' }}>
                                                    {product.SoLuong}
                                                </span>
                                                <button 
                                                    onClick={() => updateQuantity(product.MaMatHang, product.SoLuong + 1)}
                                                    style={{ 
                                                        padding: '5px 10px', 
                                                        background: '#4CAF50', 
                                                        color: 'white', 
                                                        border: 'none', 
                                                        borderRadius: '5px',
                                                        cursor: 'pointer',
                                                        fontSize: '14px'
                                                    }}
                                                >
                                                    +
                                                </button>
                                            </div>
                                            <button 
                                                onClick={() => removeProduct(product.MaMatHang)}
                                                style={{ 
                                                    padding: '5px 10px', 
                                                    background: '#ff5252', 
                                                    color: 'white', 
                                                    border: 'none', 
                                                    borderRadius: '5px',
                                                    cursor: 'pointer'
                                                }}
                                            >
                                                🗑️
                                            </button>
                                        </div>
                                        <div style={{ color: '#FF6B00', fontWeight: 'bold', fontSize: '15px' }}>
                                            {product.ThanhTien?.toLocaleString()} đ
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                        
                        <div style={{ 
                            borderTop: '2px solid #e0e0e0', 
                            paddingTop: '15px',
                            marginTop: '15px'
                        }}>
                            <div style={{ 
                                display: 'flex', 
                                justifyContent: 'space-between',
                                fontSize: '18px',
                                fontWeight: 'bold',
                                marginBottom: '20px',
                                color: '#FF6B00'
                            }}>
                                <span>Tổng:</span>
                                <span>{tongTien.toLocaleString()} đ</span>
                            </div>
                            <button 
                                onClick={() => setStep(1)}
                                style={{ 
                                    width: '100%',
                                    padding: '12px', 
                                    background: '#999', 
                                    color: 'white', 
                                    border: 'none', 
                                    borderRadius: '8px', 
                                    cursor: 'pointer',
                                    marginBottom: '10px',
                                    fontSize: '15px'
                                }}
                            >
                                ← Quay lại
                            </button>
                            <button 
                                onClick={goToPayment}
                                disabled={selectedProducts.length === 0}
                                style={{ 
                                    width: '100%',
                                    padding: '12px', 
                                    background: selectedProducts.length > 0 ? '#FF9800' : '#ccc', 
                                    color: 'white', 
                                    border: 'none', 
                                    borderRadius: '8px', 
                                    cursor: selectedProducts.length > 0 ? 'pointer' : 'not-allowed',
                                    fontWeight: 'bold',
                                    fontSize: '16px'
                                }}
                            >
                                Thanh toán →
                            </button>
                        </div>
                    </div>
                </div>
            )}
            
            {/* BƯỚC 3: THANH TOÁN */}
            {step === 3 && !invoiceData && (
                <div style={{ background: 'white', padding: '30px', borderRadius: '12px', boxShadow: '0 2px 12px rgba(0,0,0,0.08)', maxWidth: '600px', margin: '0 auto' }}>
                    <h3 style={{ fontSize: '24px', marginBottom: '25px' }}>💳 Thanh toán</h3>
                    
                    <div style={{ marginBottom: '20px', padding: '15px', background: '#f5f5f5', borderRadius: '8px' }}>
                        <h4 style={{ marginBottom: '10px' }}>Thông tin khách hàng</h4>
                        <p><strong>Họ tên:</strong> {customerInfo.HoTen}</p>
                        <p><strong>SĐT:</strong> {customerInfo.SDT}</p>
                        <p><strong>Điểm hiện có:</strong> <span style={{ color: '#FF6B00', fontWeight: 'bold' }}>{customerInfo.TongDiemTichLuy || 0} điểm</span></p>
                    </div>
                    
                    <div style={{ marginBottom: '20px' }}>
                        <h4 style={{ marginBottom: '10px' }}>Danh sách sản phẩm</h4>
                        {selectedProducts.map(p => (
                            <div key={p.MaMatHang} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #eee' }}>
                                <span>{p.TenMatHang} x {p.SoLuong}</span>
                                <span style={{ fontWeight: 'bold' }}>{p.ThanhTien.toLocaleString()} đ</span>
                            </div>
                        ))}
                    </div>
                    
                    <div style={{ marginBottom: '20px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600' }}>Sử dụng điểm tích lũy (1 điểm = 1,000đ)</label>
                        <input 
                            type="number"
                            min="0"
                            max={customerInfo.TongDiemTichLuy || 0}
                            value={diemMuonDung}
                            onChange={(e) => setDiemMuonDung(parseInt(e.target.value) || 0)}
                            disabled={(customerInfo.TongDiemTichLuy || 0) === 0}
                            style={{ 
                                width: '100%', 
                                padding: '10px', 
                                borderRadius: '6px', 
                                border: '1px solid #ddd',
                                background: (customerInfo.TongDiemTichLuy || 0) === 0 ? '#f5f5f5' : 'white',
                                cursor: (customerInfo.TongDiemTichLuy || 0) === 0 ? 'not-allowed' : 'text',
                                color: (customerInfo.TongDiemTichLuy || 0) === 0 ? '#999' : 'black'
                            }}
                        />
                        <small style={{ color: '#666' }}>
                            {(customerInfo.TongDiemTichLuy || 0) === 0 
                                ? 'Khách hàng chưa có điểm tích lũy' 
                                : `Tối đa: ${Math.min(customerInfo.TongDiemTichLuy || 0, Math.floor(tongTien / 1000))} điểm`
                            }
                        </small>
                    </div>
                    
                    <div style={{ marginBottom: '25px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600' }}>Phương thức thanh toán</label>
                        <select 
                            value={phuongThucTT}
                            onChange={(e) => setPhuongThucTT(e.target.value)}
                            style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                        >
                            <option value="Tiền mặt">Tiền mặt</option>
                            <option value="Chuyển khoản">Chuyển khoản</option>
                            <option value="Thẻ">Thẻ</option>
                        </select>
                    </div>
                    
                    <div style={{ background: '#e3f2fd', padding: '20px', borderRadius: '8px', marginBottom: '25px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px' }}>
                            <span>Tổng tiền:</span>
                            <span style={{ fontWeight: 'bold' }}>{tongTien.toLocaleString()} đ</span>
                        </div>
                        {diemMuonDung > 0 && (
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px', color: '#f44336' }}>
                                <span>Giảm trừ điểm:</span>
                                <span>- {giamTruDiem.toLocaleString()} đ</span>
                            </div>
                        )}
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '20px', fontWeight: 'bold', color: '#FF6B00', borderTop: '2px solid #90caf9', paddingTop: '10px' }}>
                            <span>Phải thu:</span>
                            <span>{thanhToan.toLocaleString()} đ</span>
                        </div>
                    </div>
                    
                    <div style={{ display: 'flex', gap: '15px' }}>
                        <button 
                            onClick={() => setStep(2)}
                            style={{ 
                                flex: 1,
                                padding: '14px', 
                                background: '#999', 
                                color: 'white', 
                                border: 'none', 
                                borderRadius: '8px', 
                                cursor: 'pointer',
                                fontSize: '16px'
                            }}
                        >
                            ← Quay lại
                        </button>
                        <button 
                            onClick={handleCreateOrder}
                            style={{ 
                                flex: 2,
                                padding: '14px', 
                                background: '#4CAF50', 
                                color: 'white', 
                                border: 'none', 
                                borderRadius: '8px', 
                                cursor: 'pointer',
                                fontWeight: 'bold',
                                fontSize: '16px'
                            }}
                        >
                            ✓ Xác nhận & Xuất hóa đơn
                        </button>
                    </div>
                </div>
            )}
            
            {/* HÓA ĐƠN THÀNH CÔNG */}
            {invoiceData && (
                <div style={{ background: 'white', padding: '40px', borderRadius: '12px', boxShadow: '0 2px 12px rgba(0,0,0,0.08)', maxWidth: '500px', margin: '0 auto', textAlign: 'center' }}>
                    <div style={{ fontSize: '60px', marginBottom: '20px' }}>✅</div>
                    <h3 style={{ fontSize: '28px', marginBottom: '20px', color: '#4CAF50' }}>Bán hàng thành công!</h3>
                    <div style={{ background: '#f5f5f5', padding: '20px', borderRadius: '8px', marginBottom: '25px', textAlign: 'left' }}>
                        <p><strong>Mã phiếu:</strong> {invoiceData.MaPhieu}</p>
                        <p><strong>Khách hàng:</strong> {customerInfo.HoTen}</p>
                        <p><strong>Tổng tiền:</strong> {invoiceData.TongGiaTri?.toLocaleString()} đ</p>
                        <p><strong>Đã thu:</strong> {invoiceData.SoTienThanhToan?.toLocaleString()} đ</p>
                        {diemMuonDung > 0 && <p><strong>Điểm đã dùng:</strong> {diemMuonDung}</p>}
                        <p><strong>Phương thức:</strong> {phuongThucTT}</p>
                    </div>
                    <button 
                        onClick={resetAndStartNew}
                        style={{ 
                            padding: '14px 40px', 
                            background: '#2196F3', 
                            color: 'white', 
                            border: 'none', 
                            borderRadius: '8px', 
                            cursor: 'pointer',
                            fontWeight: 'bold',
                            fontSize: '16px'
                        }}
                    >
                        Bán đơn mới
                    </button>
                </div>
            )}
        </div>
    );
};

export default DirectSale;
