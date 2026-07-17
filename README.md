#  Marvel App - Mobile Application with Backend API

##  Giới thiệu dự án
Dự án là một hệ thống công nghệ hoàn chỉnh bao gồm ứng dụng di động (Mobile App) kết hợp với hệ thống dịch vụ hậu tầng (Backend API). Hệ thống cho phép người dùng khám phá, tìm kiếm và quản lý thông tin về các nhân vật, sự kiện, truyện tranh thuộc vũ trụ điện ảnh Marvel một cách mượt mà và trực quan.

##  Công nghệ sử dụng
- **Ứng dụng di động (Frontend Mobile):** Flutter / Dart / VS Code
- **Hệ thống dịch vụ (Backend API):** ASP.NET Core (.NET 6.0 / .NET 8.0) / C# / Visual Studio
- **Cơ sở dữ liệu (Database):** SQL Server
- **Dịch vụ tích hợp:** Twilio API (Hỗ trợ dịch vụ gửi mã xác thực OTP qua SMS)

##  Các chức năng chính

###  1. Ứng dụng di động (Marvel App)
- **Khám phá vũ trụ Marvel:** Hiển thị danh sách, thông tin chi tiết, chỉ số sức mạnh và tiểu sử của các siêu anh hùng.
- **Tìm kiếm thông minh:** Tìm kiếm nhân vật nhanh chóng, lọc anh hùng theo danh mục hoặc theo các sự kiện nổi bật.
- **Xác thực người dùng:** Hệ thống đăng nhập, đăng ký tài khoản bảo mật trực tiếp trên ứng dụng di động.
- **Tối ưu giao diện:** Thiết kế giao diện hiện đại, responsive mượt mà, tối ưu hóa hiệu năng tải hình ảnh và dữ liệu.

###  2. Hệ thống dịch vụ (DATABASE API)
- **RESTful API Architecture:** Xây dựng hệ thống Backend theo chuẩn RESTful API bằng ASP.NET Core để cung cấp và đồng bộ dữ liệu cho ứng dụng di động.
- **Quản lý thực thể (Entities):** Xử lý logic nghiệp vụ, quản lý cơ sở dữ liệu tài khoản, danh sách siêu anh hùng từ SQL Server.
- **Tích hợp Twilio OTP:** Xử lý cổng dịch vụ bên thứ ba để gửi mã OTP bảo mật qua SMS phục vụ cho tính năng xác thực đăng ký.
- **Quản lý cấu hình:** Quản lý môi trường, chuỗi kết nối linh hoạt và an toàn qua hệ thống file `appsettings.json`.

##  Cấu trúc mã nguồn tổng quan
- `marvel_app/`: Mã nguồn ứng dụng di động Flutter (chứa file cấu hình `pubspec.yaml`, giao diện và logic xử lý nằm trong `lib/`).
- `API/DATABASEAPI/`: Mã nguồn dự án Backend ASP.NET Core (chứa `Controllers/` xử lý API endpoints, `Entities/` định nghĩa cấu trúc dữ liệu).
- `database/`: Chứa file script `database.sql` và `danh sach duong dan anh bo sung.sql` để khởi tạo cấu trúc bảng và dữ liệu mẫu trong SQL Server.
- Các file tài liệu báo cáo đồ án đi kèm (`.docx`, `.pptx`).

##  Hướng dẫn cài đặt và chạy thử (Installation & Setup)

### 1. Cấu hình Cơ sở dữ liệu (Backend)
1. Mở **SQL Server Management Studio (SSMS)**.
2. Tạo một Database mới (ví dụ: `MarvelDB`).
3. Mở và chạy (Execute) file script `database.sql` để khởi tạo các bảng dữ liệu.

### 2. Chạy Backend API
1. Mở thư mục `API/DATABASEAPI/` bằng **Visual Studio**.
2. Cập nhật lại chuỗi kết nối SQL Server của bạn trong file `appsettings.json` tại mục `ConnectionStrings`.
3. Nhấn **F5** hoặc nút **Start** để chạy dự án. API sẽ được khởi chạy mặc định dưới dạng Localhost (ví dụ: `https://localhost:xxxx`).

### 3. Chạy Ứng dụng di động (Mobile App)
1. Mở thư mục `marvel_app/` bằng **VS Code** hoặc **Android Studio**.
2. Chạy lệnh `flutter pub get` trong Terminal để tải các thư viện cần thiết.
3. Thay đổi đường dẫn URL kết nối API trong mã nguồn Flutter hướng về địa chỉ Localhost (hoặc IP máy/Ngrok) của cụm Backend API vừa chạy.
4. Kết nối thiết bị giả lập (Emulator) hoặc điện thoại thật và nhấn **F5** để khởi chạy ứng dụng.
