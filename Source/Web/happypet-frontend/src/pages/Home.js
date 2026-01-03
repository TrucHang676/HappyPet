
// // // // // // // // src/pages/Home.js
// // // // // // // import React from 'react';
// // // // // // // import { useNavigate } from 'react-router-dom';

// // // // // // // const Home = () => {
// // // // // // //     const navigate = useNavigate(); 

// // // // // // //     // --- HÀM XỬ LÝ CLICK ĐẶT LỊCH (MỚI THÊM) ---
// // // // // // //     const handleBookingClick = () => {
// // // // // // //         const token = localStorage.getItem('token'); // Lấy token từ bộ nhớ
        
// // // // // // //         if (token) {
// // // // // // //             // Trường hợp 1: Đã có token (Đã đăng nhập) -> Cho qua đặt lịch
// // // // // // //             navigate('/booking');
// // // // // // //         } else {
// // // // // // //             // Trường hợp 2: Chưa có token (Khách vãng lai) -> Bắt đăng nhập
// // // // // // //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// // // // // // //             navigate('/login');
// // // // // // //         }
// // // // // // //     };

// // // // // // //     return (
// // // // // // //         <div style={{ textAlign: 'center', padding: '50px' }}>
// // // // // // //             {/* 1. TIÊU ĐỀ & MÔ TẢ (GIỮ NGUYÊN) */}
// // // // // // //             <h1 style={{ color: '#8B4513', marginBottom: '15px' }}>
// // // // // // //                 Chào mừng đến với HappyPet! 🐶🐱
// // // // // // //             </h1>
// // // // // // //             <p style={{ fontSize: '18px', color: '#555', marginBottom: '30px' }}>
// // // // // // //                 Nơi cung cấp các dịch vụ spa và chăm sóc thú cưng tốt nhất cho Boss của bạn.
// // // // // // //             </p>
            
// // // // // // //             {/* 2. NÚT ĐẶT LỊCH (SỬA ONCLICK) */}
// // // // // // //             <button 
// // // // // // //                 onClick={handleBookingClick} // <--- Thay đổi dòng này (Gọi hàm kiểm tra)
// // // // // // //                 style={{
// // // // // // //                     padding: '15px 30px',
// // // // // // //                     fontSize: '18px',
// // // // // // //                     backgroundColor: '#ff6f00',
// // // // // // //                     color: 'white',
// // // // // // //                     border: 'none',
// // // // // // //                     borderRadius: '30px',
// // // // // // //                     cursor: 'pointer',
// // // // // // //                     marginBottom: '40px', 
// // // // // // //                     boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
// // // // // // //                     transition: '0.3s'
// // // // // // //                 }}
// // // // // // //                 onMouseOver={(e) => e.target.style.backgroundColor = '#e65100'} 
// // // // // // //                 onMouseOut={(e) => e.target.style.backgroundColor = '#ff6f00'}
// // // // // // //             >
// // // // // // //                 📅 ĐẶT LỊCH NGAY
// // // // // // //             </button>

// // // // // // //             {/* 3. HÌNH ẢNH (GIỮ NGUYÊN) */}
// // // // // // //             <div style={{ display: 'block' }}>
// // // // // // //                 <img 
// // // // // // //                     src="https://img.freepik.com/free-vector/cute-pets-illustration_53876-112522.jpg" 
// // // // // // //                     alt="Happy Pets" 
// // // // // // //                     style={{ 
// // // // // // //                         maxWidth: '80%', 
// // // // // // //                         height: 'auto', 
// // // // // // //                         borderRadius: '15px',
// // // // // // //                         boxShadow: '0 5px 15px rgba(0,0,0,0.1)'
// // // // // // //                     }}
// // // // // // //                 />
// // // // // // //             </div>
// // // // // // //         </div>
// // // // // // //     );
// // // // // // // };

// // // // // // // export default Home;

// // // // // // // import React from 'react';
// // // // // // // import { useNavigate } from 'react-router-dom';
// // // // // // // import './Home.css';

// // // // // // // const Home = () => {
// // // // // // //     const navigate = useNavigate(); 

// // // // // // //     const handleBookingClick = () => {
// // // // // // //         const token = localStorage.getItem('token');
// // // // // // //         if (token) {
// // // // // // //             navigate('/booking');
// // // // // // //         } else {
// // // // // // //             // Có thể thay bằng Modal hoặc Toast đẹp hơn sau này
// // // // // // //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// // // // // // //             navigate('/login');
// // // // // // //         }
// // // // // // //     };

// // // // // // //     return (
// // // // // // //         <div className="home-container">
// // // // // // //             {/* 1. HERO SECTION */}
// // // // // // //             <div className="hero-wrapper">
// // // // // // //                 <img className="hero-deco-img deco-left" src="https://cdn-icons-png.flaticon.com/512/616/616408.png" alt="Cat" />
// // // // // // //                 <img className="hero-deco-img deco-right" src="https://cdn-icons-png.flaticon.com/512/616/616554.png" alt="Dog" />

// // // // // // //                 <div className="hero-content">
// // // // // // //                     <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
// // // // // // //                     <h1 className="hero-title">HappyPet Care</h1>
// // // // // // //                     <p className="hero-subtitle">
// // // // // // //                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
// // // // // // //                     </p>
// // // // // // //                     {/* Nút đặt lịch đã được sửa CSS */}
// // // // // // //                     <button className="cta-button" onClick={handleBookingClick}>
// // // // // // //                         <span>ĐẶT LỊCH NGAY</span>
// // // // // // //                         <span style={{fontSize: '1.2rem'}}>📅</span>
// // // // // // //                     </button>
// // // // // // //                 </div>
// // // // // // //             </div>

// // // // // // //             {/* 2. FLOATING CARDS: 3 Dịch vụ chính */}
// // // // // // //             <div className="floating-services">
// // // // // // //                 {/* Dịch vụ 1: Khám bệnh */}
// // // // // // //                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
// // // // // // //                     <div className="icon-box">🩺</div>
// // // // // // //                     <h3>Khám bệnh</h3>
// // // // // // //                 </div>
                
