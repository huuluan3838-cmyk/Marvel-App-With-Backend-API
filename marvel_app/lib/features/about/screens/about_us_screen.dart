import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

// Import các màn hình để điều hướng
import 'package:marvel_travel/features/itinerary/screens/itinerary_screen.dart';
import 'package:marvel_travel/features/guide/screens/guide_screen.dart';
import 'package:marvel_travel/features/destinations/screens/map_screen.dart';
import 'package:marvel_travel/features/community/screens/community_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/shared/widgets/login_dialog.dart';

class AboutUsScreen extends StatelessWidget {
  final bool isDark;

  const AboutUsScreen({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final subtitleColor = isDark ? Colors.white70 : AppColors.grey;
    final cardBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor:
          isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
            centerTitle: true,
            title: Text(
              'Về chúng tôi',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ),

          // ── Nội dung chính ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Logo & Tên App
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF32D445), Color(0xFF004311)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo2.jpg',
                            fit: BoxFit.scaleDown,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.landscape,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          stops: marvelTitleStops,
                          colors: marvelTitleColors,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Text(
                          'Marvel Travel',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Khơi Nguồn Trải Nghiệm, Lan Tỏa Giá Trị',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 2. Sứ mệnh (Mission)
                Text(
                  'Sứ mệnh của chúng tôi',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Khơi Nguồn Trải Nghiệm, Lan Tỏa Giá Trị.\n\nMarvel Travel là nền tảng kết nối những người đam mê xê dịch, giúp bạn dễ dàng khám phá vẻ đẹp của Việt Nam, lập lịch trình thông minh và chia sẻ những khoảnh khắc đáng nhớ cùng cộng đồng.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Tính năng nổi bật (Có thể Click)
                Text(
                  'Tại sao chọn Marvel?',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Lập lịch trình thông minh',
                  description: 'Tự động gợi ý và tối ưu hóa chuyến đi của bạn.',
                  isDark: isDark,
                  onTap: () {
                    if (!AuthState().isLoggedIn) {
                      showLoginRequiredDialog(context,
                          featureName: 'Lập lịch trình', isDark: isDark);
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ItineraryScreen(isDark: isDark)));
                  },
                ),
                const SizedBox(height: 12),
                _FeatureRow(
                  icon: Icons.explore_rounded,
                  title: 'Cẩm nang du lịch',
                  description:
                      'Trang bị kiến thức, mẹo vặt cho chuyến đi hoàn hảo.',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GuideScreen(isDark: isDark))),
                ),
                const SizedBox(height: 12),
                _FeatureRow(
                  icon: Icons.public_rounded,
                  title: 'Cộng đồng đam mê',
                  description:
                      'Kết nối, đánh giá và chia sẻ kinh nghiệm du lịch.',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CommunityScreen(isDark: isDark))),
                ),
                const SizedBox(height: 12),
                _FeatureRow(
                  icon: Icons.map_rounded,
                  title: 'Bản đồ tương tác',
                  description:
                      'Khám phá các điểm đến hấp dẫn trên khắp Việt Nam.',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MapScreen(isDark: isDark))),
                ),
                const SizedBox(height: 40),

                // 4. Thông tin liên hệ
                Text(
                  'Liên hệ',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ContactTile(
                        icon: Icons.language,
                        title: 'Website',
                        subtitle: 'www.marveltravel.vn',
                        isDark: isDark,
                      ),
                      Divider(
                          height: 1,
                          indent: 56,
                          color: isDark ? Colors.white10 : Colors.grey[300]),
                      _ContactTile(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        subtitle: 'support@marveltravel.vn',
                        isDark: isDark,
                      ),
                      Divider(
                          height: 1,
                          indent: 56,
                          color: isDark ? Colors.white10 : Colors.grey[300]),
                      _ContactTile(
                        icon: Icons.phone_outlined,
                        title: 'Hotline',
                        subtitle: '1900 1234',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Footer
                Center(
                  child: Text(
                    '© 2026 Marvel Travel. All rights reserved.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: subtitleColor.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Các Widget Phụ Trợ ──

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final VoidCallback onTap;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? Colors.white30 : AppColors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          color: isDark ? Colors.white70 : AppColors.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white30 : AppColors.grey,
        size: 18,
      ),
      onTap: () {
        // Xử lý sự kiện mở link / gọi điện
      },
    );
  }
}
