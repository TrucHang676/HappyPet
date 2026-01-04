// import React, { useState, useEffect } from 'react';
// import axios from 'axios';
// import { useLocation, useNavigate } from 'react-router-dom';
// import './Booking.css';

// const SelectVaccine = () => {
//     const location = useLocation();
//     const navigate = useNavigate();
//     const { MaPhieu } = location.state || {};

//     const [activeTab, setActiveTab] = useState('single'); 
//     const [vaccines, setVaccines] = useState([]);
//     const [packages, setPackages] = useState([]);
//     const [selectedItems, setSelectedItems] = useState([]); 
    
//     // State chọn vaccine để áp gói
//     const [targetVaccineForPackage, setTargetVaccineForPackage] = useState('');

//     // 🔥 1. THÊM STATE TÌM KIẾM
//     const [searchTerm, setSearchTerm] = useState('');

//     useEffect(() => {
//         if (!MaPhieu) {
//             alert("Không tìm thấy mã phiếu!");
//             navigate('/booking'); 
//             return;
//         }
//         fetchData();
//     }, [MaPhieu]);

//     const fetchData = async () => {
//         try {
//             const token = localStorage.getItem('token');
//             const headers = { Authorization: `Bearer ${token}` };

//             // 1. Lấy dữ liệu
//             const resData = await axios.get('https://happy-pet-fomc.onrender.com/api/booking/vaccine-data', { headers });
//             setVaccines(resData.data.vaccines);
//             setPackages(resData.data.packages);
            
//             if(resData.data.vaccines.length > 0) {
//                 setTargetVaccineForPackage(resData.data.vaccines[0].MaVaccine);
//             }

//             // 2. Lấy giỏ hàng
//             fetchSelected(headers);
//         } catch (error) { console.error(error); }
//     };

//     const fetchSelected = async (headers) => {
//         try {
//             const resSelected = await axios.get(`https://happy-pet-fomc.onrender.com/api/booking/selected/${MaPhieu}`, { headers });
//             setSelectedItems(resSelected.data);
//         } catch (error) { console.error(error); }
//     };

//     const handleAction = async (url, body) => {
//         try {
//             const token = localStorage.getItem('token');
//             await axios.post(`https://happy-pet-fomc.onrender.com/api/booking/${url}`, 
//                 { ...body, MaPhieu }, 
//                 { headers: { Authorization: `Bearer ${token}` } }
//             );
//             fetchSelected({ Authorization: `Bearer ${token}` }); 
//         } catch (error) {
//             alert("❌ Lỗi: " + (error.response?.data?.message || "Thất bại"));
//         }
//     };

//     // 🔥 2. LOGIC LỌC DANH SÁCH (Dùng chung cho cả 2 tab)
//     const filteredVaccines = vaccines.filter(v => 
//         v.TenVaccine.toLowerCase().includes(searchTerm.toLowerCase())
//     );

//     return (
//         <div className="booking-container" style={{maxWidth: '1000px'}}>
//             <h2 className="booking-title">💉 Chọn Vaccine (Phiếu: {MaPhieu})</h2>

//             <div style={{display: 'flex', gap: '20px'}}>
//                 {/* TRÁI: DANH SÁCH CHỌN */}
//                 <div style={{flex: 2}}>
                    
//                     {/* MENU TABS */}
//                     <div className="tabs" style={{marginBottom: '15px'}}>
//                         <button style={{padding: '10px 20px', background: activeTab==='single' ? '#1565c0' : '#eee', color: activeTab==='single'?'white':'black', border:'none', marginRight:'5px', cursor:'pointer'}} onClick={() => setActiveTab('single')}>
//                             Chọn Mũi Lẻ
//                         </button>
//                         <button style={{padding: '10px 20px', background: activeTab==='package' ? '#1565c0' : '#eee', color: activeTab==='package'?'white':'black', border:'none', cursor:'pointer'}} onClick={() => setActiveTab('package')}>
//                             Chọn Theo Gói
//                         </button>
//                     </div>

