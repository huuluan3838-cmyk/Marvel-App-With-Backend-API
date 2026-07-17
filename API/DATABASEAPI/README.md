# Marvel Travel API - DATABASEAPI

Backend ASP.NET Core Web API cho ứng dụng du lịch Marvel Travel. API quản lý tài khoản, phân quyền, địa điểm du lịch, bài viết cộng đồng, cẩm nang, đánh giá, bình luận, bookmark, lịch trình, thông báo, yêu cầu hỗ trợ và hồ sơ người dùng.

## 1. Công nghệ sử dụng

- ASP.NET Core Web API
- Entity Framework Core
- SQL Server / SQL Server Express
- JWT Authentication
- Role-based Authorization
- Swagger/OpenAPI

## 2. Cấu hình hiện tại

File cấu hình chính:

```text
appsettings.json
```

Connection string hiện tại:

```json
"ConnectionStrings": {
  "ApiDemo": "Server=Agrimotor\\SQLEXPRESS;Database=MarvelTravelDB;User Id=sa;Password=123;TrustServerCertificate=True;Encrypt=False"
}
```

JWT hiện tại:

```json
"Jwt": {
  "Key": "MarvelTravelApi_Development_Secret_Key_Change_Me_At_Least_32_Chars",
  "Issuer": "MarvelTravelAPI",
  "Audience": "MarvelTravelApp",
  "ExpireMinutes": 1440
}
```

> Lưu ý: Khi đưa sang máy khác, cần đổi `Server`, `User Id`, `Password` trong `appsettings.json` cho đúng SQL Server của máy đó.

## 3. Cách đổi database khi chạy trên máy khác

Ví dụ nếu máy khác dùng SQL Server Express tên mặc định:

```json
"ApiDemo": "Server=.\\SQLEXPRESS;Database=MarvelTravelDB;User Id=sa;Password=123;TrustServerCertificate=True;Encrypt=False"
```

Nếu dùng Windows Authentication:

```json
"ApiDemo": "Server=.\\SQLEXPRESS;Database=MarvelTravelDB;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=False"
```

Nếu dùng SQL Server localdb:

```json
"ApiDemo": "Server=(localdb)\\MSSQLLocalDB;Database=MarvelTravelDB;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=False"
```

Các bước chuyển máy:

1. Mở SQL Server Management Studio.
2. Chạy file:

```text
database/database.sql
```

3. Kiểm tra database `MarvelTravelDB` đã được tạo.
4. Sửa connection string trong `appsettings.json` theo SQL Server của máy mới.
5. Chạy API lại.

## 4. Cách chạy API

Cài .NET SDK phù hợp, sau đó chạy:

```powershell
dotnet restore
dotnet build .\DATABASEAPI.sln
dotnet run
```

Hoặc chạy bằng Visual Studio với profile `http`.

API mặc định chạy ở:

```text
http://localhost:5131
```

Swagger:

```text
http://localhost:5131/swagger
```

## 5. CORS

API đã bật CORS `AllowAll` để Flutter/Web có thể gọi API trong môi trường đồ án.

```csharp
policy.AllowAnyOrigin()
      .AllowAnyHeader()
      .AllowAnyMethod();
```

## 6. Bảo mật đã có

API đã có:

- Đăng ký / đăng nhập.
- Hash mật khẩu bằng service backend.
- JWT token khi đăng nhập thành công.
- API cần đăng nhập dùng `Authorization: Bearer <token>`.
- Phân quyền theo role.
- Policy:
  - `AdminOnly`
  - `ContentModerator`

Các role chính:

- `Admin`
- `Moderator`
- `User`

## 7. Database có gì

File SQL:

```text
database/database.sql
```

Database chính:

```text
MarvelTravelDB
```

Các nhóm bảng chính:

| Nhóm | Bảng / Ý nghĩa |
| --- | --- |
| Người dùng | Người dùng, tài khoản, mật khẩu hash |
| Phân quyền | Role, quyền, mapping người dùng - role |
| Địa điểm | Địa điểm du lịch, chi tiết địa điểm |
| Bài viết | Bài viết cộng đồng, trạng thái bài viết |
| Cẩm nang | Nội dung hướng dẫn du lịch |
| Đánh giá | Đánh giá địa điểm theo số sao và nội dung |
| Bình luận | Bình luận theo bài viết |
| Bookmark | Lưu địa điểm yêu thích |
| Lịch trình | Tạo và quản lý lịch trình du lịch |
| Thông báo | Thông báo người dùng |
| Hỗ trợ | Yêu cầu hỗ trợ từ người dùng |

## 8. Danh sách controller

Hiện có 12 controller:

```text
AuthController.cs
BaiVietController.cs
BinhLuanController.cs
BookmarkController.cs
CamNangController.cs
DanhGiaController.cs
DiaDiemController.cs
LichTrinhController.cs
PhanQuyenController.cs
ProfileController.cs
ThongBaoController.cs
YeuCauHoTroController.cs
```

## 9. Danh sách API chính

### Auth

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| POST | `/api/auth/register` | Đăng ký tài khoản |
| POST | `/api/auth/login` | Đăng nhập, trả JWT token |

