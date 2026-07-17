import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/constants/api_config.dart';

class ExtendedApiService {
  ExtendedApiService._();

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (AuthState().token != null)
          'Authorization': 'Bearer ${AuthState().token}',
      };

  static Future<List<dynamic>> getCamNang({String? category}) async {
    final response = await http.get(ApiConfig.uri(
        'CamNang', category == null ? null : {'category': category}));
    if (response.statusCode != 200) {
      throw Exception('Không tải được cẩm nang: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> likeCamNang(int id) async {
    final response = await http.post(ApiConfig.uri('CamNang/like/$id'),
        headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không thích được cẩm nang: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getDanhGiaByDiaDiem(int maDiaDiem) async {
    final response =
        await http.get(ApiConfig.uri('DanhGia/diadiem/$maDiaDiem'));
    if (response.statusCode != 200) {
      throw Exception('Không tải được đánh giá: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }



  static Future<Map<String, dynamic>> getDanhGiaStats(int maDiaDiem) async {
    final response = await http.get(ApiConfig.uri('DanhGia/diadiem/$maDiaDiem/stats'));
    if (response.statusCode != 200) {
      throw Exception('Không tải được thống kê đánh giá: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createDanhGia(
      {required int maDiaDiem, required double soSao, String? noiDung}) async {
    final response = await http.post(
      ApiConfig.uri('DanhGia'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'maDiaDiem': maDiaDiem,
        'soSao': soSao,
        'noiDung': noiDung,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Không gửi được đánh giá: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getDanhGiaMine() async {
    final response = await http.get(ApiConfig.uri('DanhGia/mine'),
        headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không tải được đánh giá cá nhân: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getBinhLuanByBaiViet(int maBaiViet) async {
    final response =
        await http.get(ApiConfig.uri('BinhLuan/baiviet/$maBaiViet'));
    if (response.statusCode != 200) {
      throw Exception('Không tải được bình luận: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createBinhLuan(
      {required int maBaiViet, required String noiDung}) async {
    final response = await http.post(
      ApiConfig.uri('BinhLuan'),
      headers: _jsonHeaders,
      body: jsonEncode({'maBaiViet': maBaiViet, 'noiDung': noiDung}),
    );
    if (response.statusCode != 200) {
      throw Exception('Không gửi được bình luận: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getThongBao() async {
    final response =
        await http.get(ApiConfig.uri('ThongBao'), headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không tải được thông báo: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> markThongBaoRead(int id) async {
    final response = await http.put(ApiConfig.uri('ThongBao/read/$id'),
        headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không cập nhật được thông báo: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }


  static Future<List<dynamic>> getAdminNotifyUsers() async {
    final response = await http.get(ApiConfig.uri('ThongBao/admin/users'),
        headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách người dùng: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> sendAdminNotification({
    required String title,
    required String content,
    required bool sendAll,
    required List<int> userIds,
  }) async {
    final response = await http.post(
      ApiConfig.uri('ThongBao/admin/send'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'tieuDe': title,
        'noiDung': content,
        'sendAll': sendAll,
        'userIds': userIds,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Không gửi được thông báo: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getLatestUnreadThongBao() async {
    final response = await http.get(ApiConfig.uri('ThongBao/unread/latest'),
        headers: _jsonHeaders);
    if (response.statusCode == 204) return null;
    if (response.statusCode != 200) {
      throw Exception('Không kiểm tra được thông báo mới: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getYeuCauHoTroMine() async {
    final response = await http.get(ApiConfig.uri('YeuCauHoTro/mine'),
        headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không tải được yêu cầu hỗ trợ: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createYeuCauHoTro(
      {String? loaiYeuCau,
      required String tieuDe,
      required String noiDung}) async {
    final response = await http.post(
      ApiConfig.uri('YeuCauHoTro'),
      headers: _jsonHeaders,
      body: jsonEncode(
          {'loaiYeuCau': loaiYeuCau, 'tieuDe': tieuDe, 'noiDung': noiDung}),
    );
    if (response.statusCode != 200) {
      throw Exception('Không gửi được yêu cầu hỗ trợ: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response =
        await http.get(ApiConfig.uri('Profile/me'), headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Không tải được hồ sơ: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(
      {String? hoTen, String? soDienThoai, String? anhDaiDien}) async {
    final response = await http.put(
      ApiConfig.uri('Profile/me'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        'anhDaiDien': anhDaiDien
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Không cập nhật được hồ sơ: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final request =
        http.MultipartRequest('POST', ApiConfig.uri('Profile/avatar'));
    if (AuthState().token != null) {
      request.headers['Authorization'] = 'Bearer ${AuthState().token}';
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Không upload được ảnh đại diện: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getApprovedPosts() async {
    final response = await http.get(ApiConfig.uri('BaiViet'));
    if (response.statusCode != 200) {
      throw Exception('Không tải được bài viết: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getAllDiaDiem() async {
    final response = await http.get(ApiConfig.uri('DiaDiem'));
    if (response.statusCode != 200) {
      throw Exception('Không tải được địa điểm: ${response.statusCode}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    final response = await http.put(
      ApiConfig.uri('Profile/password'),
      headers: _jsonHeaders,
      body: jsonEncode(
          {'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Không đổi được mật khẩu: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createAdminDiaDiem({
    required String tenDiaDiem,
    required String tinhThanh,
    required String moTa,
    required double kinhDo,
    required double viDo,
    String? hinhAnh,
    List<Map<String, String?>> chiTiets = const [],
  }) async {
    final response = await http.post(
      ApiConfig.uri('DiaDiem/admin'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'tenDiaDiem': tenDiaDiem,
        'tinhThanh': tinhThanh,
        'moTa': moTa,
        'kinhDo': kinhDo,
        'viDo': viDo,
        'hinhAnh': hinhAnh,
        'chiTiets': chiTiets,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Không tạo được địa điểm: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

}