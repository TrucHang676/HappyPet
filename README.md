# HappyPet - Hệ thống quản lý phòng khám thú y và bán lẻ hàng tiêu dùng

HappyPet là một giải pháp quản lý tích hợp, hỗ trợ vận hành chuỗi phòng khám thú y và các cửa hàng bán lẻ sản phẩm dành cho thú cưng. Hệ thống hỗ trợ xử lý các nghiệp vụ từ đặt lịch hẹn dịch vụ, khám bệnh lâm sàng, tiêm phòng định kỳ, quản lý kho hàng, hóa đơn tại quầy và trực tuyến cho đến chương trình tích lũy điểm thưởng thành viên trên nhiều chi nhánh.

## Tổng quan

Hệ thống HappyPet được thiết kế nhằm giải quyết các bất cập trong quản lý phân mảnh tại các cơ sở thú y và bán lẻ thú cưng:
- **Phân tán dữ liệu y khoa và bán hàng**: Thông thường lịch sử điều trị, thông tin tiêm phòng và dữ liệu hóa đơn mua hàng được lưu trữ rời rạc. HappyPet chuẩn hóa và tập trung toàn bộ dữ liệu này dưới hồ sơ duy nhất của từng khách hàng và thú cưng.
- **Quản lý lịch hẹn thủ công**: Việc đặt lịch hẹn khám bệnh hoặc tiêm phòng dễ dẫn đến tình trạng quá tải hoặc trùng lặp bác sĩ. Hệ thống giải quyết bằng cơ chế đặt lịch động, tự động phân bổ ca trực và tự động thu hồi lịch hẹn quá hạn.
- **Kiểm soát kho hàng phức tạp**: Các chi nhánh cần quản lý kho thuốc y tế, vaccine và các vật phẩm tiêu dùng với hạn sử dụng khác nhau. Hệ thống tự động khấu trừ kho khi có giao dịch phát sinh và đưa ra các cảnh báo tồn kho dưới hạn mức an toàn.
- **Chương trình thành viên thiếu đồng bộ**: Chương trình chăm sóc khách hàng được tích lũy điểm và cập nhật xếp hạng thành viên định kỳ hàng năm một cách tự động, tối ưu hóa các chính sách ưu đãi chiết khấu trực tiếp trên từng hóa đơn.

## Kiến trúc hệ thống và Thiết kế cơ sở dữ liệu

HappyPet được xây dựng trên kiến trúc ba lớp (Three-Tier Architecture) nhằm tách biệt các tầng xử lý và tối ưu hiệu năng:
- **Tầng giao diện (Frontend)**: Xây dựng bằng React, chịu trách nhiệm kết xuất giao diện động và tương tác trực quan cho từng đối tượng người dùng (Khách hàng, Tiếp tân, Bác sĩ thú y, Quản lý chi nhánh, Giám đốc doanh nghiệp).
- **Tầng máy chủ (Backend)**: Triển khai bằng Express (Node.js), cung cấp hệ thống RESTful API bảo mật thông qua xác thực Token và xử lý trung gian (middleware) phân quyền truy cập.
- **Tầng cơ sở dữ liệu (Database)**: Sử dụng Microsoft SQL Server làm hệ quản trị cơ sở dữ liệu quan hệ chính, lưu trữ toàn bộ dữ liệu có cấu trúc và thực thi các logic nghiệp vụ nặng thông qua stored procedures, triggers, views và phân vùng dữ liệu.

Các thách thức kỹ thuật cốt lõi trong hệ quản trị cơ sở dữ liệu đã được xử lý và tối ưu hóa bao gồm:

