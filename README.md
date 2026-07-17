# 🇻🇳 Marvel Travel - Ứng Dụng Hỗ Trợ Khám Phá Và Lập Lịch Trình Du Lịch Việt Nam

## 📌 Giới thiệu dự án
**Marvel Travel** là một hệ sinh thái công nghệ hoàn chỉnh được xây dựng theo mô hình Client-Server hiện đại, bao gồm ứng dụng di động đa nền tảng kết hợp với hệ thống dịch vụ hậu tầng (Backend API)[cite: 4]. 

Hệ thống được phát triển nhằm giải quyết bài toán phân tán thông tin du lịch hiện nay, cung cấp cho du khách một giải pháp tổng thể để **tìm kiếm địa danh, khám phá bản đồ số trực quan, tự động lập lịch trình du lịch thông minh theo ngày** và tham gia tương tác, chia sẻ trải nghiệm thực tế với cộng đồng yêu du lịch tại Việt Nam[cite: 4].

## 🛠 Công nghệ sử dụng
- **Ứng dụng di động (Frontend Mobile):** Flutter Framework / Ngôn ngữ Dart / VS Code hoặc Android Studio[cite: 4]
- **Quản lý trạng thái (State Management):** Provider State Management[cite: 4]
- **Bản đồ số tích hợp:** OpenStreetMap kết hợp thư viện Flutter Map (Hỗ trợ định vị GPS)[cite: 4]
- **Hệ thống dịch vụ (Backend Web API):** ASP.NET Core Web API (.NET 6.0 / .NET 8.0) / Ngôn ngữ C# / Visual Studio[cite: 4]
- **Tương tác Cơ sở dữ liệu:** Entity Framework Core (EF Core)[cite: 4]
- **Cơ sở dữ liệu (Database):** Microsoft SQL Server[cite: 4]
- **Xác thực bảo mật:** JWT Authentication (JSON Web Token) kết hợp phân quyền hệ thống dựa trên vai trò RBAC (Admin, Moderator, User, Guest)[cite: 4]

## ⚡ Các chức năng chính (Phân chia theo cấu trúc Đồ án)

### 1. Ứng dụng di động (Client Flutter)
- **Trang chủ & Khám phá hấp dẫn:** Hiển thị banner quảng bá danh lam thắng cảnh, danh sách các điểm đến hấp dẫn được đề xuất và tích hợp cẩm nang du lịch Việt Nam[cite: 4].
- **Bản đồ số thông minh (Tích hợp GPS):** Hiển thị các địa điểm du lịch dưới dạng Marker trực quan trên nền bản đồ OpenStreetMap, hỗ trợ tự động xác định vị trí hiện tại của du khách[cite: 4].
- **Lập lịch trình du lịch:** Cho phép người dùng nhập điểm đến, khoảng thời gian đi/về, phong cách du lịch mong muốn để hệ thống tự động thiết lập và gợi ý lịch trình tham quan chi tiết theo từng ngày (Timeline)[cite: 4].
- **Mạng xã hội Cộng đồng du lịch:** Khu vực News Feed cho phép các thành viên đăng bài viết review kèm hình ảnh, bày tỏ cảm xúc (Like), bình luận (Comment) trao đổi kinh nghiệm hoặc báo cáo vi phạm nội dung không phù hợp[cite: 4].
- **Quản lý danh sách yêu thích (Bookmarks):** Lưu trữ và đồng bộ hóa các địa điểm yêu thích về tài khoản cá nhân phục vụ cho việc tra cứu và lập lịch trình sau này[cite: 4].
- **Cài đặt quyền riêng tư & Trợ giúp:** Cho phép tùy chỉnh thiết lập ứng dụng (ngôn ngữ, giao diện sáng/tối), quản lý dữ liệu thu thập, cấu hình thông báo và gửi yêu cầu hỗ trợ kỹ thuật trực tiếp đến Ban quản trị[cite: 4].

### 2. Hệ thống dịch vụ hậu tầng (Backend ASP.NET Core)
- **RESTful API Architecture:** Kiến trúc ba lớp phân tách rõ ràng (Presentation, Business, Data Layer), cung cấp và đồng bộ dữ liệu JSON an toàn cho Client di động thông qua giao thức HTTPS[cite: 4].
- **Xác thực bảo mật & Phân quyền (RBAC):** Xử lý quy trình Đăng ký, Đăng nhập (cấp mã JWT Token hợp lệ đính kèm ở Header) và phân quyền chặt chẽ giữa 4 nhóm tác nhân hệ thống[cite: 4].
- **Quản trị nội dung (Admin Dashboard):** Cung cấp các công cụ CRUD quản lý danh mục địa điểm, tài khoản người dùng, kiểm duyệt bài viết cộng đồng, xử lý báo cáo vi phạm và hiển thị biểu đồ thống kê hệ thống[cite: 4].

## 📂 Cấu trúc mã nguồn tổng quan
- `marvel_app/` : Mã nguồn ứng dụng di động Flutter (chứa file `pubspec.yaml` quản lý thư viện và thư mục `lib/` xử lý giao diện/logic)[cite: 4].
- `API/DATABASEAPI/` : Dự án Backend Web API (chứa `Controllers/` xử lý endpoint, `Services/` xử lý nghiệp vụ, `Data/` quản lý EF Core)[cite: 4].
- `database/` : Chứa file script `.sql` dùng để khởi tạo cấu trúc 16 bảng quan hệ quan trọng và nạp dữ liệu mẫu vào SQL Server[cite: 3, 4].
- `docs/` : Các file tài liệu báo cáo đồ án (`.docx`) và slide thuyết trình (`.pptx`) nộp Khoa CNTT - HUIT[cite: 4].

## 🚀 Hướng dẫn cài đặt và chạy thử (Installation & Setup)

### 1. Cấu hình Cơ sở dữ liệu (Database)
1. Mở **SQL Server Management Studio (SSMS)**.
2. Tạo một Database mới có tên là `MarvelTravelDB` (hoặc tên tùy chọn).
3. Import và thực thi (Execute) file script `.sql` trong thư mục `database/` để khởi tạo cấu trúc 16 bảng quan hệ[cite: 4].

### 2. Khởi chạy Backend Web API
1. Mở thư mục dự án Backend bằng **Visual Studio**.
2. Tìm file `appsettings.json`, cập nhật lại chuỗi kết nối cơ sở dữ liệu của bạn tại mục `ConnectionStrings` hướng về `MarvelTravelDB` vừa tạo.
3. Nhấn **F5** để khởi chạy Server. Hệ thống sẽ kích hoạt tài liệu kiểm thử Swagger tự động tại cổng Localhost (ví dụ: `https://localhost:7001/swagger`).

### 3. Khởi chạy Ứng dụng di động (Flutter Client)
1. Mở thư mục `marvel_app/` bằng **Visual Studio Code** hoặc **Android Studio**.
2. Mở Terminal và chạy lệnh `flutter pub get` để đồng bộ và tải toàn bộ các package cấu hình (Provider, Flutter Map...)[cite: 4].
3. Thay đổi hằng số đường dẫn base URL kết nối API trong mã nguồn Flutter từ địa chỉ mặc định sang địa chỉ IP máy cục bộ của bạn hoặc link proxy (Ngrok) để thiết bị giả lập/thiết bị thật kết nối được Backend.
4. Mở thiết bị giả lập (Android Emulator / iOS Simulator) và nhấn **F5** (hoặc chạy lệnh `flutter run`) để tận hưởng ứng dụng!
