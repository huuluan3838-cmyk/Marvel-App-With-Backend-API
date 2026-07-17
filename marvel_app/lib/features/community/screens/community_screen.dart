import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/features/community/screens/create_post_screen.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart'; // Import màn hình xác thực (AuthScreen và AuthState)
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

// ── CẤU HÌNH API ──
final String apiUrl = ApiConfig.baseUrl;

// ── Model Dữ liệu từ API ────────────────────────────────────────────────────────
class CommunityPost {
  final int id;
  final String authorName;
  final String authorAvatar;
  final String timeAgo;
  final String title;
  final String contentSnippet;
  final String imagePath;
  final String category;
  int likes;
  int comments;
  int shares;
  bool isLiked;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.timeAgo,
    required this.title,
    required this.contentSnippet,
    required this.imagePath,
    required this.category,
    required this.likes,
    required this.comments,
    this.shares = 0,
    this.isLiked = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // Xử lý thời gian hiển thị (VD: "2 giờ trước")
    String timeAgoStr = 'Vừa xong';
    if (json['ngayDang'] != null) {
      DateTime postDate = DateTime.parse(json['ngayDang']);
      Duration diff = DateTime.now().difference(postDate);
      if (diff.inDays > 0) {
        timeAgoStr = '${diff.inDays} ngày trước';
      } else if (diff.inHours > 0) {
        timeAgoStr = '${diff.inHours} giờ trước';
      } else if (diff.inMinutes > 0) {
        timeAgoStr = '${diff.inMinutes} phút trước';
      }
    }

    String normalize(dynamic val) {
      final raw = val?.toString().trim() ?? '';
      if (raw.isEmpty) return '';
      if (raw.toLowerCase().startsWith('http')) return raw;
      final clean = raw.startsWith('/') ? raw.substring(1) : raw;
      if (clean.toLowerCase().startsWith('assets/')) return clean;
      return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/${raw.startsWith('/') ? raw.substring(1) : raw}';
    }

    return CommunityPost(
      id: json['maBaiViet'] ?? 0,
      authorName:
          'User ${json['maNguoiDung']}', // Tạm dùng ID nếu API chưa join bảng User
      authorAvatar: 'U',
      timeAgo: timeAgoStr,
      title: json['tieuDe'] ?? '',
      contentSnippet: json['noiDung'] ?? '',
      imagePath: normalize(json['hinhAnh']),
      category: json['theLoai'] ?? 'Khác',
      likes: json['luotThich'] ?? 0,
      comments: json['luotBinhLuan'] ?? 0,
      shares: json['luotChiaSe'] ?? 0,
      isLiked: json['isLiked'] == true,
    );
  }
}