// // // // // // //                 {/* Dịch vụ 2: Tiêm vaccine */}
// // // // // // //                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
// // // // // // //                     <div className="icon-box">💉</div>
// // // // // // //                     <h3>Tiêm vaccine</h3>
// // // // // // //                 </div>
                
// // // // // // //                 {/* Dịch vụ 3: Cửa hàng */}
// // // // // // //                 <div className="service-card" onClick={() => navigate('/shop')}>
// // // // // // //                     <div className="icon-box">🛍️</div>
// // // // // // //                     <h3>Cửa hàng</h3>
// // // // // // //                 </div>
// // // // // // //             </div>

// // // // // // //             {/* 3. PROMO SECTION */}
// // // // // // //             <div className="promo-section">
// // // // // // //                 {/* Đã đổi tiêu đề theo yêu cầu */}
// // // // // // //                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
// // // // // // //                 <div className="promo-grid">
// // // // // // //                     <div className="promo-item">
// // // // // // //                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
// // // // // // //                         <div className="promo-overlay">
// // // // // // //                             <h3>Gói khám sức khỏe tổng quát</h3>
// // // // // // //                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
// // // // // // //                         </div>
// // // // // // //                     </div>
// // // // // // //                     <div className="promo-item">
// // // // // // //                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
// // // // // // //                         <div className="promo-overlay">
// // // // // // //                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
// // // // // // //                             <p>Chờ đón vào tháng sau!</p>
// // // // // // //                         </div>
// // // // // // //                     </div>
// // // // // // //                     <div className="promo-item">
// // // // // // //                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
// // // // // // //                         <div className="promo-overlay">
// // // // // // //                             <h3>Ngày hội tiêm chủng</h3>
// // // // // // //                             <p>Miễn phí tư vấn</p>
// // // // // // //                         </div>
// // // // // // //                     </div>
// // // // // // //                 </div>
// // // // // // //             </div>
// // // // // // //         </div>
// // // // // // //     );
// // // // // // // };

// // // // // export default Home;

// // // // // import React from 'react';
// // // // // import { useNavigate } from 'react-router-dom';
// // // // // import './Home.css';

// // // // // const Home = () => {
// // // // //     const navigate = useNavigate(); 

// // // // //     const handleBookingClick = () => {
// // // // //         const token = localStorage.getItem('token');
// // // // //         if (token) {
// // // // //             navigate('/booking');
// // // // //         } else {
// // // // //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// // // // //             navigate('/login');
// // // // //         }
// // // // //     };

// // // // //     return (
// // // // //         <div className="home-container">
// // // // //             {/* 1. HERO SECTION */}
// // // // //             <div className="hero-wrapper">
// // // // //                 {/* --- BIỆT ĐỘI THÚ CƯNG (ĐÃ ĐỔI CON BÒ SỮA THÀNH CORGI) --- */}
                
// // // // //                 {/* 1. Chó Corgi (Bên trái) */}
// // // // //                 <img 
// // // // //                     className="hero-deco-img deco-dog-left" 
// // // // //                     src="https://cdn-icons-png.flaticon.com/512/1864/1864514.png" 
// // // // //                     alt="Corgi" 
// // // // //                     style={{height: '140px', left: '2%'}} // Chỉnh lại xíu cho Corgi nó vừa vặn
// // // // //                 />
                
// // // // //                 {/* 2. Mèo (Ngồi cạnh Corgi) */}
// // // // //                 <img 
// // // // //                     className="hero-deco-img deco-cat" 
// // // // //                     src="https://cdn-icons-png.flaticon.com/512/616/616408.png" 
// // // // //                     alt="Cat" 
// // // // //                 />
                
// // // // //                 {/* 3. Hamster (Bên phải, đang ăn hạt) */}
// // // // //                 <img 
// // // // //                     className="hero-deco-img deco-hamster" 
// // // // //                     src="https://cdn-icons-png.flaticon.com/512/235/235359.png" 
// // // // //                     alt="Hamster" 
// // // // //                 />
                
// // // // //                 {/* 4. Chim Vẹt (Bay trên cao bên phải) */}
// // // // //                 <img 
// // // // //                     className="hero-deco-img deco-bird" 
// // // // //                     src="https://cdn-icons-png.flaticon.com/512/814/814561.png" 
// // // // //                     alt="Bird" 
// // // // //                 />
                
// // // // //                 {/* 5. Chó Bull Pháp (Bên phải ngoài cùng - Thay cho con chó đốm/bò sữa cũ) */}
// // // // //                 <img 
// // // // //                     className="hero-deco-img deco-dog-right" 
// // // // //                     src="https://cdn-icons-png.flaticon.com/512/2395/2395796.png" 
// // // // //                     style={{display: 'none'}} /* Ẩn con cũ đi cho chắc */
// // // // //                     alt="Hidden" 
// // // // //                 />
// // // // //                 <img 
// // // // //                     className="hero-deco-img deco-dog-right" 
// // // // //                     src="https://cdn-icons-png.flaticon.com/512/2829/2829817.png" 
// // // // //                     alt="Bulldog"
// // // // //                     style={{height: '130px', right: '5%'}} 
// // // // //                 />
// // // // //                 {/* --------------------------- */}

// // // // //                 <div className="hero-content">
// // // // //                     <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
// // // // //                     <h1 className="hero-title">HappyPet Care</h1>
// // // // //                     <p className="hero-subtitle">
// // // // //                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
// // // // //                     </p>
// // // // //                     <button className="cta-button" onClick={handleBookingClick}>
// // // // //                         <span>ĐẶT LỊCH NGAY</span>
// // // // //                         <span style={{fontSize: '1.2rem'}}>📅</span>
// // // // //                     </button>
// // // // //                 </div>
// // // // //             </div>

// // // // //             {/* 2. FLOATING CARDS: 3 Dịch vụ chính */}
// // // // //             <div className="floating-services">
// // // // //                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
// // // // //                     <div className="icon-box">🩺</div>
// // // // //                     <h3>Khám bệnh</h3>
// // // // //                 </div>
                
