# Marvel Travel Flutter App

Ứng dụng Flutter cho đề tài Marvel Travel - app giới thiệu địa điểm du lịch Việt Nam, đọc bài viết/cẩm nang, xem bản đồ, lưu địa điểm yêu thích, tạo lịch trình, bình luận, đánh giá và quản lý tài khoản người dùng.

Ứng dụng này kết nối với backend ASP.NET Core Web API ở thư mục:

```text
D:\Flutter_DoAn\Nhom7_MarvelApp\API\DATABASEAPI
```

## 1. Công nghệ sử dụng

- Flutter / Dart
- HTTP API bằng package `http`
- JWT token cho các API cần đăng nhập
- `flutter_map` để hiển thị bản đồ
- `latlong2` cho tọa độ
- `cached_network_image` cho ảnh online
- Font Be Vietnam Pro
- Dark mode / light mode

## 2. Cấu hình API

File cấu hình API nằm tại:

```text
lib/services/api_config.dart
```

Cấu hình hiện tại:

```dart
static const int port = 5131;
static String get baseUrl => 'http://$host:$port/api';
```

Host được xử lý tự động:

| Nền tảng chạy app | Host API |
| --- | --- |
| Android Emulator | `10.0.2.2` |
| Windows/macOS/Linux/Web | `localhost` |

Vì vậy backend cần chạy ở:

```text
http://localhost:5131
```

Nếu backend đổi port, sửa tại:

```dart
lib/services/api_config.dart
```

Ví dụ backend chạy port `5000`:

```dart
static const int port = 5000;
```

Nếu chạy app trên điện thoại thật, không dùng `localhost` hoặc `10.0.2.2`. Cần đổi `host` sang IP LAN của máy chạy backend, ví dụ:

```dart
return '192.168.1.10';
```

## 3. Cách chạy app

Trước tiên chạy backend API ở thư mục `DATABASEAPI`.

Sau đó trong thư mục Flutter:

```powershell
flutter pub get
flutter run
```

Nếu chạy Android Emulator, đảm bảo backend vẫn chạy trên máy host với port `5131`.

## 4. Cấu trúc thư mục chính

```text
lib/
├── main.dart
├── services/
│   ├── api_config.dart
│   └── extended_api_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── destination_list_screen.dart
│   ├── destination_detail_screen.dart
│   ├── auth_screen.dart
│   ├── register_screen.dart
│   ├── community_screen.dart
│   ├── create_post_screen.dart
│   ├── guide_screen.dart
│   ├── blog_list_screen.dart
│   ├── bookmark_screen.dart
│   ├── itinerary_screen.dart
│   ├── my_itineraries_screen.dart
│   ├── notifications_screen.dart
│   ├── support_request_screen.dart
│   ├── profile_screen.dart
│   ├── personal_info_screen.dart
│   ├── admin_dashboard_screen.dart
│   └── ...
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── aurora_nav_bar.dart
    └── marvel_app_bar.dart
```

## 5. Assets và font

Ảnh nằm ở:

```text
assets/images/
```

Font nằm ở:

```text
assets/fonts/
```

`pubspec.yaml` đã khai báo:

```yaml
assets:
  - assets/images/

fonts:
  - family: BeVietnamPro
```

Các ảnh địa điểm mẫu đang có:

```text
VinhHaLong.jpg
PhoCoHoiAn.jpg
LangBiang.jpg
NamCatTien.jpg
HoHoanKiem.jpg
```

Database backend đang lưu đường dẫn ảnh dạng:

```text
assets/images/VinhHaLong.jpg
```

Flutter đã xử lý được các dạng ảnh:

- `assets/images/...`
- `/assets/images/...`
- `https://...`
- `http://...`
- đường dẫn relative từ backend

## 6. Bản đồ

Màn hình bản đồ:

```text
lib/screens/map_screen.dart
```

App dùng `flutter_map`.

Tile map đã đổi sang Carto basemap để tránh lỗi OpenStreetMap 403 `Access blocked`:

```dart
https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png
https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png
```

Đã thêm:

```dart
userAgentPackageName: 'com.example.marvel_app'
```

Màn hình map gọi API:

```http
GET /api/DiaDiem
```

Để lấy danh sách địa điểm, tọa độ, mô tả và ảnh.

## 7. Đăng nhập và JWT

Màn hình đăng nhập:

```text
lib/screens/auth_screen.dart
```

Khi đăng nhập thành công, backend trả response dạng:

```json
{
  "token": "...",
  "user": {
    "maNguoiDung": 1,
    "hoTen": "...",
    "email": "...",
    "roles": ["User"]
  }
}
```

Flutter lưu token trong `AuthState`.

Các API cần đăng nhập sẽ gửi:

```http
Authorization: Bearer <token>
```

## 8. Service API mở rộng

File:

```text
lib/services/extended_api_service.dart
```

Đang có các hàm chính:

```dart
getCamNang()
likeCamNang(id)
getDanhGiaByDiaDiem(maDiaDiem)
createDanhGia(...)
getBinhLuanByBaiViet(maBaiViet)
createBinhLuan(...)
getThongBao()
markThongBaoRead(id)
getYeuCauHoTroMine()
createYeuCauHoTro(...)
getProfile()
updateProfile(...)
changePassword(...)
```

## 9. Các màn hình và chức năng đã làm

