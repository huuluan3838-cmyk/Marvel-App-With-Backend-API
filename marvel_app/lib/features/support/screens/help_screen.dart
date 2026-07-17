import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart'; // Import AuthState và AuthScreen
import 'package:marvel_travel/features/support/screens/support_request_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class HelpScreen extends StatefulWidget {
  final bool isDark;
  const HelpScreen({super.key, this.isDark = false});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // Đưa list FAQs về static const để tối ưu hiệu suất, không bị gạch vàng báo tạo lại mỗi lần build
  static const List<Map<String, String>> _faqs = [
    {
      'question': 'Làm sao tạo lịch trình mới?',
      'answer':
          'Bạn có thể vào mục "Khám phá", chọn điểm đến yêu thích và nhấn nút "Lên lịch trình tự động". Hệ thống AI sẽ dựa trên số ngày và phong cách bạn chọn để tối ưu lộ trình tốt nhất.'
    },
    {
      'question': 'Làm sao lưu địa điểm yêu thích?',
      'answer':
          'Tại trang chi tiết của mỗi địa danh, nhấn vào biểu tượng Bookmark (Lưu) ở góc phải trên cùng của màn hình. Địa điểm sẽ được lưu lại trong mục "Yêu thích".'
    },
    {
      'question': 'Tôi muốn báo cáo nội dung không phù hợp?',
      'answer':
          'Vui lòng nhấn vào nút "Gửi yêu cầu hỗ trợ", chọn mục "Báo cáo vi phạm" và điền thông tin chi tiết kèm hình ảnh minh chứng để ban quản trị xử lý trong vòng 24h.'
    },
    {
      'question': 'Làm sao đổi mật khẩu?',
      'answer':
          'Vào mục "Cá nhân" (Profile), chọn "Cài đặt tài khoản" -> "Đổi mật khẩu", nhập mật khẩu hiện tại và mật khẩu mới của bạn để cập nhật bảo mật.'
    },
  ];

  // Hàm hiển thị Dialog yêu cầu đăng nhập
  void _showLoginRequiredDialog(BuildContext context, String actionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yêu cầu đăng nhập',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: widget.isDark ? Colors.white : AppColors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn cần đăng nhập tài khoản để hệ thống xác định danh tính và hỗ trợ $actionName tốt nhất.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: widget.isDark ? Colors.white70 : AppColors.grey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog thông báo
                // ĐÃ SỬA LỖI: Dùng AuthScreen thay vì LoginScreen để tránh báo lỗi đỏ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AuthScreen(isDark: widget.isDark)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Đăng nhập ngay',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // HÀM KIỂM TRA RÀNG BUỘC ĐĂNG NHẬP KHI TƯƠNG TÁC HỖ TRỢ
  void _handleSupportAction(String actionDetail, VoidCallback onGranted) {
    final isLoggedIn = AuthState().isLoggedIn;

    if (!isLoggedIn) {
      _showLoginRequiredDialog(context, actionDetail);
    } else {
      onGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor:
          isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black12,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Trợ giúp',
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Chúng tôi luôn sẵn sàng hỗ trợ bạn trong mọi hành trình.',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: subColor),
          ),
          const SizedBox(height: 20),

          // ── KHỐI LIÊN HỆ NHANH (QUICK CONTACT) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: isDark ? Colors.black38 : Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildContactTile(
                  icon: Icons.email_outlined,
                  title: 'support@marveltravel.vn',
                  subtitle: 'Phản hồi trong 24h',
                  onTap: () => _handleSupportAction('gửi thư hỗ trợ', () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Đang mở ứng dụng Email gửi từ tài khoản: ${AuthState().email}',
                              style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily)),
                          behavior: SnackBarBehavior.floating),
                    );
                  }),
                  isDark: isDark,
                ),
                const Divider(height: 20),
                _buildContactTile(
                  icon: Icons.phone_in_talk_rounded,
                  title: '1900 123 456',
                  subtitle: 'Thứ 2 - Chủ nhật, 8:00 - 20:00',
                  onTap: () => _handleSupportAction('gọi tổng đài cứu trợ', () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Đang kích hoạt cuộc gọi đến tổng đài CSKH...',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily)),
                          behavior: SnackBarBehavior.floating),
                    );
                  }),
                  isDark: isDark,
                ),
                const Divider(height: 20),
                _buildContactTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Live chat',
                  subtitle: 'Nhận tư vấn trực tiếp',
                  onTap: () => _handleSupportAction('kết nối trực tuyến', () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Xin chào ${AuthState().username}, tổng đài viên hỗ trợ đang kết nối!',
                            style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // NÚT CHÍNH: CHUYỂN HƯỚNG SANG SUPPORT_REQUEST_SCREEN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () =>
                        _handleSupportAction('tạo phiếu yêu cầu', () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupportRequestScreen(isDark: widget.isDark),
                        ),
                      );
                    }),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Gửi yêu cầu hỗ trợ',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── KHỐI CÂU HỎI THƯỜNG GẶP (FAQ LIST) ──
          Text(
            'Câu hỏi thường gặp',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              return Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  iconColor: AppColors.primary,
                  collapsedIconColor: isDark ? Colors.white60 : AppColors.grey,
                  title: Text(
                    faq['question']!,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textColor),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq['answer']!,
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            color: subColor,
                            height: 1.4),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : AppColors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(
                    0.1), // Đã sửa lại thành withOpacity để chống gạch vàng ở phiên bản Flutter mới
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: subColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }
}