//                     {/* 🔥 3. Ô TÌM KIẾM (ĐẶT Ở ĐÂY) */}
//                     <div style={{marginBottom: '15px'}}>
//                         <input 
//                             type="text" 
//                             placeholder="🔍 Tìm tên vaccine (Ví dụ: Dại, 7 bệnh, Mèo...)"
//                             value={searchTerm}
//                             onChange={(e) => setSearchTerm(e.target.value)}
//                             style={{
//                                 width: '100%',
//                                 padding: '12px',
//                                 borderRadius: '5px',
//                                 border: '1px solid #1565c0',
//                                 fontSize: '16px',
//                                 outline: 'none',
//                                 boxSizing: 'border-box'
//                             }}
//                         />
//                     </div>

//                     <div style={{maxHeight: '500px', overflowY: 'auto'}}>
//                         {activeTab === 'single' ? (
//                             // --- TAB LẺ ---
//                             filteredVaccines.length === 0 ? (
//                                 <p style={{textAlign:'center', color:'#777'}}>Không tìm thấy vaccine nào phù hợp.</p>
//                             ) : (
//                                 filteredVaccines.map(v => (
//                                     <div key={v.MaVaccine} className="item-card" style={{border: '1px solid #ddd', padding: '10px', marginBottom: '10px', display:'flex', justifyContent:'space-between', alignItems:'center'}}>
//                                         <div>
//                                             <strong>{v.TenVaccine}</strong>
//                                             <p style={{margin:0, color:'#666'}}>{v.DonGia?.toLocaleString()} VNĐ</p>
//                                         </div>
//                                         <button onClick={() => handleAction('add-single', { MaVaccine: v.MaVaccine })} style={{background:'#2e7d32', color:'white', border:'none', padding:'5px 10px', borderRadius:'4px', cursor:'pointer'}}>+ Thêm</button>
//                                     </div>
//                                 ))
//                             )
//                         ) : (
//                             // --- TAB GÓI ---
//                             <div>
//                                 <div style={{background: '#fff3cd', padding: '10px', marginBottom: '15px', borderRadius: '5px', border: '1px solid #ffeeba'}}>
//                                     <label style={{fontWeight:'bold', display:'block', marginBottom:'5px'}}>👉 Bước 1: Bạn muốn mua gói cho loại Vaccine nào?</label>
                                    
//                                     {/* Dropdown này cũng sẽ được lọc theo ô tìm kiếm luôn cho tiện */}
//                                     <select 
//                                         className="input-field" 
//                                         value={targetVaccineForPackage}
//                                         onChange={(e) => setTargetVaccineForPackage(e.target.value)}
//                                         style={{width: '100%', padding: '8px'}}
//                                     >
//                                         {filteredVaccines.length > 0 ? (
//                                             filteredVaccines.map(v => (
//                                                 <option key={v.MaVaccine} value={v.MaVaccine}>{v.TenVaccine} - {v.DonGia?.toLocaleString()}đ</option>
//                                             ))
//                                         ) : (
//                                             <option disabled>Không tìm thấy vaccine</option>
//                                         )}
//                                     </select>
//                                 </div>

//                                 <p style={{fontWeight:'bold', marginBottom:'10px'}}>👉 Bước 2: Chọn gói ưu đãi:</p>

//                                 {packages.map(p => (
//                                     <div key={p.MaGoi} className="item-card" style={{border: '1px solid #ddd', padding: '10px', marginBottom: '10px', display:'flex', justifyContent:'space-between', alignItems:'center'}}>
//                                         <div>
//                                             <strong>{p.TenGoi}</strong> 
//                                             <span style={{fontSize:'12px', background:'#ff9800', marginLeft:'5px', padding:'2px 5px', borderRadius:'4px', color:'white'}}>Giảm {p.GiamGia * 100}%</span>
//                                             <p style={{margin:0, fontSize:'13px'}}>({p.SoMuiTuongUng} mũi - Hạn {p.ThoiHan} tháng)</p>
//                                         </div>
//                                         <button 
//                                             onClick={() => handleAction('add-package', { MaVaccine: targetVaccineForPackage, MaGoi: p.MaGoi })}
//                                             style={{background:'#1565c0', color:'white', border:'none', padding:'5px 10px', borderRadius:'4px', cursor:'pointer'}}
//                                         >
//                                             + Chọn Gói Này
//                                         </button>
//                                     </div>
//                                 ))}
//                             </div>
//                         )}
//                     </div>
//                 </div>

