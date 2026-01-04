import React, { useState } from 'react';
import axios from 'axios';

const TestAutoHuy = () => {
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);

    const handleAutoHuy = async () => {
        setLoading(true);
        setResult(null);
        try {
            const token = localStorage.getItem('token');
            const res = await axios.post('https://happy-pet-fomc.onrender.com/api/employee/auto-huy-hen', {}, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setResult({
                success: true,
                data: res.data,
                message: `✅ Thành công! Đã hủy ${res.data.soPhieuHuy} phiếu quá hạn`
            });
        } catch (error) {
            setResult({
                success: false,
                error: error.response?.data || error.message,
                message: `❌ Lỗi: ${error.response?.data?.message || error.message}`
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{ padding: '40px', maxWidth: '800px', margin: '0 auto' }}>
            <h1>🔧 Test Tự Động Hủy Lịch Hẹn</h1>
            <p style={{ color: '#666', marginBottom: '20px' }}>
                Hệ thống sẽ tự động hủy các phiếu trạng thái <strong>DD</strong> (Đã đặt) 
                quá giờ hẹn <strong>120 phút</strong>.
            </p>
            
            <button 
                onClick={handleAutoHuy}
                disabled={loading}
                style={{
                    padding: '15px 30px',
                    fontSize: '16px',
                    backgroundColor: loading ? '#ccc' : '#e74c3c',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    fontWeight: '600'
                }}
            >
                {loading ? '⏳ Đang xử lý...' : '🚀 Chạy Tự Động Hủy Ngay'}
            </button>

            {result && (
                <div style={{
                    marginTop: '30px',
                    padding: '20px',
                    backgroundColor: result.success ? '#d4edda' : '#f8d7da',
                    border: `1px solid ${result.success ? '#c3e6cb' : '#f5c6cb'}`,
                    borderRadius: '8px'
                }}>
                    <h3>{result.message}</h3>
                    <pre style={{ 
                        marginTop: '15px', 
                        backgroundColor: '#f8f9fa', 
                        padding: '15px', 
                        borderRadius: '5px',
                        overflow: 'auto'
                    }}>
                        {JSON.stringify(result.success ? result.data : result.error, null, 2)}
                    </pre>
                </div>
            )}

            <div style={{
                marginTop: '40px',
                padding: '20px',
                backgroundColor: '#e8f4f8',
                borderRadius: '8px',
                borderLeft: '4px solid #17a2b8'
            }}>
                <h3>📋 Thông tin:</h3>
                <ul style={{ lineHeight: '1.8' }}>
                    <li>Scheduler chạy tự động mỗi <strong>10 phút</strong></li>
                    <li>Hủy phiếu có: <code>TrangThai = 'DD'</code></li>
                    <li>Điều kiện: <code>TG_ThucHienDV &lt; GETDATE() - 120 phút</code></li>
                    <li>Hành động: Hoàn kho, mở lại gói vaccine, chuyển trạng thái sang <strong>DH</strong></li>
                </ul>
            </div>
        </div>
    );
};

export default TestAutoHuy;