// ── Giao diện chính ───────────────────────────────────────────────────────────
class CommunityScreen extends StatefulWidget {
  final bool isDark;
  const CommunityScreen({super.key, this.isDark = false});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'Mới nhất';
  final List<String> _categories = [
    'Mới nhất',
    'Review',
    'Kinh nghiệm',
    'Check-in',
    'Lịch trình',
    'Khác'
  ];

  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _realtimeTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _refreshPostStats());
    AuthState().addListener(_fetchPosts);
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    AuthState().removeListener(_fetchPosts);
    super.dispose();
  }

  // GỌI API LẤY DANH SÁCH BÀI VIẾT
  Future<void> _fetchPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final Map<String, String> headers = {};
      if (AuthState().token != null) {
        headers['Authorization'] = 'Bearer ${AuthState().token}';
      }

      final response =
          await http.get(Uri.parse('$apiUrl/BaiViet'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _posts = data.map((json) => CommunityPost.fromJson(json)).toList();
          });
        }
      } else {
        _showMessage('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Không thể kết nối đến máy chủ.');
      debugPrint('Lỗi fetchPosts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Lọc bài viết theo danh mục

  Future<void> _refreshPostStats() async {
    if (!mounted || _posts.isEmpty) return;
    try {
      final ids = _posts.map((p) => p.id).join(',');
      final headers = <String, String>{};
      if (AuthState().token != null) {
        headers['Authorization'] = 'Bearer ${AuthState().token}';
      }
      final response = await http.get(Uri.parse('$apiUrl/BaiViet/stats?ids=$ids'), headers: headers);
      if (response.statusCode != 200) return;
      final List<dynamic> data = jsonDecode(response.body);
      final stats = <int, Map<String, dynamic>>{};
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final id = map['maBaiViet'] is int ? map['maBaiViet'] as int : int.tryParse(map['maBaiViet']?.toString() ?? '0') ?? 0;
        if (id > 0) stats[id] = map;
      }
      setState(() {
        for (final post in _posts) {
          final stat = stats[post.id];
          if (stat == null) continue;
          post.likes = stat['luotThich'] ?? post.likes;
          post.comments = stat['luotBinhLuan'] ?? post.comments;
          post.shares = stat['luotChiaSe'] ?? post.shares;
          post.isLiked = stat['isLiked'] == true;
        }
      });
    } catch (_) {}
  }

  List<CommunityPost> get _filteredPosts {
    if (_selectedCategory == 'Mới nhất') return _posts;
    return _posts.where((p) => p.category == _selectedCategory).toList();
  }

  Future<void> _openCreatePost() async {
    if (!AuthState().isLoggedIn) {
      _showLoginRequired();
      return;
    }

    final draft = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          isDark: widget.isDark,
          categories: _categories,
        ),
      ),
    );
    if (draft != null) {
      final token = AuthState().token;
      if (token == null || token.isEmpty) {
        _showLoginRequired();
        return;
      }

      try {
        final response = await http.post(
          Uri.parse('$apiUrl/BaiViet'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode({
            'tieuDe': draft.title,
            'noiDung': draft.content,
            'theLoai': draft.category,
            'hinhAnh': draft.imagePath.isEmpty ? null : draft.imagePath,
          }),
        );

        if (response.statusCode == 200) {
          _showMessage('Bài viết đang chờ Admin kiểm duyệt!');
          _fetchPosts();
        } else {
          _showMessage('Không thể đăng bài. Mã lỗi: ${response.statusCode}');
        }
      } catch (e) {
        _showMessage('Không thể kết nối máy chủ: $e');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: const TextStyle(fontFamily: AppTextStyles.fontFamily))),
    );
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text('Yêu cầu đăng nhập',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: widget.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        content: Text('Bạn cần đăng nhập để thực hiện tính năng này.',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: widget.isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng',
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // ĐÃ SỬA LỖI Ở ĐÂY: Dùng AuthScreen thay vì LoginScreen
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AuthScreen(isDark: widget.isDark)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Đăng nhập',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_document, color: Colors.white),
        label: const Text('Viết bài',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      // Bọc CustomScrollView bằng RefreshIndicator để vuốt làm mới
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              backgroundColor: bgColor,
              elevation: 0,
              pinned: true,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: textColor, size: 20),
                ),
              ),
              title: Text(
                'Cộng đồng',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: textColor,
                ),
              ),
              centerTitle: true,
            ),

            // ── Thanh Phân loại (Categories) ──
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : AppColors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Danh sách bài viết ──
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _isLoading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                    )
                  : _filteredPosts.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.article_outlined,
                                      size: 64,
                                      color: isDark
                                          ? Colors.white24
                                          : AppColors.grey.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có bài viết nào',
                                    style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.grey,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _CommunityPostCard(
                                  post: _filteredPosts[index],
                                  isDark: isDark,
                                  onLikeToggled: _refreshPostStats,
                                  onRequireLogin: _showLoginRequired,
                                ),
                              );
                            },
                            childCount: _filteredPosts.length,
                          ),
                        ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ── Widget Thẻ Bài Viết ────────────────────────────────────────────────────────
