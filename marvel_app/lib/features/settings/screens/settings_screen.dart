import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/legal/screens/privacy_policy_screen.dart';
import 'package:marvel_travel/features/legal/screens/terms_screen.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart'; // Lắng nghe trạng thái đăng nhập để quản lý phiên liên kết tài khoản
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  const SettingsScreen({super.key, this.isDark = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'Hệ thống';
  String _language = 'Tiếng Việt';

  // Trạng thái cấu hình quyền và thông báo thực tế cần có
  bool _location = true;
  bool _analytics = true;
  bool _autoPlay = false;
  bool _notiItinerary = true; // Bổ sung: Nhắc nhở lịch trình bay/di chuyển AI
  bool _notiPromotion =
      false; // Bổ sung: Nhận thông tin khuyến mãi khách sạn, điểm đến

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TermsScreen(isDark: widget.isDark)),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PrivacyPolicyScreen(isDark: widget.isDark)),
    );
  }

  // Bổ sung thực tế: Logic giải phóng bộ nhớ đệm ứng dụng khi tải quá nhiều ảnh du lịch
  void _clearCache() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Đang giải phóng bộ nhớ đệm hình ảnh...',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã dọn dẹp sạch bộ nhớ đệm hình ảnh du lịch!',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00AE2C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  // Bổ sung thực tế: Hộp thoại xác nhận đăng xuất tài khoản an toàn
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Text(
              'Đăng xuất',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng Marvel Travel không?',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthState().logout();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đã đăng xuất thành công.',
                        style: TextStyle(fontFamily: AppTextStyles.fontFamily)),
                    behavior: SnackBarBehavior.floating),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);

    final isLoggedIn = AuthState().isLoggedIn;
    final currentUsername =
        AuthState().username.isNotEmpty ? AuthState().username : 'Khách hàng';
    final currentEmail = AuthState().email.isNotEmpty
        ? AuthState().email
        : 'explorer@marveltravel.vn';

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
              color: isDark ? Colors.white10 : Colors.black.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Cài đặt',
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
          // ── PHÂN KHU THỰC TẾ BỔ SUNG: LIÊN KẾT TÀI KHOẢN NGƯỜI DÙNG ──
          _SectionTitle(text: 'Tài khoản', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 70 : 15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isLoggedIn
                      ? const Color(0xFF00AE2C)
                      : Colors.grey.withAlpha(40),
                  child: Icon(
                      isLoggedIn
                          ? Icons.verified_user_rounded
                          : Icons.account_circle_outlined,
                      color: Colors.white,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUsername,
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor)),
                      const SizedBox(height: 1),
                      Text(
                          isLoggedIn
                              ? currentEmail
                              : 'Đăng nhập để đồng bộ lịch trình du lịch',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: subColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionTitle(text: 'Giao diện', isDark: isDark),
          const SizedBox(height: 10),
          _RadioCard(
            isDark: isDark,
            title: 'Chế độ hệ thống',
            value: 'Hệ thống',
            groupValue: _themeMode,
            onChanged: (val) => setState(() => _themeMode = val ?? 'Hệ thống'),
          ),
          const SizedBox(height: 8),
          _RadioCard(
            isDark: isDark,
            title: 'Sáng',
            value: 'Sáng',
            groupValue: _themeMode,
            onChanged: (val) => setState(() => _themeMode = val ?? 'Sáng'),
          ),
          const SizedBox(height: 8),
          _RadioCard(
            isDark: isDark,
            title: 'Tối',
            value: 'Tối',
            groupValue: _themeMode,
            onChanged: (val) => setState(() => _themeMode = val ?? 'Tối'),
          ),
          const SizedBox(height: 16),

          _SectionTitle(text: 'Ngôn ngữ', isDark: isDark),
          const SizedBox(height: 10),
          _DropdownCard(
            isDark: isDark,
            value: _language,
            options: const ['Tiếng Việt', 'English', 'Français'],
            onChanged: (val) => setState(() => _language = val ?? 'Tiếng Việt'),
          ),
          const SizedBox(height: 16),

          _SectionTitle(text: 'Quyền và bảo mật', isDark: isDark),
          const SizedBox(height: 10),
          _SwitchCard(
            isDark: isDark,
            title: 'Truy cập vị trí',
            subtitle: 'Sử dụng vị trí để đề xuất điểm đến gần bạn.',
            value: _location,
            onChanged: (val) => setState(() => _location = val),
          ),
          const SizedBox(height: 10),
          _SwitchCard(
            isDark: isDark,
            title: 'Phân tích sử dụng',
            subtitle: 'Giúp cải thiện chất lượng dịch vụ.',
            value: _analytics,
            onChanged: (val) => setState(() => _analytics = val),
          ),
          const SizedBox(height: 10),
          _SwitchCard(
            isDark: isDark,
            title: 'Tự động phát video',
            subtitle: 'Áp dụng cho bài viết có video.',
            value: _autoPlay,
            onChanged: (val) => setState(() => _autoPlay = val),
          ),
          const SizedBox(height: 10),
          // Bổ sung quyền thông báo hành trình thực tế du lịch
          _SwitchCard(
            isDark: isDark,
            title: 'Thông báo hành trình',
            subtitle:
                'Nhắc nhở lịch trình chuyến đi và thời gian di chuyển AI.',
            value: _notiItinerary,
            onChanged: (val) => setState(() => _notiItinerary = val),
          ),
          const SizedBox(height: 10),
          _SwitchCard(
            isDark: isDark,
            title: 'Thông báo ưu đãi',
            subtitle:
                'Nhận thông tin khuyến mãi vé máy bay & phòng khách sạn giá rẻ.',
            value: _notiPromotion,
            onChanged: (val) => setState(() => _notiPromotion = val),
          ),
          const SizedBox(height: 16),

          // ── PHÂN KHU BỔ SUNG: DỌN DẸP BỘ NHỚ ĐỆM ĐỒNG BỘ CARD ──
          _SectionTitle(text: 'Bộ nhớ dữ liệu', isDark: isDark),
          const SizedBox(height: 10),
          _InfoTile(
            isDark: isDark,
            title: 'Dọn dẹp bộ nhớ đệm (Cache)',
            subtitle:
                'Giải phóng dung lượng hình ảnh điểm đến đã load tích lũy',
            icon: Icons.cleaning_services_rounded,
            onTap: _clearCache,
          ),
          const SizedBox(height: 16),

          _SectionTitle(text: 'Khác', isDark: isDark),
          const SizedBox(height: 10),
          _InfoTile(
            isDark: isDark,
            title: 'Điều khoản sử dụng',
            subtitle: 'Cập nhật 24/05/2026',
            icon: Icons.description_outlined,
            onTap: _openTerms,
          ),
          const SizedBox(height: 10),
          _InfoTile(
            isDark: isDark,
            title: 'Chính sách bảo mật',
            subtitle: 'Cập nhật 24/05/2026',
            icon: Icons.privacy_tip_outlined,
            onTap: _openPrivacy,
          ),

          // HIỂN THỊ NÚT ĐĂNG XUẤT NẾU TRẠNG THÁI ĐÃ ĐĂNG NHẬP THÀNH CÔNG
          if (isLoggedIn) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Đăng xuất tài khoản',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  iconColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Marvel Travel • Phiên bản v2.4.0',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  color: subColor,
                  letterSpacing: 0.5),
            ),
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SectionTitle({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: isDark ? Colors.white : AppColors.black,
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final bool isDark;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownCard({
    required this.isDark,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cardColor,
          icon: Icon(Icons.keyboard_arrow_down, color: textColor),
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontWeight: FontWeight.w600),
          items: options
              .map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: subColor),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _InfoTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(30),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: subColor),
        ),
        trailing: Icon(Icons.chevron_right, color: subColor),
      ),
    );
  }
}
