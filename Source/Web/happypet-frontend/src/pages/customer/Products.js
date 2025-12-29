import React, { useState, useEffect, useMemo, useRef } from 'react';
import { orderService } from '../../services/orderService';
import Swal from 'sweetalert2';
import './Products.css';

const Products = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  // Check if user is employee
  const userRole = localStorage.getItem('role');
  const isEmployee = userRole === 'Nhân viên Tiếp tân' || userRole === 'Nhân viên bán hàng' || userRole === 'NV' || userRole === 'ADMIN';

  // ====== DANH MỤC + PHÂN TRANG ======
  const CATEGORIES = [
    { key: '', label: 'Tất cả', icon: '🐾' },
    { key: 'TA', label: 'Thức ăn', icon: '🍲' },
    { key: 'SPK', label: 'Phụ kiện', icon: '🦴' },
    { key: 'T', label: 'Thuốc', icon: '💊' },
    { key: 'QA', label: 'Quần áo', icon: '👕' }
  ];

  const [selectedCategory, setSelectedCategory] = useState(''); // loaiMH
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 9;

  // ====== CHỌN CHI NHÁNH (Nội thành) ======
  const [branches, setBranches] = useState([]);
  const [selectedCity, setSelectedCity] = useState(((localStorage.getItem('shipCity') || '').trim()));
  const [selectedBranch, setSelectedBranch] = useState(((localStorage.getItem('shipBranch') || '').trim()));
  const [savedBranchLabel, setSavedBranchLabel] = useState(null);
  const attemptedFetchRef = useRef(false);

  const detectCityFromAddress = (addr = '') => {
    const cities = ['Hồ Chí Minh', 'Cần Thơ', 'Hà Nội', 'Đà Nẵng', 'Bình Dương'];
    return cities.find(c => addr.includes(c)) || '';
  };

  // // ====== ẢNH ======
  // const FALLBACK_IMG = 'https://via.placeholder.com/300x300?text=HappyPet';
  const FALLBACK_IMG = 'https://placehold.co/300x300?text=HappyPet';
  const REAL_IMG_LIMIT = 6;

  // 1) Load danh sách chi nhánh (1 lần)
  useEffect(() => {
    const loadBranches = async () => {
      try {
        const data = await orderService.getBranches();
        const arr = Array.isArray(data) ? data : [];
        setBranches(arr);

        if (!Array.isArray(data)) console.warn("API /branches không trả mảng. Check backend response.");
        if (arr.length === 0) console.warn("Không có chi nhánh nào trả về. Check route/SP/dữ liệu.");
      } catch (e) {
        console.error('Lỗi load chi nhánh FULL:', e?.response?.status, e?.response?.data, e?.message);
        Swal.fire('Lỗi', `Không tải được danh sách chi nhánh. ${e?.message || ''}`, 'error');
      }
    };
    loadBranches();
  }, []);

  // Reset trang khi đổi lọc
  useEffect(() => {
    setPage(1);
  }, [selectedBranch, selectedCategory, searchTerm]);

  // 2) Load sản phẩm khi đổi chi nhánh hoặc đổi danh mục (bạn vẫn có nút 🔍 để reload theo search)
  useEffect(() => {
    loadProducts();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedBranch, selectedCategory]);

  const loadProducts = async () => {
    setLoading(true);
    try {
      const data = await orderService.getProducts(searchTerm, selectedCategory, selectedBranch);
      setProducts(Array.isArray(data) ? data : []);
    } catch (err) {
      console.error('Lỗi load sản phẩm:', err);
    } finally {
      setLoading(false);
    }
  };

  // New helper: lấy phí ship từ object chi nhánh (nhiều tên trường khác nhau có thể tồn tại)
  const getBranchShippingFee = (b) => {
    if (!b) return 0;
    return Number(b.PhiGiaoHang ?? b.PhiShip ?? b.PhiVanChuyen ?? b.ShipFee ?? b.ShippingFee ?? b.Fee ?? 0) || 0;
  };

  const formatMoney = (v) => Number(v || 0).toLocaleString('vi-VN') + 'đ';

  // --- HÀM XỬ LÝ THÊM GIỎ HÀNG (ĐÃ SỬA ĐỂ CHẠY LOCAL STORAGE) ---
  const handleAddToCart = async (product) => {
    // --- 1. KIỂM TRA ĐĂNG NHẬP NGAY TỪ ĐẦU ---
    const token = localStorage.getItem('token');
    if (!token) {
      Swal.fire({
        icon: 'warning',
        title: 'Chưa đăng nhập',
        text: 'Bạn vui lòng đăng nhập để mua hàng nhé!',
        showCancelButton: true,
        confirmButtonText: 'Đăng nhập',
        cancelButtonText: 'Để sau'
      }).then((result) => {
        if (result.isConfirmed) {
          window.location.href = '/login'; // Chuyển hướng sang trang login
        }
      });
      return; // Dừng lại, không cho chạy tiếp
    }

    // --- 2. Các bước kiểm tra hàng hóa (Giữ nguyên) ---
    if (product.TinhTrang === 'Hết hàng') {
      Swal.fire('Thông báo', 'Sản phẩm này hiện đã hết hàng!', 'warning');
      return;
    }

    const city = (selectedCity || localStorage.getItem('shipCity') || '').trim();
    const branch = (selectedBranch || localStorage.getItem('shipBranch') || '').trim();

    if (!city || !branch) {
      Swal.fire('Thông báo', 'Vui lòng chọn thành phố và chi nhánh trước khi thêm vào giỏ.', 'warning');
      return;
    }

    const tonKho = product.SoLuongTon ?? null;
    if (branch && tonKho !== null && Number(tonKho) <= 0) {
      Swal.fire('Thông báo', 'Chi nhánh này hiện đã hết hàng sản phẩm này!', 'warning');
      return;
    }

    // --- 3. GỌI API THÊM VÀO GIỎ (Thay vì lưu LocalStorage như trước) ---
  // 1. Lấy mã hiện tại và "tắm rửa" sạch sẽ ngay lập tức
    let cleanCode = localStorage.getItem('currentOrderCode');
    if (cleanCode) {
        cleanCode = String(cleanCode).replace(/\+/g, '').trim();
    }

    // 2. Gửi mã sạch lên Server
    const payload = {
      maMH: product.MaMatHang,
      soLuong: 1,
      maCN: branch,
      diaChi: `Nội thành ${city}`,
      maPhieuHienTai: cleanCode // ✅ Gửi mã này thì Server mới nhận người quen
    };

    try {
      // 1. Gọi API và hứng kết quả trả về (trong đó có mã phiếu Pxxxx)
      const response = await orderService.addToCart(payload);

      // 2. 🔥 QUAN TRỌNG: Lưu ngay mã phiếu vào máy để dùng cho món tiếp theo
      if (response && response.maPhieu) {
        // Dọn sạch dấu ++ nếu có cho chắc ăn
        const cleanCode = String(response.maPhieu).replace(/\+/g, '').trim();
        localStorage.setItem('currentOrderCode', cleanCode);
        console.log("✅ Đã lưu mã phiếu vào máy:", cleanCode);
      }

      // 3. Thông báo thành công
      Swal.fire({
        icon: 'success',
        title: 'Thành công!',
        text: `${product.TenMatHang} đã được thêm vào giỏ hàng.`,
        showConfirmButton: false,
        timer: 1500
      });

    } catch (err) {
      console.error(err);
      Swal.fire('Lỗi', typeof err === 'string' ? err : 'Không thể thêm vào giỏ', 'error');
    }

  };

  // const renderStars = () => (
  //   <div className="card-rating">
  //     {'★★★★★'.split('').map((_, index) => (
  //       <span key={index} className="star" style={{ color: '#ffc107' }}>★</span>
  //     ))}
  //     <span className="rating-count">(12)</span>
  //   </div>
  // );

  // 🔥 HÀM VẼ SAO TỪ DB (Mới)
  const renderStars = (prod) => {
      // Lấy điểm từ DB (Nếu ko có thì mặc định 0). Bà nhớ check xem API trả về field tên gì nha (thường là DiemTB hoặc Rating)
      const rating = prod.DiemTrungBinh || 0; 
      const count = prod.SoLuongDanhGia || 0; 

      return (
          <div className="card-rating">
              {[1, 2, 3, 4, 5].map((star) => (
                  <span 
                      key={star} 
                      className="star" 
                      style={{ color: star <= Math.round(rating) ? '#ffc107' : '#e4e5e9', fontSize: '18px' }}
                  >
                      ★
                  </span>
              ))}
              <span className="rating-count" style={{fontSize: '12px', color: '#666', marginLeft: '5px'}}>
                  ({count} đánh giá)
              </span>
          </div>
      );
  };
  const renderPrice = (donGia) => {
    if (typeof donGia === 'number') return `${donGia.toLocaleString('vi-VN')}đ`;
    if (typeof donGia === 'string' && donGia.trim()) return donGia;
    return '0đ';
  };

  // ====== city/branch helpers ======
  const getBranchId = (b) => b.MaCN || b.MaChiNhanh || b.branchId || b.id;
  const getBranchAddress = (b) => b.DiaChi || b.DiaChiCN || b.Address || b.address || '';

  const cityOptions = useMemo(() => {
    return Array.from(
      new Set(branches.map(b => detectCityFromAddress(getBranchAddress(b))).filter(Boolean))
    );
  }, [branches]);

  const branchesInCity = useMemo(() => {
    return branches.filter(b => detectCityFromAddress(getBranchAddress(b)) === selectedCity);
  }, [branches, selectedCity]);

  // Nếu có branch đang lưu trong localStorage nhưng không có trong danh sách lọc, cố gắng đồng bộ city tự động
  useEffect(() => {
    if (!selectedBranch) return;
    const found = branches.find(b => getBranchId(b) === selectedBranch);
    if (found) {
      const city = detectCityFromAddress(getBranchAddress(found));
      if (city && city !== selectedCity) {
        setSelectedCity(city);
        localStorage.setItem('shipCity', city);
      }
    }
  }, [branches, selectedBranch]);

  const selectedBranchObj = selectedBranch ? branches.find(b => getBranchId(b) === selectedBranch) : null;

  // Nếu chưa có object chi nhánh tương ứng trong memory, thử fetch lại danh sách để lấy địa chỉ
  useEffect(() => {
    let mounted = true;

    const resolveSavedBranch = async () => {
      if (!selectedBranch) {
        if (mounted) setSavedBranchLabel(null);
        return;
      }

      // nếu đã có object thì set label ngay
      const found = branches.find(b => String(getBranchId(b)).trim() === String(selectedBranch).trim());
      if (found) {
        if (mounted) setSavedBranchLabel(`${getBranchId(found)} - ${getBranchAddress(found)}`);
        return;
      }

      // tránh fetch liên tục nếu đã thử trước đó
      if (attemptedFetchRef.current) {
        // nếu selectedBranch chứa dấu ' - ' có thể đã lưu cả địa chỉ, dùng trực tiếp
        if (selectedBranch.includes(' - ')) {
          if (mounted) setSavedBranchLabel(selectedBranch);
        } else {
          if (mounted) setSavedBranchLabel(selectedBranch);
        }
        return;
      }

      attemptedFetchRef.current = true;
      try {
        const data = await orderService.getBranches();
        const arr = Array.isArray(data) ? data : [];
        if (arr.length > 0) setBranches(arr);
        const f = arr.find(b => String(getBranchId(b)).trim() === String(selectedBranch).trim());
        if (f) {
          if (mounted) setSavedBranchLabel(`${getBranchId(f)} - ${getBranchAddress(f)}`);
          return;
        }

        // fallback: if selectedBranch looks like 'id - address' show it, otherwise show id only
        if (selectedBranch.includes(' - ')) {
          if (mounted) setSavedBranchLabel(selectedBranch);
        } else {
          if (mounted) setSavedBranchLabel(selectedBranch);
        }
      } catch (e) {
        if (mounted) setSavedBranchLabel(selectedBranch);
      }
    };

    resolveSavedBranch();

    return () => { mounted = false; };
  }, [selectedBranch, branches]);

  const handleChooseCity = (val) => {
    const v = (val || '').trim(); // ✅ FIX: trim để khỏi dính khoảng trắng
    setSelectedCity(v);
    setSelectedBranch('');
    localStorage.setItem('shipCity', v);
    localStorage.removeItem('shipBranch');
  };

  const handleChooseBranch = (val) => {
    const v = (val || '').trim(); // ✅ FIX: trim để khỏi dính khoảng trắng
    setSelectedBranch(v);
    localStorage.setItem('shipBranch', v);
  };

  const handleClearBranch = () => {
    setSelectedCity('');
    setSelectedBranch('');
    localStorage.removeItem('shipCity');
    localStorage.removeItem('shipBranch');
  };

  // ====== PHÂN TRANG (FE) ======
  const totalItems = products.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);

  const start = (safePage - 1) * PAGE_SIZE;
  const end = start + PAGE_SIZE;
  const pagedProducts = products.slice(start, end);

  const goToPage = (p) => {
    if (p < 1 || p > totalPages) return;
    setPage(p);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  // pages hiển thị kiểu 1 2 3 4 5 ... last
  const pageButtons = useMemo(() => {
    if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1);

    const set = new Set([1, 2, safePage - 1, safePage, safePage + 1, totalPages - 1, totalPages]);
    const arr = Array.from(set).filter(p => p >= 1 && p <= totalPages).sort((a, b) => a - b);
    return arr;
  }, [totalPages, safePage]);

  return (
    <div className="products-page-wrapper">
      {/* --- BANNER --- */}
      <div className="banner-section">
        <div className="banner-content">
          <h1>Thiên Đường Thú Cưng</h1>
          <p>Chăm sóc toàn diện - Yêu thương đong đầy</p>
          <button className="shop-now-btn">Khám phá ngay</button>
        </div>
      </div>

      {/* --- DANH MỤC NHANH (lọc LoaiMH) --- */}
      <div className="category-quick-nav">
        {CATEGORIES.map(cat => (
          <div
            key={cat.key}
            className={`cat-item ${selectedCategory === cat.key ? 'active' : ''}`}
            onClick={() => setSelectedCategory(cat.key)}
            style={{ cursor: 'pointer' }}
            title={cat.label}
          >
            <div className="cat-circle">{cat.icon}</div>
            <span>{cat.label}</span>
          </div>
        ))}
      </div>

      {/* --- CONTAINER CHÍNH --- */}
      <div className="shop-container">
        {/* SIDEBAR */}
        <div className="shop-sidebar">
          <div className="filter-group">
            <h3>Lọc theo loại</h3>
            <ul>
              <li><label><input type="checkbox" /> Chó</label></li>
              <li><label><input type="checkbox" /> Mèo</label></li>
              <li><label><input type="checkbox" /> Hamster</label></li>
            </ul>
          </div>
          <div className="filter-group">
            <h3>Khoảng giá</h3>
            <input type="range" min="0" max="1000000" className="price-range" />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem', marginTop: '5px' }}>
              <span>0đ</span>
              <span>1.000.000đ</span>
            </div>
          </div>
        </div>

        {/* CONTENT */}
        <div className="shop-content">
          <div className="shop-header">
            <h2>SẢN PHẨM MỚI NHẤT</h2>
            <div className="search-bar-mini">
              <input
                type="text"
                placeholder="Tìm kiếm..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              <button onClick={loadProducts}>🔍</button>
            </div>
          </div>

          {/* ====== CHỌN CHI NHÁNH ====== */}
          <div style={{
            background: '#fff3cd',
            border: '1px solid #ffeeba',
            padding: '12px 14px',
            borderRadius: '10px',
            margin: '12px 0 16px 0'
          }}>
            <b>⚠️ Trung tâm chỉ cho phép giao nội thành.</b>
            <div style={{ marginTop: 6 }}>
              Vui lòng chọn <b>thành phố</b> và <b>chi nhánh</b> phù hợp với địa chỉ của bạn.
            </div>

            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginTop: 10 }}>
              <select value={selectedCity} onChange={(e) => handleChooseCity(e.target.value)}>
                <option value="">-- Chọn thành phố --</option>
                {cityOptions.map(c => <option key={c} value={c}>{c}</option>)}
              </select>

              <select
                value={selectedBranch}
                onChange={(e) => handleChooseBranch(e.target.value)}
                disabled={!selectedCity}
              >
                <option value="">-- Chọn chi nhánh --</option>
                {branchesInCity.map(b => (
                  <option key={getBranchId(b)} value={getBranchId(b)}>
                    {getBranchId(b)} - {getBranchAddress(b)}
                  </option>
                ))}
                {selectedBranch && !branchesInCity.some(b => getBranchId(b) === selectedBranch) && (
                  <option value={selectedBranch}>
                    {selectedBranchObj ? `${getBranchId(selectedBranchObj)} - ${getBranchAddress(selectedBranchObj)}` : (savedBranchLabel || selectedBranch)}
                  </option>
                )}
              </select>

              {(selectedCity || selectedBranch) && (
                <button onClick={handleClearBranch} style={{ cursor: 'pointer' }}>
                  Xóa chọn
                </button>
              )}
            </div>

            {/* Hiển thị phí ship nếu có chi nhánh chọn */}
            {selectedBranchObj && (
              <div style={{ marginTop: 8, fontSize: '0.95rem' }}>
                <b>Phí ship nội thành:</b> <span style={{ color: '#d35400' }}>{formatMoney(getBranchShippingFee(selectedBranchObj))}</span>
                <div style={{ fontSize: '0.85rem', color: '#555' }}>Phí ship có thể thay đổi theo quy định kho / đơn vị vận chuyển.</div>
              </div>
            )}

            <div style={{ marginTop: 8, fontSize: '0.9rem', opacity: 0.85 }}>
              {selectedBranch
                ? `Đang lọc theo chi nhánh: ${selectedBranch}`
                : 'Chưa chọn chi nhánh: đang hiển thị toàn bộ sản phẩm.'}
            </div>
          </div>

          {loading ? (
            <p>Đang tải sản phẩm...</p>
          ) : (
            <>
              <div className="product-grid-new">
                {pagedProducts.map((prod, idx) => {
                  const globalIndex = start + idx; // để ảnh thật vẫn theo “thứ tự toàn list”
                  const showRealImage = globalIndex < REAL_IMG_LIMIT;
                  const imgSrc = (showRealImage && prod.HinhAnh) ? prod.HinhAnh : FALLBACK_IMG;

                  const tonKho = prod.SoLuongTon ?? null;
                  const outByBranch = selectedBranch && tonKho !== null && Number(tonKho) <= 0;

                  return (
                    <div key={prod.MaMatHang} className="product-card-new">
                      <div className="card-img-wrapper">
                        <img
                          src={imgSrc}
                          alt={prod.TenMatHang}
                          onError={(e) => { e.target.onerror = null; e.target.src = FALLBACK_IMG; }}
                        />
                        {(prod.TinhTrang === 'Hết hàng' || outByBranch) && (
                          <span className="badge badge-out">Hết hàng</span>
                        )}
                      </div>

                      <div className="card-body">
                        <p className="card-category">{prod.HangSX}</p>
                        <h3 className="card-title" title={prod.TenMatHang}>{prod.TenMatHang}</h3>
                        {renderStars(prod)}

                        {/* ✅ Chỉ hiện tồn kho khi backend có trả SoLuongTon */}
                        {selectedBranch && prod.SoLuongTon !== undefined && prod.SoLuongTon !== null && (
                          <p
                            style={{
                              fontSize: '0.85rem',
                              margin: '6px 0',
                              color: Number(prod.SoLuongTon) > 0 ? '#2e7d32' : '#c62828'
                            }}
                          >
                            Số lượng còn lại: {prod.SoLuongTon}
                          </p>
                        )}

                        <div className="card-bottom">
                          <p className="card-price">{renderPrice(prod.DonGia)}</p>
                          <button
                            className="btn-add-cart-mini"
                            onClick={() => handleAddToCart(prod)}
                            disabled={prod.TinhTrang === 'Hết hàng' || outByBranch || isEmployee}
                            title={isEmployee ? 'Nhân viên không thể thêm vào giỏ' : 'Thêm vào giỏ'}
                            style={isEmployee ? {opacity: 0.3, cursor: 'not-allowed'} : {}}
                          >
                            +
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}

                {pagedProducts.length === 0 && (
                  <p style={{ padding: 12 }}>Không có sản phẩm phù hợp.</p>
                )}
              </div>

              {/* ====== PHÂN TRANG ====== */}
              <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                gap: 10,
                margin: '22px 0'
              }}>
                <button
                  onClick={() => goToPage(safePage - 1)}
                  disabled={safePage === 1}
                  style={{ border: 'none', background: 'transparent', fontSize: 20, cursor: 'pointer' }}
                  title="Trang trước"
                >
                  ‹
                </button>

                {pageButtons.map((p, idxBtn) => {
                  const prev = pageButtons[idxBtn - 1];
                  const showDots = prev && p - prev > 1;

                  return (
                    <React.Fragment key={p}>
                      {showDots && <span style={{ padding: '0 6px' }}>…</span>}
                      <button
                        onClick={() => goToPage(p)}
                        style={{
                          width: 38,
                          height: 38,
                          borderRadius: 6,
                          border: '1px solid #eee',
                          cursor: 'pointer',
                          background: p === safePage ? '#e74c3c' : '#fff',
                          color: p === safePage ? '#fff' : '#333',
                          fontWeight: p === safePage ? 700 : 500
                        }}
                      >
                        {p}
                      </button>
                    </React.Fragment>
                  );
                })}

                <button
                  onClick={() => goToPage(safePage + 1)}
                  disabled={safePage === totalPages}
                  style={{ border: 'none', background: 'transparent', fontSize: 20, cursor: 'pointer' }}
                  title="Trang sau"
                >
                  ›
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  
  );
};

export default Products;