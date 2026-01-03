import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { ShoppingCart, Search, ShoppingBag } from 'lucide-react'; // Thêm icon Search, ShoppingBag cho đẹp
import './Shop.css';

const Shop = () => {
    const [products, setProducts] = useState([]);
    const [search, setSearch] = useState('');
    const [type, setType] = useState(''); // Lưu loại mặt hàng đang lọc
    const [loading, setLoading] = useState(false);
    const [cartCount, setCartCount] = useState(0);

    // Danh mục (M có thể thêm hình ảnh thật vào thay cho icon)
    const categories = [
        { id: '', name: 'Tất cả', icon: '🐾' },
        { id: 'T', name: 'Thuốc & Y tế', icon: '💊' },
        { id: 'VC', name: 'Vaccine', icon: '💉' },
        { id: 'SPK', name: 'Phụ kiện & Đồ chơi', icon: '🦴' },
        { id: 'TA', name: 'Thức ăn', icon: '🥣' } // Thêm cái này cho phong phú
    ];

    useEffect(() => {
        const fetchProducts = async () => {
            setLoading(true);
            try {
                const res = await axios.get(`http://localhost:5000/api/products`, { 
                    params: { tuKhoa: search, loaiMH: type }
                });
                setProducts(res.data);
            } catch (err) {
                console.error("Lỗi load sản phẩm:", err);
            } finally {
                setLoading(false);
            }
        };
        fetchProducts();
    }, [search, type]);

// Thay thế toàn bộ const handleAddToCart cũ bằng đoạn này:

    const handleAddToCart = async (product) => {
    // 1. Kiểm tra đăng nhập (Sửa lỗi Ảnh 1)
    const storedMaKH = localStorage.getItem('maKH');
    
    if (!storedMaKH) {
        // Nếu chưa đăng nhập -> Báo lỗi xong DỪNG LUÔN (return)
        alert("Bạn cần đăng nhập để mua hàng!"); 
        return; // <--- CÁI NÀY QUAN TRỌNG NHẤT
    }

    // 2. Nếu đã đăng nhập thì mới chạy tiếp
    try {
        const currentMaPhieu = localStorage.getItem('activeOrder');
        const res = await axios.post(`http://localhost:5000/api/cart/add`, {
            maKH: storedMaKH.trim(),
            maMH: product.MaMatHang,
            maPhieuHienTai: currentMaPhieu,
            diaChi: "Quận 1, Hồ Chí Minh", 
            maCN: "CN001",
            hinhThucTT: "Tiền mặt",
            soLuong: 1
        });

        if (res.data.success) {
            localStorage.setItem('activeOrder', res.data.maPhieu);
            setCartCount(prev => prev + 1);
            // Hiện thông báo thành công (cái bảng to ở giữa)
            alert(`Đã thêm ${product.TenMatHang} vào giỏ!`); 
        }
    } catch (err) {
        console.error(err);
        alert("Lỗi: " + (err.response?.data?.message || err.message));
    }
};
    // Format tiền tệ cho đẹp
    const formatCurrency = (val) => {
        return Number(val).toLocaleString('vi-VN', { style: 'currency', currency: 'VND' });
    };

    return (
        <div className="shop-wrapper">
            
            {/* 1. Header Cửa hàng + Giỏ hàng */}
            <header className="shop-header-bar" style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px'}}>
                <h2 style={{color: '#333', display: 'flex', alignItems: 'center', gap: '10px'}}>
                    <ShoppingBag color="#e67e22" /> Cửa Hàng HappyPet
                </h2>
                <div className="cart-icon-container" style={{position: 'relative', cursor: 'pointer'}}>
                    <ShoppingCart size={28} color="#e67e22" />
                    {cartCount > 0 && <span className="cart-badge" style={{
                        position: 'absolute', top: '-8px', right: '-8px', 
                        background: '#e74c3c', color: 'white', borderRadius: '50%', 
                        padding: '2px 6px', fontSize: '0.7rem', fontWeight: 'bold'
                    }}>{cartCount}</span>}
                </div>
            </header>

            {/* 2. Banner Khuyến mãi (Áp dụng CSS mới) */}
            <div className="shop-banner">
                <div className="banner-content">
                    <h1>Yêu Thương Pet - Sale 20%</h1>
                    <p>Cho toàn bộ phụ kiện & đồ chơi tháng 12</p>
                    <button className="banner-btn">Mua ngay</button>
                </div>
                <div className="banner-image">
                    {/* Thay ảnh thật của m vào đây */}
                    <img src="https://cdn-icons-png.flaticon.com/512/616/616408.png" alt="Pet" /> 
                </div>
            </div>

            {/* 3. Thanh Tìm kiếm (Áp dụng CSS mới) */}
            <div className="search-container">
                <div className="search-box">
                    <Search size={20} color="#999" />
                    <input 
                        type="text" 
                        placeholder="Tìm sản phẩm nhanh..." 
                        value={search}
                        onChange={(e) => setSearch(e.target.value)} 
                    />
                </div>
            </div>

            {/* 4. Danh mục dạng Icon tròn (Áp dụng CSS mới) */}
            <div className="category-section">
                {categories.map(cat => (
                    <div 
                        key={cat.id} 
                        className={`cat-item ${type === cat.id ? 'active' : ''}`}
                        onClick={() => setType(cat.id)}
                    >
                        <div className="cat-icon">{cat.icon}</div>
                        <span className="cat-name">{cat.name}</span>
                    </div>
                ))}
            </div>

            {/* 5. Grid Sản phẩm (Áp dụng CSS mới - Card đẹp hơn) */}
            <h3 className="section-title">Sản phẩm nổi bật</h3>
            {loading ? <p className="loading-spinner">Đang tải sản phẩm...</p> : (
                <div className="product-grid">
                    {products.length > 0 ? products.map(p => (
                        <div key={p.MaMatHang} className="product-card">
                            <div className="card-img">
                                {/* Thay ảnh thật vào đây */}
                                <img 
                                    src={p.HinhAnh ? p.HinhAnh : `https://via.placeholder.com/300x300?text=${p.TenMatHang}`} 
                                    alt={p.TenMatHang}
                                    onError={(e) => { e.target.onerror = null; e.target.src = "https://via.placeholder.com/300x300?text=No+Image"; }} 
                                />
                                {p.TinhTrang === 'Hết hàng' && <span className="badge-out">Hết hàng</span>}
                            </div>
                            
                            <div className="card-body">
                                <span className="card-cate">{p.LoaiMH || 'Sản phẩm'}</span>
                                <h4 className="card-title" title={p.TenMatHang}>{p.TenMatHang}</h4>
                                <p style={{fontSize: '0.8rem', color: '#777', marginBottom: '10px'}}>{p.HangSX || 'Đang cập nhật'}</p>
                                
                                <div className="card-bottom">
                                    <div className="card-price">{formatCurrency(p.DonGia)}</div>
                                    <button 
                                        className="btn-add-cart" 
                                        disabled={p.TinhTrang === 'Hết hàng'}
                                        onClick={() => handleAddToCart(p)}
                                        title="Thêm vào giỏ"
                                    >
                                        <ShoppingCart size={18} />
                                    </button>
                                </div>
                            </div>
                        </div>
                    )) : <p className="no-result">Không tìm thấy sản phẩm nào! 😿</p>}
                </div>
            )}
        </div>
    );
};