// // // // //                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
// // // // //                     <div className="icon-box">💉</div>
// // // // //                     <h3>Tiêm vaccine</h3>
// // // // //                 </div>
                
// // // // //                 <div className="service-card" onClick={() => navigate('/products')}>
// // // // //                     <div className="icon-box">🛍️</div>
// // // // //                     <h3>Cửa hàng</h3>
// // // // //                 </div>
// // // // //             </div>

// // // // //             {/* 3. PROMO SECTION */}
// // // // //             <div className="promo-section">
// // // // //                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
// // // // //                 <div className="promo-grid">
// // // // //                     <div className="promo-item">
// // // // //                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
// // // // //                         <div className="promo-overlay">
// // // // //                             <h3>Gói khám sức khỏe tổng quát</h3>
// // // // //                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
// // // // //                         </div>
// // // // //                     </div>
// // // // //                     <div className="promo-item">
// // // // //                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
// // // // //                         <div className="promo-overlay">
// // // // //                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
// // // // //                             <p>Chờ đón vào tháng sau!</p>
// // // // //                         </div>
// // // // //                     </div>
// // // // //                     <div className="promo-item">
// // // // //                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
// // // // //                         <div className="promo-overlay">
// // // // //                             <h3>Ngày hội tiêm chủng</h3>
// // // // //                             <p>Miễn phí tư vấn</p>
// // // // //                         </div>
// // // // //                     </div>
// // // // //                 </div>
// // // // //             </div>
// // // // //         </div>
// // // // //     );
// // // // // };

// // // // // export default Home;


// // // // // import React from 'react';
// // // // // import { useNavigate } from 'react-router-dom';
// // // // // import './Home.css';

// // // // // const Home = () => {
// // // // //     const navigate = useNavigate(); 

// // // // //     // --- LOGIC GIỮ NGUYÊN KHÔNG ĐỤNG ---
// // // // //     const handleBookingClick = () => {
// // // // //         const token = localStorage.getItem('token');
// // // // //         if (token) {
// // // // //             navigate('/booking');
// // // // //         } else {
// // // // //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// // // // //             navigate('/login');
// // // // //         }
// // // // //     };

// // // // //     return (
// // // // //         <div className="home-container">
// // // // //             {/* 1. HERO SECTION - Đã sửa nền thành ảnh Chó Mèo Hamster */}
// // // // //             <div className="hero-wrapper" style={{
// // // // //                 // Link ảnh nền mới: Hội tụ đủ các boss
// // // // //                 backgroundImage: "url('https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg?w=1380&t=st=1709220000~exp=1709220600~hmac=xyz')", 
// // // // //                 backgroundSize: 'cover',
// // // // //                 backgroundPosition: 'center',
// // // // //                 backgroundRepeat: 'no-repeat',
// // // // //                 position: 'relative', // Để căn chỉnh lớp phủ đen mờ
// // // // //                 borderRadius: '20px', // Bo góc cho đẹp giống cũ
// // // // //                 overflow: 'hidden'
// // // // //             }}>
// // // // //                 {/* Lớp phủ màu đen mờ (Overlay) để chữ màu trắng nổi lên rõ hơn */}
// // // // //                 <div style={{
// // // // //                     position: 'absolute',
// // // // //                     top: 0, left: 0, right: 0, bottom: 0,
// // // // //                     backgroundColor: 'rgba(0, 0, 0, 0.4)', // Màu đen mờ 40%
// // // // //                     zIndex: 1
// // // // //                 }}></div>

// // // // //                 {/* --- Đã XÓA mấy cái icon hoạt hình (deco-img) cũ để nhìn ảnh nền cho rõ --- */}

// // // // //                 <div className="hero-content" style={{position: 'relative', zIndex: 2}}>
// // // // //                     <span className="hero-badge" style={{backgroundColor: 'rgba(255, 255, 255, 0.2)', backdropFilter: 'blur(5px)', border: '1px solid rgba(255,255,255,0.5)', color: '#fff'}}>
// // // // //                         ✨ Dịch vụ thú cưng số #1
// // // // //                     </span>
                    
// // // // //                     {/* Chữ đổi sang màu trắng + bóng đổ cho dễ đọc trên nền ảnh */}
// // // // //                     <h1 className="hero-title" style={{color: '#ffffff', textShadow: '2px 2px 8px rgba(0,0,0,0.6)'}}>
// // // // //                         HappyPet Care
// // // // //                     </h1>
                    
// // // // //                     <p className="hero-subtitle" style={{color: '#f0f0f0', textShadow: '1px 1px 4px rgba(0,0,0,0.6)', fontWeight: '500'}}>
// // // // //                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn từ A-Z.
// // // // //                     </p>
                    
// // // // //                     <button className="cta-button" onClick={handleBookingClick}>
// // // // //                         <span>ĐẶT LỊCH NGAY</span>
// // // // //                         <span style={{fontSize: '1.2rem'}}>📅</span>
// // // // //                     </button>
// // // // //                 </div>
// // // // //             </div>

// // // // //             {/* 2. FLOATING CARDS: GIỮ NGUYÊN */}
// // // // //             <div className="floating-services">
// // // // //                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
// // // // //                     <div className="icon-box">🩺</div>
// // // // //                     <h3>Khám bệnh</h3>
// // // // //                 </div>
                
// // // // //                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
// // // // //                     <div className="icon-box">💉</div>
// // // // //                     <h3>Tiêm vaccine</h3>
// // // // //                 </div>
                
// // // // //                 <div className="service-card" onClick={() => navigate('/products')}>
// // // // //                     <div className="icon-box">🛍️</div>
// // // // //                     <h3>Cửa hàng</h3>
// // // // //                 </div>
// // // // //             </div>

