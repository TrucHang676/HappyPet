import React, { useState, useEffect } from 'react';
import axios from 'axios';
import dayjs from 'dayjs';
import isBetween from 'dayjs/plugin/isBetween';
import './History.css';

dayjs.extend(isBetween);

const RecheckReminder = () => {
    const [reminders, setReminders] = useState([]);
    const [timeTab, setTimeTab] = useState('today');
    const [loading, setLoading] = useState(true);

    const getDateRange = (tab) => {
        const today = dayjs();
        let start, end;

        switch (tab) {
            case 'today':
                start = today;
                end = today;
                break;
            case 'next3':
                start = today;
                end = today.add(2, 'day');
                break;
            case 'week':
                start = today;
                end = today.add(6, 'day');
                break;
            default:
                start = today;
                end = today;
        }

        return { start, end };
    };

    useEffect(() => {
        const fetchReminders = async () => {
            setLoading(true);
            try {
                const token = localStorage.getItem('token');
                const res = await axios.get('https://happy-pet-fomc.onrender.com/api/orders/history', {
                    headers: { Authorization: `Bearer ${token}` }
                });

                const { start, end } = getDateRange(timeTab);

                // Lọc các phiếu dịch vụ đã hoàn thành và có ngày tái khám
                const filtered = res.data.filter(item => {
                    if (!item.NgayHenTaiKham) return false;
                    if (item.LoaiPhieu === 'MH') return false; // Chỉ lấy dịch vụ
                    if (!['HT', 'DHT'].includes(item.TrangThai)) return false; // Chỉ lấy hoàn thành

                    const recheckDate = dayjs(item.NgayHenTaiKham);
                    return recheckDate.isBetween(start, end, 'day', '[]');
                });

                setReminders(filtered);
            } catch (error) {
                console.error('Lỗi:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchReminders();
    }, [timeTab]);

    return (
        <div style={{ padding: '30px', maxWidth: '1000px', margin: '0 auto' }}>
            <h2 style={{ textAlign: 'center', marginBottom: '30px', color: '#333' }}>
                🔔 Nhắc Nhở Tái Khám
            </h2>

            {/* Tabs thời gian */}
            <div style={{ display: 'flex', justifyContent: 'center', gap: '15px', marginBottom: '30px' }}>
                <button 
                    onClick={() => setTimeTab('today')}
                    style={{
                        padding: '10px 25px',
                        border: timeTab === 'today' ? '2px solid #e67e22' : '1px solid #ddd',
                        background: timeTab === 'today' ? '#fff3e0' : 'white',
                        color: timeTab === 'today' ? '#e67e22' : '#666',
                        borderRadius: '25px',
                        cursor: 'pointer',
                        fontWeight: timeTab === 'today' ? 'bold' : 'normal'
                    }}
                >
                    📅 Hôm nay
                </button>
                <button 
                    onClick={() => setTimeTab('next3')}
                    style={{
                        padding: '10px 25px',
                        border: timeTab === 'next3' ? '2px solid #e67e22' : '1px solid #ddd',
                        background: timeTab === 'next3' ? '#fff3e0' : 'white',
                        color: timeTab === 'next3' ? '#e67e22' : '#666',
                        borderRadius: '25px',
                        cursor: 'pointer',
                        fontWeight: timeTab === 'next3' ? 'bold' : 'normal'
                    }}
                >
                    🗓️ 3 ngày tới
                </button>
                <button 
                    onClick={() => setTimeTab('week')}
                    style={{
                        padding: '10px 25px',
                        border: timeTab === 'week' ? '2px solid #e67e22' : '1px solid #ddd',
                        background: timeTab === 'week' ? '#fff3e0' : 'white',
                        color: timeTab === 'week' ? '#e67e22' : '#666',
                        borderRadius: '25px',
                        cursor: 'pointer',
                        fontWeight: timeTab === 'week' ? 'bold' : 'normal'
                    }}
                >
                    📆 Tuần tới
                </button>
            </div>

            {/* Danh sách nhắc nhở */}
            {loading ? (
                <div style={{ textAlign: 'center', padding: '50px', color: '#999' }}>⏳ Đang tải...</div>
            ) : reminders.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '50px', color: '#999' }}>
                    <div style={{ fontSize: '50px', marginBottom: '15px' }}>🎉</div>
                    <div>Không có lịch tái khám nào trong thời gian này!</div>
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                    {reminders.map((item, index) => {
                        const recheckDate = dayjs(item.NgayHenTaiKham);
                        const daysUntil = recheckDate.diff(dayjs(), 'day');
                        const isToday = daysUntil === 0;
                        const isUrgent = daysUntil <= 1;

                        return (
                            <div 
                                key={index}
                                style={{
                                    border: `2px solid ${isUrgent ? '#e74c3c' : '#3498db'}`,
                                    borderRadius: '12px',
                                    padding: '20px',
                                    backgroundColor: isUrgent ? '#fee' : '#f8f9fa',
                                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
                                }}
                            >
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <div style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '8px' }}>
                                            🏥 Phiếu #{item.MaPhieu}
                                        </div>
                                        <div style={{ fontSize: '14px', color: '#666', marginBottom: '5px' }}>
                                            📅 Ngày khám: {dayjs(item.TG_LapPhieu).format('DD/MM/YYYY')}
                                        </div>
                                        {item.TrieuChung && (
                                            <div style={{ fontSize: '13px', color: '#888' }}>
                                                🩺 Triệu chứng: {item.TrieuChung}
                                            </div>
                                        )}
                                        {item.ChanDoan && (
                                            <div style={{ fontSize: '13px', color: '#888' }}>
                                                💊 Chẩn đoán: {item.ChanDoan}
                                            </div>
                                        )}
                                    </div>
                                    <div style={{ textAlign: 'right' }}>
                                        <div style={{ 
                                            fontSize: '24px', 
                                            fontWeight: 'bold', 
                                            color: isUrgent ? '#e74c3c' : '#3498db',
                                            marginBottom: '5px'
                                        }}>
                                            {recheckDate.format('DD/MM/YYYY')}
                                        </div>
                                        <div style={{ 
                                            fontSize: '14px', 
                                            color: isToday ? '#e74c3c' : '#666',
                                            fontWeight: isToday ? 'bold' : 'normal'
                                        }}>
                                            {isToday ? '⚠️ HÔM NAY!' : daysUntil === 1 ? '⚠️ NGÀY MAI!' : `Còn ${daysUntil} ngày`}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default RecheckReminder;