export default Shop;

// import React, { useState, useEffect } from 'react';
// import axios from 'axios';
// import { ShoppingCart, Search, ShoppingBag } from 'lucide-react'; 
// import './Shop.css';

// const Shop = () => {
//     const [products, setProducts] = useState([]);
//     const [search, setSearch] = useState('');
//     const [type, setType] = useState(''); // Lưu loại mặt hàng đang lọc
//     const [loading, setLoading] = useState(false);
//     const [cartCount, setCartCount] = useState(0);

//     // Danh mục (Giữ nguyên y chang cũ)
//     const categories = [
//         { id: '', name: 'Tất cả', icon: '🐾' },
//         { id: 'T', name: 'Thuốc & Y tế', icon: '💊' },
//         { id: 'VC', name: 'Vaccine', icon: '💉' },
//         { id: 'SPK', name: 'Phụ kiện & Đồ chơi', icon: '🦴' },
//         { id: 'TA', name: 'Thức ăn', icon: '🥣' } 
//     ];

//     useEffect(() => {
//         const fetchProducts = async () => {
//             setLoading(true);
//             try {
//                 const res = await axios.get(`http://localhost:5000/api/orders/products`, { 
//                     params: { tuKhoa: search, loaiMH: type }
//                 });
//                 setProducts(res.data);
//             } catch (err) {
//                 console.error("Lỗi load sản phẩm:", err);
//             } finally {
//                 setLoading(false);
//             }
//         };
//         fetchProducts();
//     }, [search, type]);

//     const handleAddToCart = async (product) => {
//         // 1. Kiểm tra đăng nhập
//         const storedMaKH = localStorage.getItem('maKH');
        
//         if (!storedMaKH) {
//             // Nếu chưa đăng nhập -> Báo lỗi xong DỪNG LUÔN
//             alert("Bạn cần đăng nhập để mua hàng!"); 
//             return; 
//         }

//         // 2. Nếu đã đăng nhập thì mới chạy tiếp
//         try {
//             const currentMaPhieu = localStorage.getItem('activeOrder');
//             const res = await axios.post(`http://localhost:5000/api/cart/add`, {
//                 maKH: storedMaKH.trim(),
//                 maMH: product.MaMatHang,
//                 maPhieuHienTai: currentMaPhieu,
//                 diaChi: "Quận 1, Hồ Chí Minh", 
//                 maCN: "CN001",
//                 hinhThucTT: "Tiền mặt",
//                 soLuong: 1
//             });