// // // // //             {/* 3. PROMO SECTION: GIỮ NGUYÊN */}
// // // // //             <div className="promo-section">
// // // // //                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
// // // // //                 <div className="promo-grid">
// // // // //                     <div className="promo-item">
// // // // //                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
// // // // //                         <div className="promo-overlay">
// // // // //                             <h3>Gói khám sức khỏe tổng quát</h3>
// // // // //                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
// // // // //                         </div>
// // // // //                     </div>
// // // // //                     <div className="promo-item">
// // // // //                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
// // // // //                         <div className="promo-overlay">
// // // // //                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
// // // // //                             <p>Chờ đón vào tháng sau!</p>
// // // // //                         </div>
// // // // //                     </div>
// // // // //                     <div className="promo-item">
// // // // //                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
// // // // //                         <div className="promo-overlay">
// // // // //                             <h3>Ngày hội tiêm chủng</h3>
// // // // //                             <p>Miễn phí tư vấn</p>
// // // // //                         </div>
// // // // //                     </div>
// // // // //                 </div>
// // // // //             </div>
// // // // //         </div>
// // // // //     );
// // // // // };

// // // // // export default Home;

// // // // import React from 'react';
// // // // import { useNavigate } from 'react-router-dom';
// // // // import './Home.css';

// // // // const Home = () => {
// // // //     const navigate = useNavigate(); 

// // // //     const handleBookingClick = () => {
// // // //         const token = localStorage.getItem('token');
// // // //         if (token) {
// // // //             navigate('/booking');
// // // //         } else {
// // // //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// // // //             navigate('/login');
// // // //         }
// // // //     };

// // // //     return (
// // // //         <div className="home-container">
// // // //             {/* 1. HERO SECTION */}
// // // //             <div className="hero-wrapper">
// // // //                 {/* --- HÌNH TRANG TRÍ CHÓ MÈO ĐÁNG YÊU --- */}
                
// // // //                 {/* Chó Corgi (Góc trái dưới) */}
// // // //                 <img 
// // // //                     className="hero-deco-img deco-dog-left" 
// // // //                     src="https://cdn-icons-png.flaticon.com/512/1864/1864514.png" 
// // // //                     alt="Corgi" 
// // // //                     style={{
// // // //                         position: 'absolute',
// // // //                         height: '140px', 
// // // //                         bottom: '20px',
// // // //                         left: '5%',
// // // //                         zIndex: 1
// // // //                     }} 
// // // //                 />
                
// // // //                 {/* Mèo (Góc trái trên) */}
// // // //                 <img 
// // // //                     className="hero-deco-img deco-cat" 
// // // //                     src="https://cdn-icons-png.flaticon.com/512/616/616408.png" 
// // // //                     alt="Cat" 
// // // //                     style={{
// // // //                         position: 'absolute',
// // // //                         height: '100px',
// // // //                         top: '15%',
// // // //                         left: '10%',
// // // //                         zIndex: 1,
// // // //                         transform: 'rotate(-15deg)'
// // // //                     }}
// // // //                 />
                
// // // //                 {/* Hamster (Góc phải dưới) */}
// // // //                 <img 
// // // //                     className="hero-deco-img deco-hamster" 
// // // //                     src="https://cdn-icons-png.flaticon.com/512/235/235359.png" 
// // // //                     alt="Hamster" 
// // // //                     style={{
// // // //                         position: 'absolute',
// // // //                         height: '90px',
// // // //                         bottom: '30px',
// // // //                         right: '18%',
// // // //                         zIndex: 1
// // // //                     }}
// // // //                 />
                
// // // //                 {/* Chim Vẹt (Góc phải trên) */}
// // // //                 <img 
// // // //                     className="hero-deco-img deco-bird" 
// // // //                     src="https://cdn-icons-png.flaticon.com/512/814/814561.png" 
// // // //                     alt="Bird" 
// // // //                     style={{
// // // //                         position: 'absolute',
// // // //                         height: '80px',
// // // //                         top: '10%',
// // // //                         right: '8%',
// // // //                         zIndex: 1,
// // // //                         transform: 'rotate(15deg)'
// // // //                     }}
// // // //                 />
                
// // // //                 {/* Chó Bull Pháp (Góc phải giữa) */}
// // // //                 <img 
// // // //                     className="hero-deco-img deco-dog-right" 
// // // //                     src="https://cdn-icons-png.flaticon.com/512/2829/2829817.png" 
// // // //                     alt="Bulldog"
// // // //                     style={{
// // // //                         position: 'absolute',
// // // //                         height: '130px', 
// // // //                         bottom: '20px',
// // // //                         right: '5%',
// // // //                         zIndex: 1
// // // //                     }} 
// // // //                 />
// // // //                 {/* --------------------------- */}

// // // //                 <div className="hero-content" style={{position: 'relative', zIndex: 2}}>
// // // //                     <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
// // // //                     <h1 className="hero-title">HappyPet Care</h1>
// // // //                     <p className="hero-subtitle">
// // // //                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
// // // //                     </p>
// // // //                     <button className="cta-button" onClick={handleBookingClick}>
// // // //                         <span>ĐẶT LỊCH NGAY</span>
// // // //                         <span style={{fontSize: '1.2rem', marginLeft: '8px'}}>📅</span>
// // // //                     </button>
// // // //                 </div>
// // // //             </div>

// // // //             {/* 2. FLOATING CARDS: 3 Dịch vụ chính */}
// // // //             <div className="floating-services">
// // // //                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
// // // //                     <div className="icon-box">🩺</div>
// // // //                     <h3>Khám bệnh</h3>
// // // //                 </div>
                
// // // //                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
// // // //                     <div className="icon-box">💉</div>
// // // //                     <h3>Tiêm vaccine</h3>
// // // //                 </div>
                
// // // //                 <div className="service-card" onClick={() => navigate('/products')}>
// // // //                     <div className="icon-box">🛍️</div>
// // // //                     <h3>Cửa hàng</h3>
// // // //                 </div>
// // // //             </div>

