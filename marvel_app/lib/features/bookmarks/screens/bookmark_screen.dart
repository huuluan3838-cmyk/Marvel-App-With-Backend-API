import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

// ── CẤU HÌNH API (Thay 5123 bằng đúng Port của Visual Studio) ──
final String apiUrl = ApiConfig.baseUrl;

// ── 1. MODEL DỮ LIỆU YÊU THÍCH ──
class BookmarkItem {
  final String id;
  final String name;
  final String province;
  final double rating;
  final String category;
  final Color color;
  final IconData icon;

  const BookmarkItem({
    required this.id,
    required this.name,
    required this.province,
    this.rating = 4.5,
    required this.category,
    required this.color,
    required this.icon,
  });

  // Chuyển đổi dữ liệu JSON từ API thành đối tượng BookmarkItem
  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['maDiaDiem']?.toString() ?? '',
      name: json['tenDiaDiem'] ?? 'Không rõ',
      province: json['tinhThanh'] ?? '',
      rating: (json['danhGiaTrungBinh'] ?? 5.0).toDouble(),
      category: 'Điểm đến', // Mặc định do API hiện tại chưa trả về Category
      color: AppColors.primary,
      icon: Icons.place_rounded,
    );
  }
}

// ── 2. QUẢN LÝ TRẠNG THÁI (STATE) & GỌI API ──
class BookmarkState extends ChangeNotifier {
  static final BookmarkState _instance = BookmarkState._internal();
  factory BookmarkState() => _instance;
  BookmarkState._internal();

  List<BookmarkItem> _items = [];
  bool isLoading = false;

  List<BookmarkItem> get items => _items;

  // Lấy danh sách bookmark từ API
  Future<void> fetchBookmarks() async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return;

    // Tạm thời fix cứng ID user = 2 để test theo dữ liệu SQL mẫu
    // Sau này bạn có thể lưu userId thực tế vào AuthState và gọi ra ở đây
    final int userId = AuthState().userId ?? 2;

    isLoading = true;
    notifyListeners(); // Cập nhật giao diện hiện vòng xoay

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/Bookmark/user/$userId'),
        headers: {'Authorization': 'Bearer ${AuthState().token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _items = data.map((json) => BookmarkItem.fromJson(json)).toList();
      } else {
        debugPrint('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi fetchBookmarks: $e');
    } finally {
      isLoading = false;
      notifyListeners(); // Ẩn vòng xoay, cập nhật danh sách
    }
  }

  // Thêm hoặc Xóa Bookmark qua API
  Future<void> toggleBookmark(String diaDiemId, BookmarkItem item) async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return;

    final int userId = AuthState().userId ?? 2;
    int dId = int.tryParse(diaDiemId) ?? 0;

    // Cập nhật giao diện ngay lập tức (Optimistic Update) cho mượt mà
    if (isBookmarked(diaDiemId)) {
      _items.removeWhere((i) => i.id == diaDiemId);
    } else {
      _items.add(item);
    }
    notifyListeners();

    try {
      // Gửi yêu cầu lên Server để cập nhật SQL
      final response = await http.post(
        Uri.parse('$apiUrl/Bookmark'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState().token}'
        },
        body: jsonEncode({
          'maNguoiDung': userId,
          'maDiaDiem': dId,
        }),
      );

      // Nếu server báo lỗi thì tải lại danh sách cũ từ CSDL để đảm bảo đồng bộ
      if (response.statusCode != 200) {
        fetchBookmarks();
      }
    } catch (e) {
      debugPrint('Lỗi toggleBookmark: $e');
      fetchBookmarks(); // Phục hồi dữ liệu nếu lỗi mạng
    }
  }

  // Hàm hỗ trợ UI xóa Bookmark
  void removeBookmark(String id) {
    toggleBookmark(
        id,
        BookmarkItem(
            id: id,
            name: '',
            province: '',
            category: '',
            color: Colors.transparent,
            icon: Icons.error));
  }

  bool isBookmarked(String id) {
    return _items.any((item) => item.id == id);
  }
}

// ── 3. GIAO DIỆN CHÍNH MÀN HÌNH YÊU THÍCH ──
class BookmarkScreen extends StatefulWidget {
  final bool isDark;
  const BookmarkScreen({super.key, this.isDark = false});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu ngay khi vừa mở tab Yêu thích lên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState().isLoggedIn) {
        BookmarkState().fetchBookmarks();
      }
    });
  }

  void _onLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(isDark: widget.isDark)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe cả thay đổi từ Auth (Đăng nhập) và BookmarkState (Tải API)
    return AnimatedBuilder(
      animation: Listenable.merge([AuthState(), BookmarkState()]),
      builder: (context, child) {
        final currentAuth = AuthState();
        final bookmarkState = BookmarkState();

        if (!currentAuth.isLoggedIn) {
          return _GuestBookmark(onLogin: _onLogin, isDark: widget.isDark);
        }

        // Hiện vòng xoay loading lúc đang gọi API
        if (bookmarkState.isLoading) {
          return Scaffold(
            backgroundColor: widget.isDark
                ? AuroraColors.deepSpace
                : const Color(0xFFF5F7F5),
            appBar: _buildAppBar(widget.isDark),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return _BookmarkList(isDark: widget.isDark);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Yêu thích',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: isDark ? Colors.white : AppColors.black,
        ),
      ),
    );
  }
}

// ── 4. GIAO DIỆN KHI CHƯA ĐĂNG NHẬP ──
class _GuestBookmark extends StatelessWidget {
  final VoidCallback onLogin;
  final bool isDark;

  const _GuestBookmark({required this.onLogin, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Yêu thích',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: textColor,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border_rounded,
                    size: 80, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Lưu giữ khoảnh khắc',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Đăng nhập để lưu lại những địa điểm bạn muốn đến và xem lại bất cứ lúc nào trên mọi thiết bị.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    color: subColor,
                    height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: const Text('Đăng nhập ngay',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 5. GIAO DIỆN DANH SÁCH YÊU THÍCH (ĐÃ ĐĂNG NHẬP) ──
class _BookmarkList extends StatelessWidget {
  final bool isDark;

  const _BookmarkList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final textColor = isDark ? Colors.white : AppColors.black;
    final bookmarks = BookmarkState().items;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Yêu thích',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: textColor,
          ),
        ),
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline_rounded,
                      size: 80,
                      color: isDark
                          ? Colors.white24
                          : AppColors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có địa điểm nào được lưu.',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        color: isDark ? Colors.white54 : AppColors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final item = bookmarks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BookmarkCard(
                    bookmark: item,
                    isDark: isDark,
                    onRemove: () {
                      BookmarkState().removeBookmark(item.id);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã bỏ lưu ${item.name}',
                              style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily)),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          action: SnackBarAction(
                            label: 'Hoàn tác',
                            textColor: AppColors.primaryLight,
                            onPressed: () =>
                                BookmarkState().toggleBookmark(item.id, item),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ── 6. THẺ MỘT MỤC YÊU THÍCH ──
class _BookmarkCard extends StatelessWidget {
  final BookmarkItem bookmark;
  final bool isDark;
  final VoidCallback onRemove;

  const _BookmarkCard({
    required this.bookmark,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: bookmark.color,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(bookmark.icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bookmark.name,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(bookmark.province,
                      style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: bookmark.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(bookmark.category,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11,
                                color: bookmark.color,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 16),
                      const SizedBox(width: 2),
                      Text(bookmark.rating.toString(),
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_remove_rounded,
                  color: AppColors.primary, size: 24),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