### Địa điểm

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/diadiem` | Lấy danh sách địa điểm |
| GET | `/api/diadiem/{id}` | Lấy chi tiết địa điểm |

API địa điểm hiện trả DTO phẳng để Flutter đọc ổn định, tránh lỗi vòng lặp JSON từ Entity Framework.

### Bài viết cộng đồng

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/baiviet` | Lấy danh sách bài viết |
| GET | `/api/baiviet/{id}` | Lấy chi tiết bài viết |
| POST | `/api/baiviet` | Tạo bài viết |
| PUT | `/api/baiviet/{id}` | Sửa bài viết |
| DELETE | `/api/baiviet/{id}` | Xóa bài viết |
| POST | `/api/baiviet/like/{id}` | Like bài viết |
| PUT | `/api/baiviet/hide/{id}` | Ẩn bài viết, yêu cầu quyền ContentModerator |

### Cẩm nang

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/camnang` | Lấy danh sách cẩm nang |
| GET | `/api/camnang/{id}` | Lấy chi tiết cẩm nang |
| POST | `/api/camnang` | Tạo cẩm nang |
| POST | `/api/camnang/like/{id}` | Like cẩm nang |

### Đánh giá địa điểm

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/danhgia/diadiem/{diaDiemId}` | Lấy đánh giá theo địa điểm |
| POST | `/api/danhgia` | Gửi đánh giá địa điểm, cần JWT |

### Bình luận bài viết

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/binhluan/baiviet/{baiVietId}` | Lấy bình luận theo bài viết |
| POST | `/api/binhluan` | Gửi bình luận, cần JWT |

### Bookmark

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/bookmark` | Lấy bookmark của người dùng |
| POST | `/api/bookmark` | Thêm bookmark, cần JWT |
| DELETE | `/api/bookmark/{maDiaDiem}` | Xóa bookmark, cần JWT |

### Lịch trình

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/lichtrinh` | Lấy lịch trình |
| POST | `/api/lichtrinh` | Tạo lịch trình, cần JWT |
| PUT | `/api/lichtrinh/{id}` | Sửa lịch trình |
| DELETE | `/api/lichtrinh/{id}` | Xóa lịch trình |

### Thông báo

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/thongbao` | Lấy thông báo của người dùng, cần JWT |
| PUT | `/api/thongbao/read/{id}` | Đánh dấu đã đọc, cần JWT |
| POST | `/api/thongbao` | Tạo thông báo |

### Yêu cầu hỗ trợ

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/yeucauhotro/mine` | Lấy yêu cầu hỗ trợ của bản thân, cần JWT |
| GET | `/api/yeucauhotro/admin` | Admin xem tất cả yêu cầu |
| POST | `/api/yeucauhotro` | Gửi yêu cầu hỗ trợ, cần JWT |
| PUT | `/api/yeucauhotro/status/{id}` | Cập nhật trạng thái yêu cầu |

### Profile

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/api/profile/me` | Lấy hồ sơ người dùng hiện tại, cần JWT |
| PUT | `/api/profile/me` | Cập nhật hồ sơ, cần JWT |
| PUT | `/api/profile/password` | Đổi mật khẩu, cần JWT |

### Phân quyền

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET/POST/PUT/DELETE | `/api/phanquyen/...` | Quản lý quyền và role tùy controller |

## 10. Cách gọi API cần đăng nhập

Sau khi login, backend trả token. Client phải gửi header:

```http
Authorization: Bearer <jwt_token>
```

Ví dụ:

```http
GET /api/profile/me
Authorization: Bearer eyJhbGciOi...
```

## 11. Lưu ý hình ảnh

Dữ liệu mẫu đang dùng hình ảnh dạng asset Flutter:

```text
assets/images/VinhHaLong.jpg
assets/images/PhoCoHoiAn.jpg
assets/images/LangBiang.jpg
assets/images/NamCatTien.jpg
assets/images/HoHoanKiem.jpg
```

Nếu muốn dùng ảnh online thì lưu trong database dạng:

```text
https://example.com/image.jpg
```

Nếu muốn dùng ảnh upload từ backend thì cần bổ sung `wwwroot/uploads` và `UseStaticFiles()` trong `Program.cs`.

## 12. Những phần đã hoàn thành

- API đăng nhập/đăng ký.
- JWT authentication.
- Hash mật khẩu.
- Phân quyền role/policy.
- API địa điểm trả dữ liệu sạch cho Flutter.
- API bài viết, like, ẩn bài viết.
- API cẩm nang.
- API đánh giá địa điểm.
- API bình luận bài viết.
- API thông báo.
- API yêu cầu hỗ trợ.
- API profile.
- API bookmark.
- API lịch trình.
- Swagger để test API.

## 13. Việc có thể phát triển tiếp

- Upload ảnh thật lên backend.
- Dashboard admin đầy đủ hơn.
- Duyệt bài viết trước khi hiển thị.
- Refresh token.
- Gửi thông báo realtime.
- Tìm kiếm nâng cao địa điểm/bài viết.
