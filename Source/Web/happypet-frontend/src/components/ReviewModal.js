import React, { useState } from 'react';
import './ReviewModal.css'; // Bà tự style css đơn giản nha (position fixed, center...)

const ReviewModal = ({ type, data, onClose, onSubmit }) => {
    // type: 'SERVICE' hoặc 'PRODUCT'
    // data: Chứa MaPhieu, và MaMatHang (nếu là product)
    
    const [ratings, setRatings] = useState({
        chatLuong: 5,
        thaiDo: 5,   // Chỉ dùng cho Service
        tongThe: 5   // Chỉ dùng cho Service
    });
    const [comment, setComment] = useState('');

    const handleSubmit = () => {
        // Gửi dữ liệu ra ngoài cho cha xử lý
        onSubmit({
            ...data,
            DiemChatLuong: ratings.chatLuong,
            DiemThaiDo: type === 'SERVICE' ? ratings.thaiDo : 0,
            DiemTongThe: type === 'SERVICE' ? ratings.tongThe : 0,
            BinhLuan: comment
        });
    };

    const renderStars = (key, label) => (
        <div className="star-row">
            <span>{label}:</span>
            <div className="stars">
                {[1, 2, 3, 4, 5].map(star => (
                    <span key={star} 
                          className={star <= ratings[key] ? 'star filled' : 'star'}
                          onClick={() => setRatings({...ratings, [key]: star})}>
                        ★
                    </span>
                ))}
            </div>
        </div>
    );

    return (
        <div className="modal-overlay">
            <div className="modal-content">
                <h3>{type === 'SERVICE' ? 'Đánh Giá Dịch Vụ' : 'Đánh Giá Sản Phẩm'}</h3>
                
                {renderStars('chatLuong', 'Chất lượng')}
                
                {type === 'SERVICE' && (
                    <>
                        {renderStars('thaiDo', 'Thái độ NV')}
                        {renderStars('tongThe', 'Tổng thể')}
                    </>
                )}

                <textarea 
                    placeholder="Viết cảm nhận của bạn..." 
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                />
                
                <div className="modal-actions">
                    <button onClick={onClose}>Đóng</button>
                    <button className="btn-submit" onClick={handleSubmit}>Gửi Đánh Giá</button>
                </div>
            </div>
        </div>
    );
};

export default ReviewModal;