### Chuẩn hóa dữ liệu và Ràng buộc toàn vẹn
Mô hình dữ liệu gồm 29 bảng được thiết kế tuân thủ các quy tắc chuẩn hóa (lên đến 3NF/BCNF) để triệt tiêu dư thừa dữ liệu và loại bỏ các dị thường khi thêm, xóa, sửa:
- Mối quan hệ giữa thực thể cha USER và các vai trò kế thừa như KHACH_HANG, NHAN_VIEN được thiết lập qua các ràng buộc khóa ngoại chặt chẽ.
- Áp dụng các ràng buộc kiểm tra (CHECK CONSTRAINTS) ngay tại tầng cơ sở dữ liệu đối với các thuộc tính nhạy cảm như định dạng số điện thoại, định dạng email, hạn mức tiền lương, tính hợp lệ của ngày sinh, và định dạng mã căn cước công dân (CCCD).

### Kiểm soát đồng thời và Quản lý giao dịch (ACID)
Để đảm bảo tính nhất quán dữ liệu khi xảy ra các truy cập đồng thời, toàn bộ các thao tác ghi dữ liệu phức tạp được bao bọc trong các giao dịch (TRANSACTION) với cơ chế kiểm soát lỗi nghiêm ngặt:
- **Logic Đặt lịch hẹn và Hủy lịch hẹn**: Trong thủ tục sp_HuyLichHen, hệ thống kiểm tra trạng thái phiếu hẹn trước khi cho phép hủy (chỉ hủy các phiếu ở trạng thái Đã Đặt DD và thời gian hủy phải trước giờ hẹn ít nhất 2 giờ). Giao dịch đảm bảo an toàn bằng cách rollback (ROLLBACK TRANSACTION) nếu bất kỳ điều kiện ràng buộc nào bị vi phạm. Khi hệ thống tự động quét hủy lịch hẹn quá hạn (sp_TuDongHuyLichHen), thủ tục sử dụng cấu trúc con trỏ (CURSOR) để cô lập và cam kết giao dịch trên từng phiếu đơn lẻ, giảm thiểu thời gian chiếm giữ khóa trên bảng dữ liệu lớn PHIEU_DICH_VU, hạn chế tình trạng nghẽn cổ chai (blocking) và khóa chết (deadlock).
- **Quy trình Khám bệnh và Kê đơn**: Thủ tục sp_BacSi_KetThucKham tự động tính toán tổng chi phí thuốc thực tế trong bảng chi tiết đơn thuốc CT_DON_THUOC và cập nhật trực tiếp vào hóa đơn trực tiếp HD_TRUC_TIEP tương ứng trong cùng một phạm vi giao dịch nguyên tố (atomic transaction).

### Phân vùng dữ liệu (Partitioning)
Để duy trì tốc độ truy vấn ổn định khi lượng dữ liệu tích lũy qua nhiều năm tăng lên nhanh chóng, bảng xếp hạng thành viên hàng năm (XEP_HANG_NAM) được phân vùng ngang (Horizontal Partitioning):
- **Partition Function**: Khai báo PF_Xep_Hang_Nam phân tách dữ liệu kiểu INT của cột năm thành các dải giá trị riêng biệt bằng phương pháp tiệm cận phải (RANGE RIGHT) cho các năm (2023, 2024, 2025, 2026).
- **Partition Scheme**: Khai báo PS_Xep_Hang_Nam ánh xạ các phân vùng này vào nhóm tệp lưu trữ mặc định. Cơ chế này cô lập hoàn toàn các truy vấn phân tích doanh thu và xếp hạng theo năm cũ, giảm thiểu dung lượng bộ nhớ cần quét khi cập nhật dữ liệu của năm hiện tại.

