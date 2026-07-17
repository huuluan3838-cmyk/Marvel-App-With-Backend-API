# DATABASEAPI - Marvel Travel API Notes

## 1. Thông tin dự án


## 2. Các sửa đổi đã thực hiện

### 2.1. Sửa API để build được

Đã sửa các file:

- `Program.cs`
  - Xóa dòng `using DATABASEAPI.Controllers;` vì namespace này không tồn tại.
  - Giữ cấu hình DI cho `MarvelTravelDbContext` đọc connection string từ `appsettings.json`.

- `appsettings.json`
  - Đổi connection string sang SQL Server local của anh:

```json
"ApiDemo": "Server=Agrimotor\\SQLEXPRESS;Database=MarvelTravelDB;User Id=sa;Password=123;TrustServerCertificate=True;Encrypt=False"
```

- `Entities/MarvelTravelDbContext.cs`
  - Sửa `OnConfiguring` dùng SQL Server `Agrimotor\\SQLEXPRESS` nếu DbContext chưa được cấu hình từ DI.

- `Controllers/AuthController.cs`
  - Sửa DTO login/google-login cho phù hợp nullable để build không còn warning.

- `Controllers/BaiVietController.cs`
  - Thêm kiểm tra thiếu dữ liệu khi báo cáo bài viết trước khi gọi stored procedure.

### 2.2. Bổ sung phân quyền chuẩn RBAC trong SQL

Đã ghi thêm ở cuối file `database/database.sql`, để anh có thể chạy tiếp trong SQL Server.

Các bảng mới:

| Bảng | Mục đích |
| --- | --- |
| `VaiTro` | Lưu vai trò: `Admin`, `User`, `Moderator` |
| `Quyen` | Lưu quyền chi tiết |
| `VaiTroQuyen` | Gán quyền cho từng vai trò |

Các object SQL mới:

| Object | Mục đích |
| --- | --- |
| `sp_KiemTraQuyen` | Kiểm tra user có quyền cụ thể hay không |
| `vw_NguoiDung_Quyen` | Xem danh sách user và quyền tương ứng |
| `FK_NguoiDung_VaiTro` | Ràng buộc `NguoiDung.VaiTro` tham chiếu `VaiTro.TenVaiTro` |

Lưu ý: API cũ vẫn dùng được vì vẫn giữ cột `NguoiDung.VaiTro`. RBAC chỉ bổ sung thêm bảng chuẩn phía sau.

### 2.3. Đồng bộ API phân quyền

Đã tạo controller mới:

- `Controllers/PhanQuyenController.cs`

Controller này dùng:

- View `vw_NguoiDung_Quyen`
- Stored procedure `sp_KiemTraQuyen`

## 3. Danh sách API hiện có

Tổng số endpoint hiện tại: **18 API**

### 3.1. Auth API

Base route: `/api/auth`

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| POST | `/api/auth/login` | Đăng nhập bằng email/password |
| POST | `/api/auth/register` | Đăng ký tài khoản mới |
| POST | `/api/auth/google-login` | Đăng nhập hoặc tạo tài khoản bằng Google |

### 3.2. Bài viết API

Base route: `/api/baiviet`

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| GET | `/api/baiviet` | Lấy danh sách bài viết đã duyệt `Approved` |
| GET | `/api/baiviet/admin` | Admin lấy tất cả bài viết |
| POST | `/api/baiviet` | Tạo bài viết mới, mặc định `Pending` |
| PUT | `/api/baiviet/approve/{id}` | Duyệt bài viết |
| POST | `/api/baiviet/like/{id}?userId=...` | Thích hoặc bỏ thích bài viết |
| POST | `/api/baiviet/report` | Báo cáo bài viết vi phạm |

### 3.3. Bookmark API

Base route: `/api/bookmark`

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| GET | `/api/bookmark/user/{userId}` | Lấy danh sách địa điểm user đã lưu |
| POST | `/api/bookmark` | Thêm hoặc bỏ lưu địa điểm |

Body mẫu:

```json
{
  "maNguoiDung": 2,
  "maDiaDiem": 1
}
```

### 3.4. Địa điểm API

Base route: `/api/diadiem`

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| GET | `/api/diadiem` | Lấy tất cả địa điểm kèm địa điểm chi tiết |
| GET | `/api/diadiem/{id}` | Lấy chi tiết một địa điểm |

### 3.5. Lịch trình API

Base route: `/api/lichtrinh`

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| GET | `/api/lichtrinh/user/{userId}` | Lấy lịch trình của user |
| POST | `/api/lichtrinh` | Tạo lịch trình mới |

### 3.6. Phân quyền API

Base route: `/api/phanquyen`

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| GET | `/api/phanquyen/user/{userId}` | Lấy danh sách quyền của user |
| GET | `/api/phanquyen/check?userId=1&permission=baiviet.approve` | Kiểm tra user có quyền cụ thể không |

## 4. Đánh giá phân quyền hiện tại

### Trước khi sửa

