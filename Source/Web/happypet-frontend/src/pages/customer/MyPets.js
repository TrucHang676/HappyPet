// src/pages/MyPets.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaPencilAlt, FaTimes, FaTrash, FaPlus, FaNotesMedical, FaSyringe, FaStethoscope } from 'react-icons/fa'; 
import './MyPets.css'; 
import Swal from 'sweetalert2'; 

const MyPets = () => {
  const [pets, setPets] = useState([]);
  
  // STATE SỬA
  const [isEditing, setIsEditing] = useState(false);
  const [editFormData, setEditFormData] = useState({
    MaTC: '', Ten: '', Loai: '', Giong: '', NgSinh: '', GioiTinh: '', TinhTrangSucKhoe: ''
  });

  // STATE THÊM MỚI
  const [isAdding, setIsAdding] = useState(false);
  const [addFormData, setAddFormData] = useState({
    Ten: '', Loai: 'Chó', Giong: '', NgSinh: '', GioiTinh: 'Đực', TinhTrangSucKhoe: ''
  });

  // STATE BỆNH ÁN
  const [isHistoryOpen, setIsHistoryOpen] = useState(false); 
  const [medicalData, setMedicalData] = useState({ khamBenh: [], tiemPhong: [] }); 
  const [activeTab, setActiveTab] = useState('kham'); 
  const [selectedPetName, setSelectedPetName] = useState(''); 

  // Hàm lấy danh sách
  const fetchPets = async () => {
    try {
        const token = localStorage.getItem('token');
        const response = await axios.get('https://happy-pet-fomc.onrender.com/api/pets/my-pets', {
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

  const handleAddChange = (e) => {
    setAddFormData({ ...addFormData, [e.target.name]: e.target.value });
  };

  const handleAddSubmit = async (e) => {
    e.preventDefault();
    try {
        const token = localStorage.getItem('token');
        await axios.post('https://happy-pet-fomc.onrender.com/api/pets/add', addFormData, {
            headers: { Authorization: `Bearer ${token}` }
        });
        alert("Thêm thành công! 🎉"); 
        setIsAdding(false); 
        setAddFormData({ Ten: '', Loai: 'Chó', Giong: '', NgSinh: '', GioiTinh: 'Đực', TinhTrangSucKhoe: '' }); 
        fetchPets(); 
    } catch (error) {
        alert("Lỗi khi thêm thú cưng!");
    }
  };

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
            `https://happy-pet-fomc.onrender.com/api/pets/update/${editFormData.MaTC}`, 
            editFormData, 
            { headers: { Authorization: `Bearer ${token}` } }
        );
        alert("Cập nhật thành công!"); 
        setIsEditing(false); 
        fetchPets();
    } catch (error) {
        alert("Lỗi khi cập nhật!");
    }
  };

  const handleDelete = (petId) => {
    Swal.fire({
        title: 'Bạn có chắc chắn muốn xóa không?',
        text: "Hành động này không thể hoàn tác!",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#3085d6',
        confirmButtonText: 'Xóa luôn',
        cancelButtonText: 'Hủy'
    }).then(async (result) => {
        if (result.isConfirmed) {
            try {
                const token = localStorage.getItem('token');
                await axios.delete(`https://happy-pet-fomc.onrender.com/api/pets/delete/${petId}`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                Swal.fire('Đã xóa!', 'Bé đã bị xóa khỏi danh sách.', 'success');
                fetchPets(); 
            } catch (error) {
                Swal.fire('Lỗi!', 'Không thể xóa, thử lại sau nhé.', 'error');
            }
        }
    });
  };

  const handleViewHistory = async (pet) => {
      setSelectedPetName(pet.Ten);
      setActiveTab('kham'); 
      try {
          const token = localStorage.getItem('token');
          const res = await axios.get(`https://happy-pet-fomc.onrender.com/api/pets/history/${pet.MaTC}`, {
              headers: { Authorization: `Bearer ${token}` }
          });
          setMedicalData(res.data); 
          setIsHistoryOpen(true); 
      } catch (error) {
          alert("Lỗi lấy dữ liệu hồ sơ!");
      }
  };

  return (
    <div className="mypets-container">
      <div className="header-section">
          <h2>Danh Sách Thú Cưng Của Tôi</h2>
          <button className="btn-add" onClick={() => setIsAdding(true)}>
             <FaPlus style={{marginRight: '8px'}}/> Thêm Bé Mới
          </button>
      </div>

      <div className="pet-list">
        {pets.length === 0 ? <p className="empty-text">Bạn chưa có thú cưng nào. Thêm ngay nhé!</p> : pets.map((pet) => (
          <div key={pet.MaTC} className="pet-card">
            <div className="card-actions">
                <div className="edit-icon" title="Sửa thông tin" onClick={() => handleEditClick(pet)}><FaPencilAlt /></div>
                <div className="delete-icon" title="Xóa bé" onClick={() => handleDelete(pet.MaTC)}><FaTrash /></div>
            </div>

            <div className="pet-icon">
                {pet.Loai === 'Mèo' ? '🐱' : (pet.Loai === 'Chó' ? '🐶' : (pet.Loai === 'Chim' ? '🐦' : '🐾'))}
            </div>
            
            <div className="pet-info">
                <h3>{pet.Ten}</h3>
                <p><strong>Giống:</strong> {pet.Loai} - {pet.Giong}</p>
                <p><strong>Tuổi: </strong> 
                   {pet.TuoiNam > 0 ? `${pet.TuoiNam} tuổi ` : ''} {pet.TuoiThang} tháng
                </p>
                <p><strong>Ngày sinh:</strong> {pet.NgSinh?.split('T')[0]}</p>
                <p><strong>Giới tính:</strong> <span className="gender-badge">{pet.GioiTinh}</span></p>
                {pet.TinhTrangSucKhoe && <p style={{color: '#e74c3c', fontSize: '0.9em', marginTop: '5px', fontWeight: 'bold'}}>❤️ {pet.TinhTrangSucKhoe}</p>}
            </div>
            
            <button className="btn-detail" onClick={() => handleViewHistory(pet)}>
                <FaNotesMedical /> Xem Hồ Sơ Bệnh Án
            </button>
          </div>
        ))}
      </div>

      {/* MODAL THÊM MỚI */}
      {isAdding && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
                <h3>Thêm Thành Viên Mới 🐶</h3>
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
                <textarea name="TinhTrangSucKhoe" value={addFormData.TinhTrangSucKhoe} onChange={handleAddChange} rows="2" placeholder="Bình thường..."></textarea>
                <div className="modal-actions">
                    <button type="button" className="btn-cancel" onClick={() => setIsAdding(false)}>Hủy</button>
                    <button type="submit" className="btn-save">Thêm Bé</button>
                </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL SỬA */}
      {isEditing && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
                <h3>Cập Nhật Hồ Sơ 📝</h3>
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
                <textarea name="TinhTrangSucKhoe" value={editFormData.TinhTrangSucKhoe} onChange={handleEditChange} rows="3" />
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
          <div className="modal-content modal-lg">
            <div className="modal-header">
                <h3>Hồ Sơ Y Tế: <span style={{color: '#e67e22'}}>{selectedPetName}</span> 🩺</h3>
                <FaTimes className="close-icon" onClick={() => setIsHistoryOpen(false)} />
            </div>

            <div className="tabs-container">
                <button className={`tab-btn ${activeTab === 'kham' ? 'active' : ''}`} onClick={() => setActiveTab('kham')}>
                    <FaStethoscope /> Lịch Sử Khám
                </button>
                <button className={`tab-btn ${activeTab === 'tiem' ? 'active' : ''}`} onClick={() => setActiveTab('tiem')}>
                    <FaSyringe /> Lịch Sử Tiêm
                </button>
            </div>
            
            <div className="history-table-container">
                {activeTab === 'kham' && (
                    medicalData.khamBenh.length === 0 ? <p className="empty-text">Bé khỏe re, chưa đi khám lần nào! 😎</p> :
                    <table className="history-table">
                        <colgroup>
                            <col style={{width: '15%'}} /> 
                            <col style={{width: '25%'}} /> 
                            <col style={{width: '30%'}} /> 
                            <col style={{width: '15%'}} /> 
                            <col style={{width: '15%'}} /> 
                        </colgroup>
                        <thead>
                            <tr>
                                <th>Ngày Khám</th>
                                <th className="text-center">Chẩn đoán</th> {/* Căn giữa tiêu đề */}
                                <th className="text-center">Triệu chứng</th> {/* Căn giữa tiêu đề */}
                                <th>Bác sĩ</th>
                                <th>Chi nhánh</th>
                            </tr>
                        </thead>
                        <tbody>
                            {medicalData.khamBenh.map((item, i) => (
                                <tr key={i}>
                                    <td className="col-date">{item.NgayKham ? new Date(item.NgayKham).toLocaleDateString('vi-VN') : ''}</td>
                                    <td className="text-center"> {/* Căn giữa nội dung */}
                                        <span className="status-bad-cell">{item.ChanDoan}</span>
                                    </td>
                                    <td className="text-muted text-center">{item.TrieuChung}</td> {/* Căn giữa nội dung */}
                                    <td style={{fontWeight: '600'}}>{item.BacSiKham}</td>
                                    <td>{item.NoiKham}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}

                {activeTab === 'tiem' && (
                    medicalData.tiemPhong.length === 0 ? <p className="empty-text">Chưa tiêm mũi nào lun? Đi tiêm ngay đi! 💉</p> :
                    <table className="history-table">
                        <colgroup>
                            <col style={{width: '15%'}} /> 
                            <col style={{width: '30%'}} /> 
                            <col style={{width: '10%'}} /> 
                            <col style={{width: '15%'}} /> 
                            <col style={{width: '30%'}} /> 
                        </colgroup>
                        <thead style={{backgroundColor: '#e8f5e9'}}>
                            <tr>
                                <th style={{color: '#2e7d32'}}>Ngày Tiêm</th>
                                <th className="text-center" style={{color: '#2e7d32'}}>Tên Vaccine</th> {/* Căn giữa tiêu đề */}
                                <th className="text-center" style={{color: '#2e7d32'}}>Liều</th>
                                <th className="text-center" style={{color: '#2e7d32'}}>Nhắc lại</th>
                                <th style={{color: '#2e7d32'}}>Người tiêm</th>
                            </tr>
                        </thead>
                        <tbody>
                            {medicalData.tiemPhong.map((item, i) => (
                                <tr key={i}>
                                    <td className="col-date">{item.NgayTiem ? new Date(item.NgayTiem).toLocaleDateString('vi-VN') : ''}</td>
                                    <td className="text-center"> {/* Căn giữa nội dung */}
                                        <span className="status-good-cell">{item.TenVaccine}</span>
                                    </td>
                                    <td className="text-center">{item.LieuLuong}</td>
                                    <td className="text-center">{item.CanNhacLai}</td>
                                    <td style={{fontWeight: '600'}}>{item.NguoiTiem}</td>
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