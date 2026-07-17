import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool isDark;
  const PrivacyPolicyScreen({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Quyền riêng tư',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Chính sách này giải thích cách chúng tôi thu thập và sử dụng dữ liệu.',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: subColor),
          ),
          const SizedBox(height: 16),
          _PolicyItem(
            isDark: isDark,
            title: 'Dữ liệu thu thập',
            content:
                'Thông tin tài khoản, vị trí (nếu được cho phép), lịch sử tìm kiếm và tương tác trong ứng dụng.',
          ),
          const SizedBox(height: 12),
          _PolicyItem(
            isDark: isDark,
            title: 'Mục đích sử dụng',
            content:
                'Cá nhân hóa nội dung, đề xuất điểm đến phù hợp và cải thiện trải nghiệm người dùng.',
          ),
          const SizedBox(height: 12),
          _PolicyItem(
            isDark: isDark,
            title: 'Chia sẻ dữ liệu',
            content:
                'Chúng tôi không bán dữ liệu. Dữ liệu chỉ chia sẻ khi có sự đồng ý hoặc yêu cầu pháp lý.',
          ),
          const SizedBox(height: 12),
          _PolicyItem(
            isDark: isDark,
            title: 'Quyền kiểm soát',
            content:
                'Bạn có thể quản lý quyền truy cập trong phần Cài đặt và yêu cầu xoá dữ liệu cá nhân.',
          ),
          const SizedBox(height: 16),
          _PolicyItem(
            isDark: isDark,
            title: 'Liên hệ',
            content: 'support@marveltravel.vn | 1900 123 456',
          ),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final bool isDark;
  final String title;
  final String content;

  const _PolicyItem({
    required this.isDark,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: subColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