Database chỉ có:

```sql
NguoiDung.VaiTro VARCHAR(20) CHECK (VaiTro IN ('Admin', 'User'))
```

Mức này chạy được cho demo nhưng chưa chuẩn vì:

- Quyền bị hardcode theo text role.
- Không quản lý được quyền chi tiết.
- Muốn thêm quyền mới phải sửa code hoặc sửa logic thủ công.
- Không có bảng mapping role-permission.

### Sau khi sửa

Đã chuyển sang mô hình RBAC mềm hơn:

```text
NguoiDung.VaiTro -> VaiTro.TenVaiTro -> VaiTroQuyen -> Quyen
```

Ưu điểm:

- Có thể thêm role mới như `Moderator`.
- Có thể thêm quyền mới mà không phá API cũ.
- Admin có toàn quyền.
- User chỉ có quyền dùng app cơ bản.
- Moderator có quyền kiểm duyệt nội dung.

## 5. Cách chạy SQL

Nếu database chưa có hoặc muốn tạo lại toàn bộ:

1. Mở SQL Server Management Studio.
2. Kết nối server: `Agrimotor\SQLEXPRESS`.
3. Login bằng `sa / 123`.
4. Mở file `database/database.sql`.
5. Chạy toàn bộ script.

Nếu database đã tạo trước đó và chỉ muốn thêm phân quyền mới:

1. Mở file `database/database.sql`.
2. Kéo xuống đoạn cuối có tiêu đề:

```sql
-- BO SUNG PHAN QUYEN CHUAN RBAC - CHAY TIEP SAU SCRIPT GOC
```

3. Chạy từ đoạn đó trở xuống.

## 6. Kiểm chứng build

Đã chạy lệnh:

```powershell
dotnet build .\DATABASEAPI.sln -v:m
```

Kết quả:

```text
Build succeeded.
0 Warning(s)
0 Error(s)
```

## 7. Gợi ý làm tiếp

Nên làm tiếp các phần sau nếu muốn API chặt hơn:

1. Thêm JWT authentication để API biết user nào đang gọi.
2. Thêm attribute/middleware kiểm tra permission thay vì truyền `userId` từ query.
3. Mã hóa mật khẩu bằng BCrypt, không lưu plaintext `123456`.
4. Tách DTO request/response, không trả trực tiếp entity `NguoiDung` có `MatKhau`.
5. Thêm API cho `CamNang`, `DanhGia`, `BinhLuan`, `YeuCauHoTro`, `ThongBao` nếu Flutter cần dùng đủ bảng.

## 8. Cập nhật bảo mật JWT + hash mật khẩu

Đã bổ sung các phần sau:

- Package `Microsoft.AspNetCore.Authentication.JwtBearer`.
- Cấu hình `Jwt` trong `appsettings.json`.
- Service `Services/AuthService.cs` để:
  - hash mật khẩu bằng `PasswordHasher<NguoiDung>`;
  - kiểm tra mật khẩu hash;
  - tạm hỗ trợ tài khoản mẫu plaintext cũ, sau login thành công sẽ tự nâng cấp sang hash;
  - sinh JWT token.
- Extension `Extensions/ClaimsPrincipalExtensions.cs` để lấy `userId` và kiểm tra Admin từ JWT claim.

Các API đã được chặn quyền thật hơn:

| Nhóm API | Quyền hiện tại |
| --- | --- |
| `GET /api/baiviet` | Public |
| `GET /api/diadiem`, `GET /api/diadiem/{id}` | Public |
| `POST /api/auth/login`, `register`, `google-login` | Public |
| `GET /api/baiviet/admin` | Admin hoặc Moderator |
| `PUT /api/baiviet/approve/{id}` | Admin hoặc Moderator |
| `POST /api/baiviet` | Cần JWT |
| `POST /api/baiviet/like/{id}` | Cần JWT, tự lấy user từ token |
| `POST /api/baiviet/report` | Cần JWT, tự lấy user từ token |
| `/api/bookmark/*` | Cần JWT, chỉ user chính chủ hoặc Admin |
| `/api/lichtrinh/*` | Cần JWT, chỉ user chính chủ hoặc Admin |
| `/api/phanquyen/*` | Chỉ Admin |

Khi gọi API cần quyền, Flutter/Postman phải gửi header:

```http
Authorization: Bearer <token trả về từ /api/auth/login>
```

Lưu ý: `Jwt:Key` trong `appsettings.json` hiện là key development. Khi deploy thật phải đổi sang secret riêng và không commit lên Git.

## 9. Hướng dẫn đổi database khi chạy trên máy khác

Khi người khác tải project này về chạy trên máy khác, thường sẽ khác tên SQL Server, tài khoản hoặc mật khẩu. Cần sửa connection string trước khi chạy API.

### 9.1. File cần sửa

Mở file:

```text
appsettings.json
```

Tìm đoạn:

```json
"ConnectionStrings": {
  "ApiDemo": "Server=Agrimotor\\SQLEXPRESS;Database=MarvelTravelDB;User Id=sa;Password=123;TrustServerCertificate=True;Encrypt=False"
}
```

Đổi lại theo máy của người đang chạy.

### 9.2. Trường hợp dùng SQL Server Authentication

Nếu máy khác dùng tài khoản SQL Server, ví dụ:

- Server: `LAPTOP-A\SQLEXPRESS`
- Database: `MarvelTravelDB`
- User: `sa`
- Password: `123456`

Thì sửa thành:

```json
"ConnectionStrings": {
  "ApiDemo": "Server=LAPTOP-A\\SQLEXPRESS;Database=MarvelTravelDB;User Id=sa;Password=123456;TrustServerCertificate=True;Encrypt=False"
}
```

Lưu ý trong JSON phải viết dấu `\` thành `\\`.

Ví dụ SQL Server thật là:

```text
LAPTOP-A\SQLEXPRESS
```

Thì trong `appsettings.json` phải ghi:

```text
LAPTOP-A\\SQLEXPRESS
```

### 9.3. Trường hợp dùng Windows Authentication

Nếu máy khác không dùng user `sa`, mà dùng Windows Authentication, sửa connection string thành:

```json
"ConnectionStrings": {
  "ApiDemo": "Server=LAPTOP-A\\SQLEXPRESS;Database=MarvelTravelDB;Integrated Security=True;TrustServerCertificate=True;Encrypt=False"
}
```

Hoặc nếu SQL Server là local default instance:

```json
"ConnectionStrings": {
  "ApiDemo": "Server=localhost;Database=MarvelTravelDB;Integrated Security=True;TrustServerCertificate=True;Encrypt=False"
}
```

### 9.4. Các tên server SQL hay gặp

Có thể thử một trong các dạng sau tùy máy:

```text
localhost
.\SQLEXPRESS
localhost\SQLEXPRESS
TEN-MAY\SQLEXPRESS
(localdb)\MSSQLLocalDB
```

Ví dụ dùng LocalDB:

```json
"ConnectionStrings": {
  "ApiDemo": "Server=(localdb)\\MSSQLLocalDB;Database=MarvelTravelDB;Integrated Security=True;TrustServerCertificate=True;Encrypt=False"
}
```

### 9.5. Cách tạo database trên máy khác

1. Mở SQL Server Management Studio.
2. Kết nối vào SQL Server của máy đó.
3. Mở file:

```text
database/database.sql
```

4. Chạy toàn bộ script để tạo database `MarvelTravelDB`, bảng, stored procedure, dữ liệu mẫu và phân quyền.
5. Sau khi chạy xong, kiểm tra có database:

```sql
SELECT name FROM sys.databases WHERE name = 'MarvelTravelDB';
```

6. Kiểm tra user mẫu:

```sql
USE MarvelTravelDB;
SELECT MaNguoiDung, HoTen, Email, VaiTro FROM NguoiDung;
```

### 9.6. Cách kiểm tra API đã kết nối đúng database chưa

Sau khi sửa `appsettings.json` và chạy SQL xong, chạy API:

```powershell
dotnet run
```

Mở Swagger hoặc gọi thử:

```http
GET /api/diadiem
```

Nếu trả về danh sách địa điểm như `Vịnh Hạ Long`, `Phố Cổ Hội An`, nghĩa là API đã kết nối đúng database.

### 9.7. Nếu bị lỗi đăng nhập SQL Server

Một số lỗi thường gặp:

#### Lỗi sai server

```text
A network-related or instance-specific error occurred
```

Cách sửa:

- Kiểm tra lại tên server trong SSMS.
- Copy đúng tên server từ cửa sổ connect của SSMS sang `appsettings.json`.

#### Lỗi sai tài khoản/mật khẩu

```text
Login failed for user 'sa'
```

Cách sửa:

- Kiểm tra SQL Server có bật SQL Server Authentication chưa.
- Kiểm tra user `sa` có bị disable không.
- Đổi lại password trong connection string.
- Hoặc chuyển sang `Integrated Security=True` nếu dùng Windows Authentication.

#### Lỗi database chưa tồn tại

```text
Cannot open database "MarvelTravelDB" requested by the login
```

Cách sửa:

- Chạy file `database/database.sql` trước.
- Kiểm tra tên database có đúng là `MarvelTravelDB` không.

### 9.8. Những chỗ có connection string trong project

Hiện project có 2 chỗ liên quan SQL Server:

1. `appsettings.json`
   - Đây là chỗ chính nên sửa khi đổi máy.

2. `Entities/MarvelTravelDbContext.cs`
   - Có fallback connection string nếu DbContext chưa được cấu hình.
   - Bình thường API sẽ dùng `appsettings.json` trước.
   - Nếu muốn đồng bộ hoàn toàn, có thể đổi fallback trong file này giống connection string mới.

Khuyến nghị: khi chạy trên máy khác, chỉ cần sửa `appsettings.json` là đủ trong đa số trường hợp.