### Chiến lược lập chỉ mục (Indexing)
Hệ thống triển khai các chỉ mục phi cụm (Non-Clustered Indexes) kết hợp với từ khóa INCLUDE để tối ưu hóa kế hoạch thực thi truy vấn (Execution Plan) và giảm số lượng đọc logic (Logical Reads):
- IX_PHIEU_KHAM_BENH_NgayHen_T1 trên trường [NgayHenTaiKham] chứa thêm (INCLUDE) các trường [MaTC] và [ChanDoan] phục vụ truy vấn tra cứu danh sách thú cưng đến lịch hẹn tái khám của chi nhánh mà không cần truy cập lại bảng dữ liệu gốc (Key Lookup).
- IX_PHIEU_DICH_VU_MaCN_Ngay_T3 trên tập thuộc tính khóa phức hợp ([MaCN], [TG_ThucHienDV]) đính kèm thông tin trạng thái, loại phiếu, mã nhân viên, mã khách hàng, tăng tốc độ kết xuất báo cáo lịch trình phục vụ trong ngày của từng chi nhánh.
- IX_MAT_HANG_LoaiMH_T2 trên trường loại mặt hàng [LoaiMH] phục vụ bộ lọc tìm kiếm danh mục sản phẩm theo chi nhánh.
- IX_PHIEU_KHAM_BENH_MaTC_T7 và IX_PHIEU_TIEM_VACCINE_MaTC_T8 hỗ trợ tối đa hiệu năng cho tính năng hiển thị toàn bộ lịch sử bệnh án lâm sàng và lịch sử tiêm chủng của một thú cưng cụ thể.

### Bảo mật và Toàn vẹn dữ liệu bằng Triggers
Định nghĩa các trigger kiểm tra mức hàng (AFTER INSERT, UPDATE, DELETE) để thực thi chính sách bảo mật khóa dữ liệu (data freezing):
- Các trigger trg_KhoaPhieuDaHoanTat_CT_MuaHang, trg_KhoaPhieuDaHoanTat_CT_TiemVC, trg_KhoaPhieuDaHoanTat_DangKiGoi, trg_KhoaPhieuDaHoanTat_CT_DonThuoc và trg_KhoaPhieuDaHoanTat_ThongTinKham giám sát chặt chẽ trạng thái của phiếu dịch vụ liên đới.
- Khi một phiếu dịch vụ chuyển sang trạng thái Đã Hoàn Thành (DHT) hoặc Đã Hủy (DH), mọi hành vi cố ý cập nhật hoặc xóa bỏ chi tiết đơn hàng, đơn thuốc, liều lượng vaccine hay chẩn đoán lâm sàng đều bị chặn đứng và hoàn tác giao dịch lập tức thông qua hàm RAISERROR. Cơ chế này loại bỏ hoàn toàn khả năng gian lận tài chính hoặc sửa đổi lịch sử bệnh án sau khi quy trình chuyên môn đã kết thúc.

## Các tính năng chính

Hệ thống cung cấp đầy đủ các phân hệ nghiệp vụ bao gồm:
- **Đặt lịch hẹn trực tuyến**: Khách hàng chủ động chọn chi nhánh, loại dịch vụ (khám bệnh, tiêm chủng), chọn bác sĩ phụ trách và khung giờ trống. Hệ thống tự động kiểm tra và khóa ca hẹn trùng lặp.
- **Hồ sơ bệnh án và Kê đơn**: Hỗ trợ bác sĩ thú y ghi nhận triệu chứng lâm sàng, chẩn đoán bệnh án, thiết lập lịch hẹn tái khám và kê đơn thuốc trực tiếp từ kho y tế.
- **Tiêm chủng định kỳ theo gói**: Quản lý các gói tiêm vaccine dài hạn của thú cưng, theo dõi thời hạn hiệu lực, nhắc lịch tiêm các mũi tiếp theo và hỗ trợ đăng ký vaccine lẻ linh hoạt.
- **Quản lý bán lẻ và Kho tồn**: Theo dõi lượng tồn kho thực tế của các loại thuốc, vaccine và phụ kiện thú cưng tại từng chi nhánh. Hệ thống tự động cảnh báo khi hàng hóa chạm mức tối thiểu để kịp thời nhập kho.
- **Tích điểm và Phân hạng hội viên**: Tự động tính điểm tích lũy từ các hóa đơn trực tiếp và trực tuyến. Quy đổi hạng thành viên (như Bạc, Vàng, Kim Cương) hàng năm để tự động giảm giá chiết khấu khi xuất hóa đơn mới.
- **Báo cáo doanh thu**: Phân hệ quản trị dành cho Giám đốc và Quản lý chi nhánh kết xuất báo cáo doanh thu theo tháng, theo loại dịch vụ và thống kê hiệu suất làm việc của đội ngũ nhân sự.