//                 {/* PHẢI: GIỎ HÀNG */}
//                 <div style={{flex: 1.5, borderLeft: '1px solid #eee', paddingLeft: '20px'}}>
//                     <h3 style={{color:'#d35400'}}>Giỏ Vaccine Của Bạn</h3>
//                     {selectedItems.length === 0 ? <p style={{color:'#777'}}>Chưa chọn vaccine nào.</p> : (
//                         selectedItems.map((item, index) => (
//                             <div key={index} style={{background: '#fff3e0', padding:'10px', marginBottom:'10px', borderRadius:'5px', border:'1px solid #ffe0b2'}}>
//                                 <strong>{item.TenVaccine || 'Vaccine'}</strong>
//                                 {item.MaGoi ? <div style={{color:'#d84315', fontSize:'13px', fontWeight:'bold'}}>📦 {item.TenGoi}</div> : <div style={{color:'green', fontSize:'13px'}}>💉 Mũi lẻ</div>}
//                                 <div style={{display:'flex', justifyContent:'space-between', marginTop:'5px'}}>
//                                     <span style={{fontWeight:'bold'}}>{item.ThanhTien?.toLocaleString()} đ</span>
//                                     <button 
//                                         onClick={() => item.MaGoi 
//                                             ? handleAction('remove-package', { MaVaccine: item.MaVaccine, MaGoi: item.MaGoi }) 
//                                             : handleAction('remove-single', { MaVaccine: item.MaVaccine })
//                                         }
//                                         style={{color:'red', border:'none', background:'none', cursor:'pointer', fontWeight:'bold'}}
//                                     >Xóa</button>
//                                 </div>
//                             </div>
//                         ))
//                     )}
//                     <button onClick={() => navigate('/history')} style={{width:'100%', marginTop:'20px', padding:'15px', background:'#ff6f00', color:'white', border:'none', borderRadius:'5px', fontWeight:'bold', cursor:'pointer', fontSize:'16px'}}>
//                         HOÀN TẤT ĐẶT LỊCH
//                     </button>
//                 </div>
//             </div>
//         </div>
//     );
// };

// export default SelectVaccine;


import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useLocation, useNavigate } from 'react-router-dom';
import Swal from 'sweetalert2'; // 🔥 1. Thêm import Swal
import './Booking.css';