// // // //             {/* 3. PROMO SECTION */}
// // // //             <div className="promo-section">
// // // //                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
// // // //                 <div className="promo-grid">
// // // //                     <div className="promo-item">
// // // //                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
// // // //                         <div className="promo-overlay">
// // // //                             <h3>Gói khám sức khỏe tổng quát</h3>
// // // //                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
// // // //                         </div>
// // // //                     </div>
// // // //                     <div className="promo-item">
// // // //                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
// // // //                         <div className="promo-overlay">
// // // //                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
// // // //                             <p>Chờ đón vào tháng sau!</p>
// // // //                         </div>
// // // //                     </div>
// // // //                     <div className="promo-item">
// // // //                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
// // // //                         <div className="promo-overlay">
// // // //                             <h3>Ngày hội tiêm chủng</h3>
// // // //                             <p>Miễn phí tư vấn</p>
// // // //                         </div>
// // // //                     </div>
// // // //                 </div>
// // // //             </div>
// // // //         </div>
// // // //     );
// // // // };

// // // // export default Home;

// // // import React from 'react';
// // // import { useNavigate } from 'react-router-dom';
// // // import './Home.css';

// // // const Home = () => {
// // //     const navigate = useNavigate(); 

// // //     const handleBookingClick = () => {
// // //         const token = localStorage.getItem('token');
// // //         if (token) {
// // //             navigate('/booking');
// // //         } else {
// // //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// // //             navigate('/login');
// // //         }
// // //     };

// // //     return (
// // //         <div className="home-container">
// // //             {/* 1. HERO SECTION */}
// // //             <div className="hero-wrapper">
                
// // //                 {/* --- 1. GÓC TRÁI DƯỚI: EM CORGI CƯỜI --- */}
// // //                 <img 
// // //                     src="https://cdn-icons-png.flaticon.com/512/1864/1864514.png" 
// // //                     alt="Corgi" 
// // //                     style={{
// // //                         position: 'absolute',
// // //                         bottom: '10px',
// // //                         left: '5%',
// // //                         height: '130px', 
// // //                         zIndex: 1,
// // //                         filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
// // //                     }} 
// // //                 />
                
// // //                 {/* --- 2. GÓC PHẢI DƯỚI: EM MÈO MẬP (Thay chỗ ông bác sĩ) --- */}
// // //                 <img 
// // //                     src="https://cdn-icons-png.flaticon.com/512/616/616408.png" 
// // //                     alt="Cat" 
// // //                     style={{
// // //                         position: 'absolute',
// // //                         bottom: '15px',
// // //                         right: '5%',
// // //                         height: '120px',
// // //                         zIndex: 1,
// // //                         filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
// // //                     }}
// // //                 />
                
// // //                 {/* --- 3. GÓC TRÁI TRÊN: DẤU CHÂN --- */}
// // //                 <img 
// // //                     src="https://cdn-icons-png.flaticon.com/512/1076/1076928.png" 
// // //                     alt="Paw" 
// // //                     style={{
// // //                         position: 'absolute',
// // //                         top: '15%',
// // //                         left: '10%',
// // //                         height: '50px',
// // //                         opacity: 0.6,
// // //                         transform: 'rotate(-20deg)',
// // //                         zIndex: 1
// // //                     }}
// // //                 />
                
// // //                 {/* --- 4. GÓC PHẢI TRÊN: CỤC XƯƠNG --- */}
// // //                 <img 
// // //                     src="https://cdn-icons-png.flaticon.com/512/1694/1694364.png" 
// // //                     alt="Bone" 
// // //                     style={{
// // //                         position: 'absolute',
// // //                         top: '15%',
// // //                         right: '10%',
// // //                         height: '50px',
// // //                         opacity: 0.8,
// // //                         transform: 'rotate(20deg)',
// // //                         zIndex: 1
// // //                     }}
// // //                 />

// // //                 {/* --- NỘI DUNG CHÍNH (Ở GIỮA) --- */}
// // //                 <div className="hero-content" style={{position: 'relative', zIndex: 2}}>
// // //                     <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
// // //                     <h1 className="hero-title">HappyPet Care</h1>
// // //                     <p className="hero-subtitle">
// // //                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
// // //                     </p>
// // //                     <button className="cta-button" onClick={handleBookingClick}>
// // //                         <span>ĐẶT LỊCH NGAY</span>
// // //                         <span style={{fontSize: '1.2rem', marginLeft: '8px'}}>📅</span>
// // //                     </button>
// // //                 </div>
// // //             </div>

// // //             {/* 2. FLOATING CARDS */}
// // //             <div className="floating-services">
// // //                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
// // //                     <div className="icon-box">🩺</div>
// // //                     <h3>Khám bệnh</h3>
// // //                 </div>
                
// // //                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
// // //                     <div className="icon-box">💉</div>
// // //                     <h3>Tiêm vaccine</h3>
// // //                 </div>
                
// // //                 <div className="service-card" onClick={() => navigate('/products')}>
// // //                     <div className="icon-box">🛍️</div>
// // //                     <h3>Cửa hàng</h3>
// // //                 </div>
// // //             </div>

// // //             {/* 3. PROMO SECTION */}
// // //             <div className="promo-section">
// // //                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
// // //                 <div className="promo-grid">
// // //                     <div className="promo-item">
// // //                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
// // //                         <div className="promo-overlay">
// // //                             <h3>Gói khám sức khỏe tổng quát</h3>
// // //                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
// // //                         </div>
// // //                     </div>
// // //                     <div className="promo-item">
// // //                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
// // //                         <div className="promo-overlay">
// // //                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
// // //                             <p>Chờ đón vào tháng sau!</p>
// // //                         </div>
// // //                     </div>
// // //                     <div className="promo-item">
// // //                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
// // //                         <div className="promo-overlay">
// // //                             <h3>Ngày hội tiêm chủng</h3>
// // //                             <p>Miễn phí tư vấn</p>
// // //                         </div>
// // //                     </div>
// // //                 </div>
// // //             </div>
// // //         </div>
// // //     );
// // // };

// // // export default Home;

// // import React from 'react';
// // import { useNavigate } from 'react-router-dom';
// // import './Home.css';

// // const Home = () => {
// //     const navigate = useNavigate(); 

