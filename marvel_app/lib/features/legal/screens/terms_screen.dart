import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  final bool isDark;
  const TermsScreen({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;

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
          'Điều khoản sử dụng',
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
            'Vui lòng đọc kỹ trước khi sử dụng ứng dụng Marvel Travel.',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: subColor),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            isDark: isDark,
            title: '1. Tài khoản & bảo mật',
            content:
                'Bạn chịu trách nhiệm bảo mật thông tin đăng nhập và không chia sẻ với bên thứ ba.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            isDark: isDark,
            title: '2. Nội dung cộng đồng',
            content:
                'Không đăng tải nội dung vi phạm pháp luật, spam hoặc gây ảnh hưởng tiêu cực đến cộng đồng.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            isDark: isDark,
            title: '3. Dữ liệu & quyền sử dụng',
            content:
                'Chúng tôi có thể sử dụng dữ liệu tổng hợp để cải thiện chất lượng dịch vụ và gợi ý cá nhân hóa.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            isDark: isDark,
            title: '4. Thay đổi điều khoản',
            content:
                'Điều khoản có thể được cập nhật và thông báo trên ứng dụng. Việc tiếp tục sử dụng đồng nghĩa với việc chấp thuận thay đổi.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cập nhật gần nhất: 24/05/2026',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String content;

  const _SectionCard({
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
