// src/pages/MyPets.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaPencilAlt, FaTimes, FaTrash, FaPlus, FaNotesMedical, FaSyringe, FaStethoscope } from 'react-icons/fa'; 
import './MyPets.css'; 
import Swal from 'sweetalert2'; // Đã import sẵn

const MyPets = () => {
  const [pets, setPets] = useState([]);
  
  // --- STATE SỬA (Edit) ---
  const [isEditing, setIsEditing] = useState(false);
  const [editFormData, setEditFormData] = useState({
    MaTC: '', Ten: '', Loai: '', Giong: '', NgSinh: '', GioiTinh: '', TinhTrangSucKhoe: ''
  });

  // --- STATE THÊM MỚI (Add) ---
  const [isAdding, setIsAdding] = useState(false);
  const [addFormData, setAddFormData] = useState({
    Ten: '', Loai: 'Chó', Giong: '', NgSinh: '', GioiTinh: 'Đực', TinhTrangSucKhoe: ''
  });

  // --- STATE CHO BỆNH ÁN ---
  const [isHistoryOpen, setIsHistoryOpen] = useState(false); 
  const [medicalData, setMedicalData] = useState({ khamBenh: [], tiemPhong: [] }); 
  const [activeTab, setActiveTab] = useState('kham'); 
  const [selectedPetName, setSelectedPetName] = useState(''); 

  // Hàm lấy danh sách
  const fetchPets = async () => {
    try {
        const token = localStorage.getItem('token');
        const response = await axios.get('http://localhost:5000/api/pets/my-pets', {
            headers: { Authorization: `Bearer ${token}` }
        });
        setPets(response.data); 
    } catch (error) {
        console.error("Lỗi lấy danh sách:", error);
    }
  };

  useEffect(() => {
    fetchPets();
  }, []);

  // --- XỬ LÝ FORM THÊM MỚI ---
  const handleAddChange = (e) => {
    setAddFormData({ ...addFormData, [e.target.name]: e.target.value });
  };

  const handleAddSubmit = async (e) => {
    e.preventDefault();
    try {
        const token = localStorage.getItem('token');
        await axios.post('http://localhost:5000/api/pets/add', addFormData, {
            headers: { Authorization: `Bearer ${token}` }
        });

        alert("Thêm thành công! 🎉"); // Giữ nguyên alert cũ theo ý bà
        setIsAdding(false); 
        setAddFormData({ Ten: '', Loai: 'Chó', Giong: '', NgSinh: '', GioiTinh: 'Đực', TinhTrangSucKhoe: '' }); 
        fetchPets(); 

    } catch (error) {
        console.error(error);
        alert("Lỗi khi thêm thú cưng!");
    }
  };

  // --- XỬ LÝ FORM SỬA ---
  const handleEditClick = (pet) => {
    setIsEditing(true);
    const formattedDate = pet.NgSinh ? pet.NgSinh.toString().split('T')[0] : '';
    setEditFormData({
        MaTC: pet.MaTC,
        Ten: pet.Ten,
        Loai: pet.Loai,
        Giong: pet.Giong,
        NgSinh: formattedDate,
        GioiTinh: pet.GioiTinh,
        TinhTrangSucKhoe: pet.TinhTrangSucKhoe || ''
    });
  };

  const handleEditChange = (e) => {
      setEditFormData({ ...editFormData, [e.target.name]: e.target.value });
  };

  const handleSaveUpdate = async (e) => {
    e.preventDefault();
    try {
        const token = localStorage.getItem('token');
        await axios.put(
            `http://localhost:5000/api/pets/update/${editFormData.MaTC}`, 
            editFormData, 
            { headers: { Authorization: `Bearer ${token}` } }
        );
        alert("Cập nhật thành công!"); // Giữ nguyên alert cũ
        setIsEditing(false); 
        fetchPets();
    } catch (error) {
        alert("Lỗi khi cập nhật!");
    }
  };


  // --- 🔥 SỬA ĐOẠN NÀY: DÙNG SWEETALERT2 CHO XÓA 🔥 ---
  const handleDelete = (petId) => {
    Swal.fire({
        title: 'Bạn có chắc chắn muốn xóa hay không?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#3085d6',
        confirmButtonText: 'Xóa',
        cancelButtonText: 'Hủy'
    }).then(async (result) => {
        if (result.isConfirmed) {
            try {
                const token = localStorage.getItem('token');
                await axios.delete(`http://localhost:5000/api/pets/delete/${petId}`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                
                // Hiện thông báo xóa thành công đẹp
                Swal.fire(
                    'Đã xóa!',
                    'Bé đã bị xóa khỏi danh sách.',
                    'success'
                );
                fetchPets(); 
            } catch (error) {
                Swal.fire('Lỗi!', 'Không thể xóa, thử lại sau nhé.', 'error');
            }
        }
    });
  };

  // --- HÀM GỌI API XEM HỒ SƠ ---
  const handleViewHistory = async (pet) => {
      setSelectedPetName(pet.Ten);
      setActiveTab('kham'); 
      try {
          const token = localStorage.getItem('token');
          const res = await axios.get(`http://localhost:5000/api/pets/history/${pet.MaTC}`, {
              headers: { Authorization: `Bearer ${token}` }
          });
          setMedicalData(res.data); 
          setIsHistoryOpen(true); 
      } catch (error) {
          alert("Không thể lấy dữ liệu hồ sơ! (Kiểm tra lại Backend)");
      }
  };

  return (
    <div className="mypets-container">
      <div className="header-section">
          <h2>Danh Sách Thú Cưng Của Tôi</h2>
          <button className="btn-add" onClick={() => setIsAdding(true)}>
             <FaPlus style={{marginRight: '5px'}}/> Thêm Thú Cưng
          </button>
      </div>

      {/* DANH SÁCH THẺ PET */}
      <div className="pet-list">
        {pets.length === 0 ? <p>Bạn chưa có thú cưng nào.</p> : pets.map((pet) => (
          <div key={pet.MaTC} className="pet-card">
            <div className="edit-icon" onClick={() => handleEditClick(pet)}><FaPencilAlt /></div>
            <div className="delete-icon" onClick={() => handleDelete(pet.MaTC)}><FaTrash /></div>

            <div className="pet-icon">
                {pet.Loai === 'Mèo' ? '🐱' : (pet.Loai === 'Chó' ? '🐶' : '🐾')}
            </div>
            <div className="pet-info">
                <h3>{pet.Ten}</h3>
                <p><strong>Loài:</strong> {pet.Loai}</p>
                <p><strong>Giống:</strong> {pet.Giong}</p>
                <p><strong>Tuổi: </strong> 
                   {pet.TuoiNam > 0 ? `${pet.TuoiNam} tuổi ` : ''} {pet.TuoiThang} tháng
                </p>
                <p><strong>Ngày sinh:</strong> {pet.NgSinh?.split('T')[0]}</p>
                <p><strong>Giới tính:</strong> <span className="gender-badge">{pet.GioiTinh}</span></p>
                {pet.TinhTrangSucKhoe && <p style={{color: 'red', fontSize: '0.9em'}}>Status: {pet.TinhTrangSucKhoe}</p>}
            </div>
            
            <button className="btn-detail" onClick={() => handleViewHistory(pet)}>
                <FaNotesMedical style={{marginRight: '5px'}}/> Xem hồ sơ
            </button>
          </div>
        ))}
      </div>

      {/* --- MODAL THÊM MỚI --- */}
      {isAdding && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
                <h3>Thêm Thành Viên Mới 🐾</h3>
                <FaTimes className="close-icon" onClick={() => setIsAdding(false)} />
            </div>
            <form onSubmit={handleAddSubmit}>
                <label>Tên bé:</label>
                <input type="text" name="Ten" value={addFormData.Ten} onChange={handleAddChange} required placeholder="Ví dụ: Milu" />

                <div className="row-2-col">
                    <div>
                        <label>Loài:</label>
                        <select name="Loai" value={addFormData.Loai} onChange={handleAddChange}>
                            <option value="Chó">Chó</option>
                            <option value="Mèo">Mèo</option>
                            <option value="Chim">Chim</option>
                            <option value="Gà">Gà</option>
                            <option value="Chuột">Chuột</option>
                            <option value="Khác">Khác</option>
                        </select>
                    </div>
                    <div>
                        <label>Giống:</label>
                        <input type="text" name="Giong" value={addFormData.Giong} onChange={handleAddChange} placeholder="Vd: Poodle"/>
                    </div>
                </div>

                <div className="row-2-col">
                    <div>
                        <label>Ngày sinh:</label>
                        <input type="date" name="NgSinh" value={addFormData.NgSinh} onChange={handleAddChange} required />
                    </div>
                    <div>
                        <label>Giới tính:</label>
                        <select name="GioiTinh" value={addFormData.GioiTinh} onChange={handleAddChange}>
                            <option value="Đực">Đực</option>
                            <option value="Cái">Cái</option>
                        </select>
                    </div>
                </div>

                <label>Tình trạng sức khỏe:</label>
                <textarea name="TinhTrangSucKhoe" value={addFormData.TinhTrangSucKhoe} onChange={handleAddChange} rows="2" style={{width: '100%'}} placeholder="Bình thường..."></textarea>

                <div className="modal-actions">
                    <button type="button" className="btn-cancel" onClick={() => setIsAdding(false)}>Hủy</button>
                    <button type="submit" className="btn-save">Thêm Bé</button>
                </div>
            </form>
          </div>
        </div>
      )}

      {/* --- MODAL SỬA --- */}
      {isEditing && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
                <h3>Cập Nhật Hồ Sơ</h3>
                <FaTimes className="close-icon" onClick={() => setIsEditing(false)} />
            </div>
            <form onSubmit={handleSaveUpdate}>
                <label>Tên bé:</label>
                <input type="text" name="Ten" value={editFormData.Ten} onChange={handleEditChange} required />

                <div className="row-2-col">
                    <div>
                        <label>Loài:</label>
                        <select name="Loai" value={editFormData.Loai} onChange={handleEditChange}>
                            <option value="Chó">Chó</option>
                            <option value="Mèo">Mèo</option>
                            <option value="Chim">Chim</option>
                            <option value="Gà">Gà</option>
                            <option value="Chuột">Chuột</option>
                            <option value="Khác">Khác</option>
                        </select>
                    </div>
                    <div>
                        <label>Giống:</label>
                        <input type="text" name="Giong" value={editFormData.Giong} onChange={handleEditChange} />
                    </div>
                </div>

                <div className="row-2-col">
                    <div>
                        <label>Ngày sinh:</label>
                        <input type="date" name="NgSinh" value={editFormData.NgSinh} onChange={handleEditChange} />
                    </div>
                    <div>
                        <label>Giới tính:</label>
                        <select name="GioiTinh" value={editFormData.GioiTinh} onChange={handleEditChange}>
                            <option value="Đực">Đực</option>
                            <option value="Cái">Cái</option>
                        </select>
                    </div>
                </div>

                <label>Tình trạng sức khỏe:</label>
                <textarea name="TinhTrangSucKhoe" value={editFormData.TinhTrangSucKhoe} onChange={handleEditChange} rows="3" style={{width: '100%'}} />

                <div className="modal-actions">
                    <button type="button" className="btn-cancel" onClick={() => setIsEditing(false)}>Hủy</button>
                    <button type="submit" className="btn-save">Lưu Thay Đổi</button>
                </div>
            </form>
          </div>
        </div>
      )}

      {/* --- MODAL XEM HỒ SƠ --- */}
      {isHistoryOpen && (
        <div className="modal-overlay">
          <div className="modal-content" style={{maxWidth: '800px'}}>
            <div className="modal-header">
                <h3>Hồ Sơ Y Tế: {selectedPetName} 🩺</h3>
                <FaTimes className="close-icon" onClick={() => setIsHistoryOpen(false)} />
            </div>

            <div className="tabs-container">
                <button className={`tab-btn ${activeTab === 'kham' ? 'active' : ''}`} onClick={() => setActiveTab('kham')}>
                    <FaStethoscope /> Lịch Sử Khám Bệnh
                </button>
                <button className={`tab-btn ${activeTab === 'tiem' ? 'active' : ''}`} onClick={() => setActiveTab('tiem')}>
                    <FaSyringe /> Lịch Sử Tiêm Phòng
                </button>
            </div>
            
            <div className="history-table-container">
                {activeTab === 'kham' && (
                    medicalData.khamBenh.length === 0 ? <p className="empty-text">Chưa có lịch sử khám.</p> :
                    <table className="history-table">
                        <thead><tr><th>Ngày</th><th>Chẩn đoán</th><th>Triệu chứng</th><th>Bác sĩ</th><th>Nơi khám</th></tr></thead>
                        <tbody>
                            {medicalData.khamBenh.map((item, i) => (
                                <tr key={i}>
                                    <td>{item.NgayKham ? new Date(item.NgayKham).toLocaleDateString('vi-VN') : ''}</td>
                                    <td style={{color:'#d32f2f', fontWeight:'bold'}}>{item.ChanDoan}</td>
                                    <td>{item.TrieuChung}</td>
                                    <td>{item.BacSiKham}</td>
                                    <td>{item.NoiKham}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}

                {activeTab === 'tiem' && (
                    medicalData.tiemPhong.length === 0 ? <p className="empty-text">Chưa có lịch sử tiêm.</p> :
                    <table className="history-table">
                        <thead><tr><th>Ngày</th><th>Vaccine</th><th>Liều</th><th>Nhắc lại</th><th>Người tiêm</th></tr></thead>
                        <tbody>
                            {medicalData.tiemPhong.map((item, i) => (
                                <tr key={i}>
                                    <td>{item.NgayTiem ? new Date(item.NgayTiem).toLocaleDateString('vi-VN') : ''}</td>
                                    <td style={{color:'#28a745', fontWeight:'bold'}}>{item.TenVaccine}</td>
                                    <td>{item.LieuLuong}</td>
                                    <td>{item.CanNhacLai}</td>
                                    <td>{item.NguoiTiem}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MyPets;