// //     const handleBookingClick = () => {
// //         const token = localStorage.getItem('token');
// //         if (token) {
// //             navigate('/booking');
// //         } else {
// //             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
// //             navigate('/login');
// //         }
// //     };

// //     return (
// //         <div className="home-container">
// //             {/* 1. HERO SECTION */}
// //             <div className="hero-wrapper">
                
// //                 {/* --- 1. GÓC TRÁI DƯỚI: EM CORGI CƯỜI --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/1864/1864514.png" 
// //                     alt="Corgi" 
// //                     style={{
// //                         position: 'absolute',
// //                         bottom: '10px',
// //                         left: '5%',
// //                         height: '130px', 
// //                         zIndex: 1,
// //                         filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
// //                     }} 
// //                 />

// //                 {/* --- MÈO TRÁI (Thêm mới) --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/616/616430.png" 
// //                     alt="Cat Left" 
// //                     style={{
// //                         position: 'absolute',
// //                         bottom: '80px',
// //                         left: '15%',
// //                         height: '70px',
// //                         zIndex: 0,
// //                         transform: 'rotate(-10deg)',
// //                         opacity: 0.9
// //                     }} 
// //                 />
                
// //                 {/* --- 2. GÓC PHẢI DƯỚI: EM MÈO MẬP --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/616/616408.png" 
// //                     alt="Cat" 
// //                     style={{
// //                         position: 'absolute',
// //                         bottom: '15px',
// //                         right: '5%',
// //                         height: '120px',
// //                         zIndex: 1,
// //                         filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
// //                     }}
// //                 />

// //                 {/* --- CHÓ PHẢI (Thêm mới) --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/2829/2829818.png" 
// //                     alt="Dog Right" 
// //                     style={{
// //                         position: 'absolute',
// //                         bottom: '60px',
// //                         right: '16%',
// //                         height: '80px',
// //                         zIndex: 0,
// //                         transform: 'rotate(10deg)',
// //                         opacity: 0.9
// //                     }} 
// //                 />
                
// //                 {/* --- 3. GÓC TRÁI TRÊN: DẤU CHÂN --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/1076/1076928.png" 
// //                     alt="Paw" 
// //                     style={{
// //                         position: 'absolute',
// //                         top: '15%',
// //                         left: '10%',
// //                         height: '50px',
// //                         opacity: 0.6,
// //                         transform: 'rotate(-20deg)',
// //                         zIndex: 1
// //                     }}
// //                 />

// //                 {/* --- HAMSTER TRÊN CAO (Thêm mới) --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/235/235359.png" 
// //                     alt="Hamster" 
// //                     style={{
// //                         position: 'absolute',
// //                         top: '25%',
// //                         left: '20%',
// //                         height: '60px',
// //                         zIndex: 1,
// //                         transform: 'rotate(15deg)'
// //                     }}
// //                 />
                
// //                 {/* --- 4. GÓC PHẢI TRÊN: CỤC XƯƠNG --- */}
// //                 <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/1694/1694364.png" 
// //                     alt="Bone" 
// //                     style={{
// //                         position: 'absolute',
// //                         top: '15%',
// //                         right: '10%',
// //                         height: '50px',
// //                         opacity: 0.8,
// //                         transform: 'rotate(20deg)',
// //                         zIndex: 1
// //                     }}
// //                 />

// //                  {/* --- THỎ TRÊN CAO (Thêm mới) --- */}
// //                  <img 
// //                     src="https://cdn-icons-png.flaticon.com/512/3069/3069172.png" 
// //                     alt="Rabbit" 
// //                     style={{
// //                         position: 'absolute',
// //                         top: '28%',
// //                         right: '22%',
// //                         height: '55px',
// //                         zIndex: 1,
// //                         transform: 'rotate(-5deg)'
// //                     }}
// //                 />

// //                 {/* --- NỘI DUNG CHÍNH (Ở GIỮA) --- */}
// //                 <div className="hero-content" style={{position: 'relative', zIndex: 2}}>
// //                     <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
// //                     <h1 className="hero-title">HappyPet Care</h1>
// //                     <p className="hero-subtitle">
// //                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
// //                     </p>
// //                     <button className="cta-button" onClick={handleBookingClick}>
// //                         <span>ĐẶT LỊCH NGAY</span>
// //                         <span style={{fontSize: '1.2rem', marginLeft: '8px'}}>📅</span>
// //                     </button>
// //                 </div>
// //             </div>

// //             {/* 2. FLOATING CARDS */}
// //             <div className="floating-services">
// //                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
// //                     <div className="icon-box">🩺</div>
// //                     <h3>Khám bệnh</h3>
// //                 </div>
                
// //                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
// //                     <div className="icon-box">💉</div>
// //                     <h3>Tiêm vaccine</h3>
// //                 </div>
                
// //                 <div className="service-card" onClick={() => navigate('/products')}>
// //                     <div className="icon-box">🛍️</div>
// //                     <h3>Cửa hàng</h3>
// //                 </div>
// //             </div>

// //             {/* 3. PROMO SECTION - ĐÃ ĐẨY LÊN CAO HƠN */}
// //             <div className="promo-section" style={{ marginTop: '-40px', paddingTop: '0' }}> 
// //                 {/* style inline này giúp kéo phần promo lên sát hơn mà không cần sửa file CSS */}
// //                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
// //                 <div className="promo-grid">
// //                     <div className="promo-item">
// //                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
// //                         <div className="promo-overlay">
// //                             <h3>Gói khám sức khỏe tổng quát</h3>
// //                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
// //                         </div>
// //                     </div>
// //                     <div className="promo-item">
// //                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
// //                         <div className="promo-overlay">
// //                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
// //                             <p>Chờ đón vào tháng sau!</p>
// //                         </div>
// //                     </div>
// //                     <div className="promo-item">
// //                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
// //                         <div className="promo-overlay">
// //                             <h3>Ngày hội tiêm chủng</h3>
// //                             <p>Miễn phí tư vấn</p>
// //                         </div>
// //                     </div>
// //                 </div>
// //             </div>
// //         </div>
// //     );
// // };

// // export default Home;