class _CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final bool isDark;
  final VoidCallback onLikeToggled;
  final VoidCallback onRequireLogin;

  const _CommunityPostCard({
    required this.post,
    required this.isDark,
    required this.onLikeToggled,
    required this.onRequireLogin,
  });

  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  // GỌI API LIKE BÀI VIẾT
  Future<void> _toggleLike() async {
    if (!AuthState().isLoggedIn) {
      widget.onRequireLogin();
      return;
    }

    final token = AuthState().token;
    if (token == null || token.isEmpty) {
      widget.onRequireLogin();
      return;
    }

    setState(() {
      widget.post.isLiked = !widget.post.isLiked;
      widget.post.likes += widget.post.isLiked ? 1 : -1;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/BaiViet/like/${widget.post.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            widget.post.likes = data['luotThich'] ?? widget.post.likes;
            widget.post.isLiked = data['isLiked'] == true;
          });
        }
        widget.onLikeToggled();
      } else {
        setState(() {
          widget.post.isLiked = !widget.post.isLiked;
          widget.post.likes += widget.post.isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      debugPrint('Lỗi Like API: $e');
      if (mounted) {
        setState(() {
          widget.post.isLiked = !widget.post.isLiked;
          widget.post.likes += widget.post.isLiked ? 1 : -1;
        });
      }
    }
  }

  // GỌI API BÁO CÁO VI PHẠM
  Future<void> _reportPost(String reason) async {
    if (!AuthState().isLoggedIn) {
      widget.onRequireLogin();
      return;
    }

    final token = AuthState().token;
    if (token == null || token.isEmpty) {
      widget.onRequireLogin();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/BaiViet/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'maBaiViet': widget.post.id,
          'lyDo': reason,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cảm ơn bạn. Đội ngũ kiểm duyệt sẽ xử lý.',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi Report API: $e');
    }
  }

  // Tùy chọn bài viết (3 chấm)
  void _showPostOptions(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined,
                  color: Colors.redAccent),
              title: const Text('Báo cáo vi phạm',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _showReportReasons(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility_off_outlined, color: textColor),
              title: Text('Ẩn bài viết này',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily, color: textColor)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Đã ẩn bài viết',
                        style:
                            TextStyle(fontFamily: AppTextStyles.fontFamily))));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportReasons(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.black;
    final reasons = [
      'Spam hoặc lừa đảo',
      'Nội dung phản cảm',
      'Vi phạm bản quyền',
      'Thông tin sai lệch',
      'Khác'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Lý do báo cáo',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor)),
            ),
            const SizedBox(height: 8),
            ...reasons.map((reason) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(reason,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPost(reason);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommentsSheet() async {
    final controller = TextEditingController();
    List<dynamic> comments = [];
    bool loading = true;

    Future<void> load(StateSetter setModalState) async {
      setModalState(() => loading = true);
      try {
        comments =
            await ExtendedApiService.getBinhLuanByBaiViet(widget.post.id);
      } catch (e) {
        debugPrint('Lỗi tải bình luận: $e');
      } finally {
        setModalState(() => loading = false);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (loading && comments.isEmpty) {
            Future.microtask(() => load(setModalState));
          }
          final bottom = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bình luận',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: widget.isDark
                                ? Colors.white
                                : AppColors.black)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : comments.isEmpty
                              ? const Center(
                                  child: Text('Chưa có bình luận.',
                                      style: TextStyle(
                                          fontFamily:
                                              AppTextStyles.fontFamily)))
                              : ListView.separated(
                                  itemCount: comments.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (_, i) {
                                    final item =
                                        comments[i] as Map<String, dynamic>;
                                    return ListTile(
                                      leading: const CircleAvatar(
                                          child: Icon(Icons.person)),
                                      title: Text(
                                          item['hoTen']?.toString() ??
                                              'Người dùng',
                                          style: const TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                          item['noiDung']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily)),
                                    );
                                  },
                                ),
                    ),
                    if (AuthState().isLoggedIn) ...[
                      TextField(
                          controller: controller,
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily),
                          decoration: const InputDecoration(
                              hintText: 'Nhập bình luận...',
                              hintStyle: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily))),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            try {
                              await ExtendedApiService.createBinhLuan(
                                  maBaiViet: widget.post.id, noiDung: text);
                              controller.clear();
                              widget.post.comments++;
                              await load(setModalState);
                              if (mounted) setState(() {});
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Không gửi được bình luận: $e',
                                            style: const TextStyle(
                                                fontFamily: AppTextStyles
                                                    .fontFamily))));
                            }
                          },
                          child: const Text('Gửi',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily)),
                        ),
                      ),
                    ] else
                      const Text('Đăng nhập để bình luận.',
                          style:
                              TextStyle(fontFamily: AppTextStyles.fontFamily)),
                  ]),
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final post = widget.post;
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white60 : AppColors.grey;

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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Tên + Thời gian
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        post.authorAvatar,
                        style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textColor),
                          ),
                          Row(
                            children: [
                              Text(post.timeAgo,
                                  style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      color: subColor)),
                              const SizedBox(width: 8),
                              Icon(Icons.public, size: 12, color: subColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: subColor),
                      onPressed: () => _showPostOptions(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Nội dung Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: textColor,
                          height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.contentSnippet,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Hình ảnh đính kèm (Xử lý cả ảnh cục bộ Asset và ảnh URL mạng)
              if (post.imagePath.isNotEmpty)
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: post.imagePath.startsWith('http')
                      ? Image.network(post.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox())
                      : Image.asset(post.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                ),

              // Tương tác (Like, Comment, Share)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: _InteractionButton(
                        icon: post.isLiked
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_alt_outlined,
                        label: post.likes.toString(),
                        color: post.isLiked ? AppColors.primary : subColor,
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _showCommentsSheet,
                      child: _InteractionButton(
                        icon: Icons.mode_comment_outlined,
                        label: post.comments.toString(),
                        color: subColor,
                      ),
                    ),
                    const Spacer(),
                    _InteractionButton(
                      icon: Icons.share_outlined,
                      label: post.shares > 0 ? post.shares.toString() : 'Chia sẻ',
                      color: subColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InteractionButton(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color),
        ),
      ],
    );
  }
}