const SelectVaccine = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const { MaPhieu } = location.state || {};

    const [activeTab, setActiveTab] = useState('single'); 
    const [vaccines, setVaccines] = useState([]);
    const [packages, setPackages] = useState([]);
    const [selectedItems, setSelectedItems] = useState([]); 
    
    // State chọn vaccine để áp gói
    const [targetVaccineForPackage, setTargetVaccineForPackage] = useState('');

    // State tìm kiếm
    const [searchTerm, setSearchTerm] = useState('');
    
    // 🔥 State gói đang tiêm
    const [ongoingPackage, setOngoingPackage] = useState(null);
    const [isCheckingPackage, setIsCheckingPackage] = useState(true);

    useEffect(() => {
        if (!MaPhieu) {
            alert("Không tìm thấy mã phiếu!");
            navigate('/booking'); 
            return;
        }
        fetchData();
    }, [MaPhieu]);

    const fetchData = async () => {
        try {
            const token = localStorage.getItem('token');
            const headers = { Authorization: `Bearer ${token}` };

            // 1. Lấy dữ liệu vaccines và packages TRƯỚC
            const resData = await axios.get('https://happy-pet-fomc.onrender.com/api/booking/vaccine-data', { headers });
            setVaccines(resData.data.vaccines);
            setPackages(resData.data.packages);
            
            if(resData.data.vaccines.length > 0) {
                setTargetVaccineForPackage(resData.data.vaccines[0].MaVaccine);
            }

            // 2. Lấy giỏ hàng
            fetchSelected(headers);
            
            // 3. Check gói đang tiêm (KHÔNG BLOCK, chạy riêng)
            checkOngoingPackage(headers);
            
        } catch (error) { 
            console.error('Lỗi load data:', error); 
            setIsCheckingPackage(false);
        }
    };
    
    // Hàm riêng check gói đang tiêm
    const checkOngoingPackage = async (headers) => {
        try {
            // Lấy thông tin phiếu để biết MaTC
            const resPhieu = await axios.get(`https://happy-pet-fomc.onrender.com/api/booking/booking-info/${MaPhieu}`, { headers });
            const MaTC = resPhieu.data.MaTC;
            
            if (!MaTC) {
                console.log('Phiếu chưa có MaTC');
                setIsCheckingPackage(false);
                return;
            }
            
            // Check gói đang tiêm
            const resCheck = await axios.get(`https://happy-pet-fomc.onrender.com/api/booking/check-ongoing-package/${MaTC}`, { headers });
            
            if (resCheck.data && resCheck.data.MaGoi) {
                console.log('🔥 GOI DANG TIEM:', resCheck.data);
                setOngoingPackage(resCheck.data);
                // Hiển thị thông báo
                Swal.fire({
                    icon: 'info',
                    title: '⚠️ Thú cưng đang có gói tiêm dở!',
                    html: `
                        <div style="text-align: left;">
                            <p><strong>Gói:</strong> ${resCheck.data.TenGoi}</p>
                            <p><strong>Vaccine:</strong> ${resCheck.data.MaVaccine}</p>
                            <p><strong>Tiến độ:</strong> ${resCheck.data.SoMuiDaTiem}/${resCheck.data.TongSoMui} mũi</p>
                            <hr/>
                            <p style="color: #f57c00;"><strong>Lưu ý:</strong> Bạn chỉ nên chọn <strong>Mũi Lẻ</strong> để tiêm thêm vaccine khác. Tab "Chọn Theo Gói" đã bị vô hiệu hóa.</p>
                        </div>
                    `,
                    confirmButtonText: 'Đã hiểu'
                });
                // Force tab sang Mũi Lẻ
                setActiveTab('single');
            }
        } catch (err) {
            console.log('Không có gói đang tiêm hoặc lỗi:', err.message);
        } finally {
            setIsCheckingPackage(false);
        }
    };

    const fetchSelected = async (headers) => {
        try {
            const resSelected = await axios.get(`https://happy-pet-fomc.onrender.com/api/booking/selected/${MaPhieu}`, { headers });
            setSelectedItems(resSelected.data);
        } catch (error) { console.error(error); }
    };

    const handleAction = async (url, body) => {
        try {
            const token = localStorage.getItem('token');
            await axios.post(`https://happy-pet-fomc.onrender.com/api/booking/${url}`, 
                { ...body, MaPhieu }, 
                { headers: { Authorization: `Bearer ${token}` } }
            );
            fetchSelected({ Authorization: `Bearer ${token}` }); 
        } catch (error) {
            alert("❌ Lỗi: " + (error.response?.data?.message || "Thất bại"));
        }
    };

    // 🔥 2. HÀM XỬ LÝ NÚT HOÀN TẤT (MỚI THÊM)
    const handleConfirm = () => {
        // Kiểm tra nếu giỏ hàng trống thì nhắc nhẹ (hoặc bỏ qua nếu bà muốn cho phép trống)
        if (selectedItems.length === 0) {
            Swal.fire({
                title: 'Giỏ hàng trống?',
                text: "Bạn chưa chọn vaccine nào. Bạn có chắc muốn hoàn tất không?",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Vẫn hoàn tất',
                cancelButtonText: 'Chọn thêm'
            }).then((result) => {
                if (result.isConfirmed) {
                    finishBooking();
                }
            });
        } else {
            finishBooking();
        }
    };

    // Hàm phụ để hiện thông báo thành công và chuyển trang
    const finishBooking = () => {
        Swal.fire({
            icon: 'success',
            title: 'Hoàn tất chọn Vaccine! 💉',
            text: 'Hệ thống sẽ chuyển đến trang lịch sử ngay bây giờ.',
            timer: 2000, 
            showConfirmButton: false
        }).then(() => {
            navigate('/my-bookings'); // Chuyển về trang lịch sử đặt hẹn
        });
    };

    // Logic lọc danh sách
    const filteredVaccines = vaccines.filter(v => 
        v.TenVaccine.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="booking-container" style={{maxWidth: '1000px'}}>
            <h2 className="booking-title">💉 Chọn Vaccine (Phiếu: {MaPhieu})</h2>

            <div style={{display: 'flex', gap: '20px'}}>
                {/* TRÁI: DANH SÁCH CHỌN */}
                <div style={{flex: 2}}>
                    
                    {/* MENU TABS */}
                    <div className="tabs" style={{marginBottom: '15px'}}>
                        <button 
                            style={{
                                padding: '10px 20px', 
                                background: activeTab==='single' ? '#1565c0' : '#eee', 
                                color: activeTab==='single'?'white':'black', 
                                border:'none', 
                                marginRight:'5px', 
                                cursor:'pointer'
                            }} 
                            onClick={() => setActiveTab('single')}
                        >
                            Chọn Mũi Lẻ
                        </button>
                        <button 
                            style={{
                                padding: '10px 20px', 
                                background: activeTab==='package' ? '#1565c0' : '#eee', 
                                color: activeTab==='package'?'white':'black', 
                                border:'none', 
                                cursor: 'pointer'
                            }} 
                            onClick={() => setActiveTab('package')}
                        >
                            Chọn Theo Gói
                        </button>
                    </div>
                    
                    {/* Card gói đang tiêm */}
                    {console.log('🎯 Render SelectVaccine, ongoingPackage:', ongoingPackage)}
                    {ongoingPackage && (
                        <div style={{
                            padding: '15px', 
                            background: 'linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)', 
                            border: '3px solid #1976d2', 
                            borderRadius: '12px', 
                            marginBottom: '20px',
                            boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                        }}>
                            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px'}}>
                                <h4 style={{margin: 0, color: '#1565c0', fontSize: '18px'}}>
                                    💉 Gói Đang Tiêm
                                </h4>
                                <span style={{
                                    background: '#4caf50',
                                    color: 'white',
                                    padding: '4px 12px',
                                    borderRadius: '20px',
                                    fontSize: '13px',
                                    fontWeight: 'bold'
                                }}>
                                    Mũi {ongoingPackage.SoMuiDaTiem + 1}/{ongoingPackage.TongSoMui}
                                </span>
                            </div>
                            
                            <div style={{marginBottom: '12px', fontSize: '14px'}}>
                                <div style={{marginBottom: '6px'}}>
                                    <strong>📦 Gói:</strong> {ongoingPackage.TenGoi}
                                </div>
                                <div style={{marginBottom: '6px'}}>
                                    <strong>💊 Vaccine:</strong> {ongoingPackage.MaVaccine}
                                </div>
                                <div>
                                    <strong>📅 Hạn:</strong> {ongoingPackage.NgayHetHan ? new Date(ongoingPackage.NgayHetHan).toLocaleDateString('vi-VN') : 'Không giới hạn'}
                                </div>
                            </div>
                            
                            <button
                                onClick={async () => {
                                    try {
                                        const token = localStorage.getItem('token');
                                        const resPhieu = await axios.get(`https://happy-pet-fomc.onrender.com/api/booking/booking-info/${MaPhieu}`, {
                                            headers: { Authorization: `Bearer ${token}` }
                                        });
                                        const MaTC = resPhieu.data.MaTC;
                                        
                                        await axios.post('https://happy-pet-fomc.onrender.com/api/booking/add-to-ongoing-package', 
                                            { MaPhieu, MaTC },
                                            { headers: { Authorization: `Bearer ${token}` } }
                                        );
                                        
                                        Swal.fire('Thành công!', 'Đã thêm mũi tiếp theo vào gói!', 'success');
                                        fetchSelected({ Authorization: `Bearer ${token}` });
                                    } catch (err) {
                                        Swal.fire('Lỗi', err.response?.data?.message || 'Không thể thêm!', 'error');
                                    }
                                }}
                                style={{
                                    width: '100%',
                                    padding: '12px',
                                    background: '#1976d2',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '8px',
                                    fontSize: '16px',
                                    fontWeight: 'bold',
                                    cursor: 'pointer',
                                    transition: 'all 0.3s'
                                }}
                                onMouseOver={(e) => e.target.style.background = '#1565c0'}
                                onMouseOut={(e) => e.target.style.background = '#1976d2'}
                            >
                                ✅ Tiêm Tiếp Gói Này
                            </button>
                            
                            <p style={{margin: '10px 0 0 0', fontSize: '13px', color: '#666', textAlign: 'center'}}>
                                💡 Hoặc chọn vaccine lẻ khác ở dưới
                            </p>
                        </div>
                    )}

                    {/* Ô TÌM KIẾM */}
                    <div style={{marginBottom: '15px'}}>
                        <input 
                            type="text" 
                            placeholder="🔍 Tìm tên vaccine (Ví dụ: Dại, 7 bệnh, Mèo...)"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            style={{
                                width: '100%', padding: '12px', borderRadius: '5px',
                                border: '1px solid #1565c0', fontSize: '16px', outline: 'none', boxSizing: 'border-box'
                            }}
                        />
                    </div>

                    <div style={{maxHeight: '500px', overflowY: 'auto'}}>
                        {activeTab === 'single' ? (
                            // --- TAB LẺ ---
                            filteredVaccines.length === 0 ? (
                                <p style={{textAlign:'center', color:'#777'}}>Không tìm thấy vaccine nào phù hợp.</p>
                            ) : (
                                filteredVaccines.map(v => {
                                    // Disable vaccine nếu đang trong gói dở
                                    const isDisabled = ongoingPackage && v.MaVaccine === ongoingPackage.MaVaccine;
                                    
                                    return (
                                        <div key={v.MaVaccine} className="item-card" style={{
                                            border: '1px solid #ddd', 
                                            padding: '10px', 
                                            marginBottom: '10px', 
                                            display:'flex', 
                                            justifyContent:'space-between', 
                                            alignItems:'center',
                                            opacity: isDisabled ? 0.5 : 1
                                        }}>
                                            <div>
                                                <strong>{v.TenVaccine}</strong>
                                                {isDisabled && <span style={{color:'red', fontSize:'12px', marginLeft:'8px'}}>⚠️ Đang trong gói</span>}
                                                <p style={{margin:0, fontSize:'13px', color:'#666'}}>{v.DonGia?.toLocaleString()} VNĐ</p>
                                            </div>
                                            <button 
                                                onClick={() => {
                                                    if (isDisabled) {
                                                        return Swal.fire('Lỗi', 'Vaccine này đang trong gói dở! Không thể thêm mũi lẻ.', 'error');
                                                    }
                                                    handleAction('add-single', { MaVaccine: v.MaVaccine });
                                                }}
                                                disabled={isDisabled}
                                                style={{
                                                    background: isDisabled ? '#ccc' : '#28a745', 
                                                    color:'white', 
                                                    border:'none', 
                                                    padding:'5px 15px', 
                                                    borderRadius:'4px', 
                                                    cursor: isDisabled ? 'not-allowed' : 'pointer'
                                                }}
                                            >
                                                + Thêm
                                            </button>
                                        </div>
                                    );
                                })
                            )
                        ) : (
                            // --- TAB GÓI ---
                            <div>
                                <div style={{background: '#fff3cd', padding: '10px', marginBottom: '15px', borderRadius: '5px', border: '1px solid #ffeeba'}}>
                                    <label style={{fontWeight:'bold', display:'block', marginBottom:'5px'}}>👉 Bước 1: Bạn muốn mua gói cho loại Vaccine nào?</label>
                                    
                                    <select 
                                        className="input-field" 
                                        value={targetVaccineForPackage}
                                        onChange={(e) => setTargetVaccineForPackage(e.target.value)}
                                        style={{width: '100%', padding: '8px'}}
                                    >
                                        {filteredVaccines.length > 0 ? (
                                            filteredVaccines.map(v => (
                                                <option key={v.MaVaccine} value={v.MaVaccine}>{v.TenVaccine} - {v.DonGia?.toLocaleString()}đ</option>
                                            ))
                                        ) : (
                                            <option disabled>Không tìm thấy vaccine</option>
                                        )}
                                    </select>
                                </div>

                                <p style={{fontWeight:'bold', marginBottom:'10px'}}>👉 Bước 2: Chọn gói ưu đãi:</p>

                                {packages.map(p => {
                                    // Disable gói nếu vaccine đang trong gói dở
                                    const isDisabled = ongoingPackage && targetVaccineForPackage === ongoingPackage.MaVaccine;
                                    
                                    return (
                                        <div key={p.MaGoi} className="item-card" style={{
                                            border: '1px solid #ddd', 
                                            padding: '10px', 
                                            marginBottom: '10px', 
                                            display:'flex', 
                                            justifyContent:'space-between', 
                                            alignItems:'center',
                                            opacity: isDisabled ? 0.5 : 1
                                        }}>
                                            <div>
                                                <strong>{p.TenGoi}</strong> 
                                                <span style={{fontSize:'12px', background:'#ff9800', marginLeft:'5px', padding:'2px 5px', borderRadius:'4px', color:'white'}}>Giảm {p.GiamGia * 100}%</span>
                                                <p style={{margin:0, fontSize:'13px'}}>({p.SoMuiTuongUng} mũi - Hạn {p.ThoiHan} tháng)</p>
                                                {isDisabled && <p style={{margin:0, fontSize:'12px', color:'red'}}>⚠️ Vaccine này đang trong gói dở</p>}
                                            </div>
                                            <button 
                                                onClick={() => {
                                                    if (isDisabled) {
                                                        return Swal.fire('Lỗi', 'Vaccine này đang trong gói dở! Không thể tạo gói mới.', 'error');
                                                    }
                                                    handleAction('add-package', { MaVaccine: targetVaccineForPackage, MaGoi: p.MaGoi });
                                                }}
                                                disabled={isDisabled}
                                                style={{
                                                    background: isDisabled ? '#ccc' : '#1565c0', 
                                                    color:'white', 
                                                    border:'none', 
                                                    padding:'5px 10px', 
                                                    borderRadius:'4px', 
                                                    cursor: isDisabled ? 'not-allowed' : 'pointer'
                                                }}
                                            >
                                                + Chọn Gói Này
                                            </button>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </div>

                {/* PHẢI: GIỎ HÀNG */}
                <div style={{flex: 1.5, borderLeft: '1px solid #eee', paddingLeft: '20px'}}>
                    <h3 style={{color:'#d35400'}}>Giỏ Vaccine Của Bạn</h3>
                    {selectedItems.length === 0 ? <p style={{color:'#777'}}>Chưa chọn vaccine nào.</p> : (
                        selectedItems.map((item, index) => (
                            <div key={index} style={{background: '#fff3e0', padding:'10px', marginBottom:'10px', borderRadius:'5px', border:'1px solid #ffe0b2'}}>
                                <strong>{item.TenVaccine || 'Vaccine'}</strong>
                                {item.MaGoi ? (
                                    <div style={{color:'#d84315', fontSize:'13px', fontWeight:'bold'}}>📦 {item.TenGoi}</div>
                                ) : item.NhacLai ? (
                                    <div style={{color:'#1976d2', fontSize:'13px', fontWeight:'bold'}}>🔄 Mũi nhắc lại</div>
                                ) : (
                                    <div style={{color:'green', fontSize:'13px'}}>💉 Mũi lẻ</div>
                                )}
                                <div style={{display:'flex', justifyContent:'space-between', marginTop:'5px'}}>
                                    <span style={{fontWeight:'bold'}}>{item.ThanhTien?.toLocaleString()} đ</span>
                                    <button 
                                        onClick={() => item.MaGoi 
                                            ? handleAction('remove-package', { MaVaccine: item.MaVaccine, MaGoi: item.MaGoi }) 
                                            : handleAction('remove-single', { MaVaccine: item.MaVaccine })
                                        }
                                        style={{color:'red', border:'none', background:'none', cursor:'pointer', fontWeight:'bold'}}
                                    >Xóa</button>
                                </div>
                            </div>
                        ))
                    )}
                    
                    {/* 🔥 3. NÚT HOÀN TẤT (GỌI HÀM handleConfirm) */}
                    <button 
                        onClick={handleConfirm} 
                        style={{width:'100%', marginTop:'20px', padding:'15px', background:'#ff6f00', color:'white', border:'none', borderRadius:'5px', fontWeight:'bold', cursor:'pointer', fontSize:'16px'}}
                    >
                        HOÀN TẤT ĐẶT LỊCH
                    </button>
                </div>
            </div>
        </div>
    );
};

export default SelectVaccine;