// import React from 'react';
// import { useNavigate } from 'react-router-dom';
// import './Home.css';

// const Home = () => {
//     const navigate = useNavigate(); 

//     const handleBookingClick = () => {
//         const token = localStorage.getItem('token');
//         if (token) {
//             navigate('/booking');
//         } else {
//             alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
//             navigate('/login');
//         }
//     };

//     return (
//         <div className="home-container">
//             {/* 1. HERO SECTION */}
//             <div className="hero-wrapper">
                
//                 {/* --- 1. GÓC TRÁI DƯỚI: EM CORGI CƯỜI --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/1864/1864514.png" 
//                     alt="Corgi" 
//                     style={{
//                         position: 'absolute',
//                         bottom: '10px',
//                         left: '5%',
//                         height: '130px', 
//                         zIndex: 1,
//                         filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
//                     }} 
//                 />

//                 {/* --- MÈO TRÁI --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/616/616430.png" 
//                     alt="Cat Left" 
//                     style={{
//                         position: 'absolute',
//                         bottom: '80px',
//                         left: '15%',
//                         height: '70px',
//                         zIndex: 0,
//                         transform: 'rotate(-10deg)',
//                         opacity: 0.9
//                     }} 
//                 />
                
//                 {/* --- 2. GÓC PHẢI DƯỚI: EM MÈO MẬP --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/616/616408.png" 
//                     alt="Cat" 
//                     style={{
//                         position: 'absolute',
//                         bottom: '15px',
//                         right: '5%',
//                         height: '120px',
//                         zIndex: 1,
//                         filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
//                     }}
//                 />

//                 {/* --- CHÓ PHẢI --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/2829/2829818.png" 
//                     alt="Dog Right" 
//                     style={{
//                         position: 'absolute',
//                         bottom: '60px',
//                         right: '16%',
//                         height: '80px',
//                         zIndex: 0,
//                         transform: 'rotate(10deg)',
//                         opacity: 0.9
//                     }} 
//                 />
                
//                 {/* --- 3. GÓC TRÁI TRÊN: DẤU CHÂN --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/1076/1076928.png" 
//                     alt="Paw" 
//                     style={{
//                         position: 'absolute',
//                         top: '15%',
//                         left: '10%',
//                         height: '50px',
//                         opacity: 0.6,
//                         transform: 'rotate(-20deg)',
//                         zIndex: 1
//                     }}
//                 />

//                 {/* --- HAMSTER TRÊN CAO --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/235/235359.png" 
//                     alt="Hamster" 
//                     style={{
//                         position: 'absolute',
//                         top: '25%',
//                         left: '20%',
//                         height: '60px',
//                         zIndex: 1,
//                         transform: 'rotate(15deg)'
//                     }}
//                 />
                
//                 {/* --- 4. GÓC PHẢI TRÊN: CỤC XƯƠNG --- */}
//                 <img 
//                     src="https://cdn-icons-png.flaticon.com/512/1694/1694364.png" 
//                     alt="Bone" 
//                     style={{
//                         position: 'absolute',
//                         top: '15%',
//                         right: '10%',
//                         height: '50px',
//                         opacity: 0.8,
//                         transform: 'rotate(20deg)',
//                         zIndex: 1
//                     }}
//                 />

//                  {/* --- THỎ TRÊN CAO --- */}
//                  <img 
//                     src="https://cdn-icons-png.flaticon.com/512/3069/3069172.png" 
//                     alt="Rabbit" 
//                     style={{
//                         position: 'absolute',
//                         top: '28%',
//                         right: '22%',
//                         height: '55px',
//                         zIndex: 1,
//                         transform: 'rotate(-5deg)'
//                     }}
//                 />

//                 {/* --- NỘI DUNG CHÍNH (Ở GIỮA) --- */}
//                 <div className="hero-content" style={{position: 'relative', zIndex: 2}}>
//                     <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
//                     <h1 className="hero-title">HappyPet Care</h1>
//                     <p className="hero-subtitle">
//                         Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
//                     </p>
//                     <button className="cta-button" onClick={handleBookingClick}>
//                         <span>ĐẶT LỊCH NGAY</span>
//                         <span style={{fontSize: '1.2rem', marginLeft: '8px'}}>📅</span>
//                     </button>
//                 </div>
//             </div>

//             {/* 2. FLOATING CARDS */}
//             <div className="floating-services">
//                 <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
//                     <div className="icon-box">🩺</div>
//                     <h3>Khám bệnh</h3>
//                 </div>
                
//                 <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
//                     <div className="icon-box">💉</div>
//                     <h3>Tiêm vaccine</h3>
//                 </div>
                
//                 <div className="service-card" onClick={() => navigate('/products')}>
//                     <div className="icon-box">🛍️</div>
//                     <h3>Cửa hàng</h3>
//                 </div>
//             </div>

//             {/* 3. PROMO SECTION - ĐÃ ĐẨY XUỐNG DƯỚI CHO THOÁNG */}
//             <div className="promo-section" style={{ marginTop: '80px' }}> 
//                 <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
//                 <div className="promo-grid">
//                     <div className="promo-item">
//                         <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
//                         <div className="promo-overlay">
//                             <h3>Gói khám sức khỏe tổng quát</h3>
//                             <p>Sắp ra mắt - Đăng ký nhận tin</p>
//                         </div>
//                     </div>
//                     <div className="promo-item">
//                         <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
//                         <div className="promo-overlay">
//                             <h3>Siêu sale đồ ăn & phụ kiện</h3>
//                             <p>Chờ đón vào tháng sau!</p>
//                         </div>
//                     </div>
//                     <div className="promo-item">
//                         <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
//                         <div className="promo-overlay">
//                             <h3>Ngày hội tiêm chủng</h3>
//                             <p>Miễn phí tư vấn</p>
//                         </div>
//                     </div>
//                 </div>
//             </div>
//         </div>
//     );
// };

// export default Home;

import React from 'react';
import { useNavigate } from 'react-router-dom';
import './Home.css';