## Công nghệ sử dụng

### Giao diện người dùng
- React (phiên bản 19.x) làm nền tảng xây dựng ứng dụng Single Page Application (SPA).
- React Router DOM quản lý luồng điều hướng và phân quyền định tuyến phía client.
- Axios xử lý truyền nhận dữ liệu phi đồng bộ thông qua HTTP/HTTPS RESTful APIs.
- SweetAlert2 và React Toastify tối ưu hóa trải nghiệm tương tác thông báo trạng thái.
- CSS thuần (Vanilla CSS) cấu trúc kiểu dáng cho toàn bộ hệ thống.

### Máy chủ
- Node.js và Express framework xử lý luồng yêu cầu hệ thống.
- mssql client kết nối và thực hiện truy vấn trực tiếp đến SQL Server.
- JSON Web Tokens (JWT) thực hiện cơ chế xác thực và duy trì phiên đăng nhập bảo mật.
- Bcryptjs mã hóa một chiều mật khẩu tài khoản người dùng trước khi lưu trữ.

### Cơ sở dữ liệu
- Microsoft SQL Server (MSSQL) đóng vai trò hệ quản trị cơ sở dữ liệu quan hệ, xử lý thủ tục lưu trữ, hàm phân vùng, chỉ mục tối ưu hiệu năng và trigger kiểm soát toàn vẹn dữ liệu.

## Hướng dẫn bắt đầu / Cài đặt

### Yêu cầu hệ thống
- Node.js (phiên bản 18.x trở lên)
- npm (phiên bản 9.x trở lên)
- Microsoft SQL Server 2019 hoặc mới hơn

### Thiết lập Cơ sở dữ liệu
1. Mở SQL Server Management Studio (SSMS) và kết nối vào instance SQL Server của bạn.
2. Thực thi tệp lệnh khởi tạo cơ sở dữ liệu và bảng tại:
   Source/Database/CreateDatabase/CreateDatabase.sql
3. Lần lượt thực thi các tệp lệnh chức năng theo thứ tự:
   - Các Trigger tại Source/Database/Trigger/Triggers.sql
   - Phân vùng dữ liệu tại Source/Database/Partition/partition.sql
   - Chỉ mục tại Source/Database/Index/index.sql
   - Các Thủ tục lưu trữ tại thư mục Source/Database/Store Procedure/ (chạy lần lượt các tệp hoặc tệp tổng hợp TONG_HOP_CAC_SP.sql)
4. Nạp dữ liệu mẫu bằng cách chạy các tập lệnh trong thư mục Source/Database/GeneratingData/ bắt đầu bằng tệp Master_GenData.sql.

### Cấu hình và Khởi chạy Máy chủ Backend
1. Di chuyển vào thư mục backend:
   cd Source/Web/happypet-backend
2. Tạo tệp .env cấu hình các thông số kết nối:
   ```env
   PORT=5000
   DB_USER=your_db_username
   DB_PASS=your_db_password
   DB_SERVER=your_db_server_address
   DB_NAME=HAPPYPET
   DB_PORT=1433
   JWT_SECRET=your_jwt_secret_key
   ```
3. Cài đặt các gói phụ thuộc và khởi chạy máy chủ phát triển:
   ```bash
   npm install
   npm run dev
   ```

### Cấu hình và Khởi chạy Giao diện Frontend
1. Di chuyển vào thư mục frontend:
   cd Source/Web/happypet-frontend
2. Tạo tệp .env định nghĩa địa chỉ API:
   ```env
   REACT_APP_API_URL=http://localhost:5000/api
   ```
3. Cài đặt thư viện và chạy ứng dụng:
   ```bash
   npm install
   npm start
   ```