| Màn hình | Chức năng |
| --- | --- |
| `home_screen.dart` | Trang chủ, lấy địa điểm và bài viết từ API, hiển thị ảnh |
| `map_screen.dart` | Bản đồ, marker địa điểm, lấy địa điểm từ API |
| `destination_list_screen.dart` | Danh sách địa điểm từ API |
| `destination_detail_screen.dart` | Chi tiết địa điểm, ảnh, mô tả, đánh giá, gửi đánh giá |
| `auth_screen.dart` | Đăng nhập, nhận JWT token |
| `register_screen.dart` | Đăng ký tài khoản |
| `community_screen.dart` | Danh sách bài viết cộng đồng, like, bình luận bottom sheet |
| `create_post_screen.dart` | Tạo bài viết cộng đồng |
| `guide_screen.dart` | Cẩm nang du lịch từ API |
| `blog_list_screen.dart` | Danh sách bài viết từ API |
| `bookmark_screen.dart` | Lưu/xóa địa điểm yêu thích, dùng JWT |
| `itinerary_screen.dart` | Tạo lịch trình |
| `my_itineraries_screen.dart` | Danh sách lịch trình của người dùng |
| `notifications_screen.dart` | Lấy thông báo và đánh dấu đã đọc |
| `support_request_screen.dart` | Gửi yêu cầu hỗ trợ, xem yêu cầu của mình |
| `profile_screen.dart` | Hồ sơ người dùng |
| `personal_info_screen.dart` | Thông tin cá nhân |
| `admin_dashboard_screen.dart` | Màn hình admin, cần nối thêm API thật nếu mở rộng |

## 10. API đã nối trong Flutter

| Chức năng | Endpoint |
| --- | --- |
| Đăng nhập | `POST /api/auth/login` |
| Đăng ký | `POST /api/auth/register` |
| Địa điểm | `GET /api/diadiem` |
| Bài viết | `GET /api/baiviet` |
| Like bài viết | `POST /api/baiviet/like/{id}` |
| Cẩm nang | `GET /api/camnang` |
| Like cẩm nang | `POST /api/camnang/like/{id}` |
| Đánh giá địa điểm | `GET /api/danhgia/diadiem/{id}` |
| Gửi đánh giá | `POST /api/danhgia` |
| Bình luận bài viết | `GET /api/binhluan/baiviet/{id}` |
| Gửi bình luận | `POST /api/binhluan` |
| Bookmark | `/api/bookmark` |
| Lịch trình | `/api/lichtrinh` |
| Thông báo | `GET /api/thongbao` |
| Đánh dấu thông báo đã đọc | `PUT /api/thongbao/read/{id}` |
| Yêu cầu hỗ trợ | `GET /api/yeucauhotro/mine`, `POST /api/yeucauhotro` |
| Profile | `GET /api/profile/me`, `PUT /api/profile/me` |
| Đổi mật khẩu | `PUT /api/profile/password` |

## 11. Lưu ý khi đổi backend/API trên máy khác

Nếu backend không chạy trên `localhost:5131`, cần sửa:

```text
lib/services/api_config.dart
```

Ví dụ backend chạy trên IP LAN:

```dart
static String get host {
  return '192.168.1.10';
}
```

Nếu backend đổi port:

```dart
static const int port = 5000;
```

Nếu chạy điện thoại thật:

- Máy tính và điện thoại phải cùng Wi-Fi.
- Tắt firewall hoặc mở port backend.
- Không dùng `localhost` vì `localhost` trên điện thoại là chính điện thoại, không phải máy tính.

## 12. Lưu ý khi API không hiện dữ liệu

Kiểm tra lần lượt:

1. Backend đã chạy chưa?

```text
http://localhost:5131/swagger
```

2. API địa điểm có trả JSON không?

```text
http://localhost:5131/api/DiaDiem
```

3. App đang chạy ở nền tảng nào?

- Android Emulator dùng `10.0.2.2`.
- Windows/Web dùng `localhost`.
- Điện thoại thật dùng IP LAN.

4. Database đã chạy script `database.sql` chưa?

5. Ảnh trong database có khớp file trong `assets/images` không?

## 13. Những phần đã hoàn thành

- Giao diện chính theo chủ đề du lịch Việt Nam.
- Dark mode / light mode.
- Đăng nhập/đăng ký với backend.
- Lưu JWT token trong app.
- Gửi token cho API cần quyền.
- Trang chủ lấy dữ liệu API.
- Danh sách địa điểm.
- Chi tiết địa điểm.
- Bản đồ và marker địa điểm.
- Xử lý lỗi tile map OpenStreetMap 403 bằng Carto basemap.
- Cẩm nang du lịch.
- Bài viết cộng đồng.
- Like bài viết/cẩm nang.
- Bình luận bài viết bằng bottom sheet.
- Đánh giá địa điểm.
- Bookmark địa điểm.
- Lịch trình.
- Thông báo.
- Yêu cầu hỗ trợ.
- Profile người dùng.
- Chuẩn hóa đường dẫn ảnh asset/network/relative.

## 14. Việc có thể phát triển tiếp

- Lưu token bằng secure storage thay vì state tạm.
- Hoàn thiện admin dashboard gọi API thật đầy đủ.
- Upload ảnh từ Flutter lên backend.
- Tìm kiếm địa điểm nâng cao.
- Bộ lọc địa điểm theo tỉnh/thể loại.
- Push notification.
- Chat hỗ trợ realtime.
- Offline cache dữ liệu.
- Kiểm thử tự động UI/API.