const Home = () => {
    const navigate = useNavigate(); 

    const handleBookingClick = () => {
        const token = localStorage.getItem('token');
        if (token) {
            navigate('/booking');
        } else {
            alert("Bạn cần đăng nhập để đặt lịch nha! 🐾");
            navigate('/login');
        }
    };

    return (
        <div className="home-container">
            {/* 1. HERO SECTION */}
            <div className="hero-wrapper">
                
                {/* --- 1. GÓC TRÁI DƯỚI: EM CORGI CƯỜI --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/1864/1864514.png" 
                    alt="Corgi" 
                    style={{
                        position: 'absolute',
                        bottom: '10px',
                        left: '5%',
                        height: '130px', 
                        zIndex: 1,
                        filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
                    }} 
                />

                {/* --- MÈO TRÁI --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/616/616430.png" 
                    alt="Cat Left" 
                    style={{
                        position: 'absolute',
                        bottom: '80px',
                        left: '15%',
                        height: '70px',
                        zIndex: 0,
                        transform: 'rotate(-10deg)',
                        opacity: 0.9
                    }} 
                />
                
                {/* --- 2. GÓC PHẢI DƯỚI: EM MÈO MẬP --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/616/616408.png" 
                    alt="Cat" 
                    style={{
                        position: 'absolute',
                        bottom: '15px',
                        right: '5%',
                        height: '120px',
                        zIndex: 1,
                        filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.2))'
                    }}
                />

                {/* --- CHÓ PHẢI --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/2829/2829818.png" 
                    alt="Dog Right" 
                    style={{
                        position: 'absolute',
                        bottom: '60px',
                        right: '16%',
                        height: '80px',
                        zIndex: 0,
                        transform: 'rotate(10deg)',
                        opacity: 0.9
                    }} 
                />
                
                {/* --- 3. GÓC TRÁI TRÊN: DẤU CHÂN --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/1076/1076928.png" 
                    alt="Paw" 
                    style={{
                        position: 'absolute',
                        top: '15%',
                        left: '10%',
                        height: '50px',
                        opacity: 0.6,
                        transform: 'rotate(-20deg)',
                        zIndex: 1
                    }}
                />

                {/* --- HAMSTER TRÊN CAO --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/235/235359.png" 
                    alt="Hamster" 
                    style={{
                        position: 'absolute',
                        top: '25%',
                        left: '20%',
                        height: '60px',
                        zIndex: 1,
                        transform: 'rotate(15deg)'
                    }}
                />
                
                {/* --- 4. GÓC PHẢI TRÊN: CỤC XƯƠNG --- */}
                <img 
                    src="https://cdn-icons-png.flaticon.com/512/1694/1694364.png" 
                    alt="Bone" 
                    style={{
                        position: 'absolute',
                        top: '15%',
                        right: '10%',
                        height: '50px',
                        opacity: 0.8,
                        transform: 'rotate(20deg)',
                        zIndex: 1
                    }}
                />

                 {/* --- THỎ TRÊN CAO --- */}
                 <img 
                    src="https://cdn-icons-png.flaticon.com/512/3069/3069172.png" 
                    alt="Rabbit" 
                    style={{
                        position: 'absolute',
                        top: '28%',
                        right: '22%',
                        height: '55px',
                        zIndex: 1,
                        transform: 'rotate(-5deg)'
                    }}
                />

                {/* --- NỘI DUNG CHÍNH (Ở GIỮA) --- */}
                <div className="hero-content" style={{position: 'relative', zIndex: 2}}>
                    <span className="hero-badge">✨ Dịch vụ thú cưng số #1</span>
                    <h1 className="hero-title">HappyPet Care</h1>
                    <p className="hero-subtitle">
                        Nơi tình yêu thú cưng bắt đầu. Chăm sóc toàn diện cho Boss của bạn.
                    </p>
                    <button className="cta-button" onClick={handleBookingClick}>
                        <span>ĐẶT LỊCH NGAY</span>
                        <span style={{fontSize: '1.2rem', marginLeft: '8px'}}>📅</span>
                    </button>
                </div>
            </div>

            {/* 2. FLOATING CARDS */}
            <div className="floating-services">
                <div className="service-card" onClick={() => navigate('/booking?service=kham-benh')}>
                    <div className="icon-box">🩺</div>
                    <h3>Khám bệnh</h3>
                </div>
                
                <div className="service-card" onClick={() => navigate('/booking?service=tiem-vaccine')}>
                    <div className="icon-box">💉</div>
                    <h3>Tiêm vaccine</h3>
                </div>
                
                <div className="service-card" onClick={() => navigate('/products')}>
                    <div className="icon-box">🛍️</div>
                    <h3>Cửa hàng</h3>
                </div>
            </div>

            {/* 3. PROMO SECTION - TRẢ VỀ VỊ TRÍ GỐC (BỎ MARGIN) */}
            <div className="promo-section"> 
                <h2 className="section-title">Ưu đãi <span className="highlight">Hot</span> sắp tới 🔥</h2>
                
                <div className="promo-grid">
                    <div className="promo-item">
                        <img src="https://img.freepik.com/free-photo/dog-waiting-veterinarian-office_23-2149198674.jpg" alt="Kham benh" />
                        <div className="promo-overlay">
                            <h3>Gói khám sức khỏe tổng quát</h3>
                            <p>Sắp ra mắt - Đăng ký nhận tin</p>
                        </div>
                    </div>
                    <div className="promo-item">
                        <img src="https://img.freepik.com/free-photo/group-portrait-adorable-puppies_53876-64778.jpg" alt="Food" />
                        <div className="promo-overlay">
                            <h3>Siêu sale đồ ăn & phụ kiện</h3>
                            <p>Chờ đón vào tháng sau!</p>
                        </div>
                    </div>
                    <div className="promo-item">
                        <img src="https://img.freepik.com/free-photo/close-up-veterinarian-taking-care-dog_23-2149100197.jpg" alt="Vaccine" />
                        <div className="promo-overlay">
                            <h3>Ngày hội tiêm chủng</h3>
                            <p>Miễn phí tư vấn</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Home;