//             if (res.data.success) {
//                 localStorage.setItem('activeOrder', res.data.maPhieu);
//                 setCartCount(prev => prev + 1);
//                 // Hiện thông báo thành công
//                 alert(`Đã thêm ${product.TenMatHang} vào giỏ!`); 
//             }
//         } catch (err) {
//             console.error(err);
//             alert("Lỗi: " + (err.response?.data?.message || err.message));
//         }
//     };

//     // Format tiền tệ
//     const formatCurrency = (val) => {
//         return Number(val).toLocaleString('vi-VN', { style: 'currency', currency: 'VND' });
//     };

//     return (
//         <div className="shop-wrapper">
            
//             {/* 1. Header Cửa hàng + Giỏ hàng */}
//             <header className="shop-header-bar" style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px'}}>
//                 <h2 style={{color: '#333', display: 'flex', alignItems: 'center', gap: '10px'}}>
//                     <ShoppingBag color="#e67e22" /> Cửa Hàng HappyPet
//                 </h2>
//                 <div className="cart-icon-container" style={{position: 'relative', cursor: 'pointer'}}>
//                     <ShoppingCart size={28} color="#e67e22" />
//                     {cartCount > 0 && <span className="cart-badge" style={{
//                         position: 'absolute', top: '-8px', right: '-8px', 
//                         background: '#e74c3c', color: 'white', borderRadius: '50%', 
//                         padding: '2px 6px', fontSize: '0.7rem', fontWeight: 'bold'
//                     }}>{cartCount}</span>}
//                 </div>
//             </header>

//             {/* 2. Banner Khuyến mãi */}
//             <div className="shop-banner">
//                 <div className="banner-content">
//                     <h1>Yêu Thương Pet - Sale 20%</h1>
//                     <p>Cho toàn bộ phụ kiện & đồ chơi tháng 12</p>
//                     <button className="banner-btn">Mua ngay</button>
//                 </div>
//                 <div className="banner-image">
//                     <img src="https://cdn-icons-png.flaticon.com/512/616/616408.png" alt="Pet" /> 
//                 </div>
//             </div>

//             {/* 3. Thanh Tìm kiếm */}
//             <div className="search-container">
//                 <div className="search-box">
//                     <Search size={20} color="#999" />
//                     <input 
//                         type="text" 
//                         placeholder="Tìm sản phẩm nhanh..." 
//                         value={search}
//                         onChange={(e) => setSearch(e.target.value)} 
//                     />
//                 </div>
//             </div>

//             {/* 4. Danh mục dạng Icon tròn */}
//             <div className="category-section">
//                 {categories.map(cat => (
//                     <div 
//                         key={cat.id} 
//                         className={`cat-item ${type === cat.id ? 'active' : ''}`}
//                         onClick={() => setType(cat.id)}
//                     >
//                         <div className="cat-icon">{cat.icon}</div>
//                         <span className="cat-name">{cat.name}</span>
//                     </div>
//                 ))}
//             </div>

//             {/* 5. Grid Sản phẩm */}
//             <h3 className="section-title">Sản phẩm nổi bật</h3>
//             {loading ? <p className="loading-spinner">Đang tải sản phẩm...</p> : (
//                 <div className="product-grid">
//                     {products.length > 0 ? products.map(p => (
//                         <div key={p.MaMatHang} className="product-card">
//                             <div className="card-img">
//                                 <img 
//                                     src={p.HinhAnh ? p.HinhAnh : `https://via.placeholder.com/300x300?text=${p.TenMatHang}`} 
//                                     alt={p.TenMatHang}
//                                     onError={(e) => { e.target.onerror = null; e.target.src = "https://via.placeholder.com/300x300?text=No+Image"; }} 
//                                 />
//                                 {p.TinhTrang === 'Hết hàng' && <span className="badge-out">Hết hàng</span>}
//                             </div>
                            
//                             <div className="card-body">
//                                 <span className="card-cate">{p.LoaiMH || 'Sản phẩm'}</span>
//                                 <h4 className="card-title" title={p.TenMatHang}>{p.TenMatHang}</h4>
//                                 <p style={{fontSize: '0.8rem', color: '#777', marginBottom: '10px'}}>{p.HangSX || 'Đang cập nhật'}</p>
                                
//                                 <div className="card-bottom">
//                                     <div className="card-price">{formatCurrency(p.DonGia)}</div>
//                                     <button 
//                                         className="btn-add-cart" 
//                                         disabled={p.TinhTrang === 'Hết hàng'}
//                                         onClick={() => handleAddToCart(p)}
//                                         title="Thêm vào giỏ"
//                                     >
//                                         <ShoppingCart size={18} />
//                                     </button>
//                                 </div>
//                             </div>
//                         </div>
//                     )) : <p className="no-result">Không tìm thấy sản phẩm nào! 😿</p>}
//                 </div>
//             )}
//         </div>
//     );
// };

// export default Shop;
