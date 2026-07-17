import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marvel_travel/features/auth/screens/register_screen.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart' hide RegisterScreen;
import 'package:marvel_travel/features/about/screens/about_us_screen.dart';
import 'package:marvel_travel/features/itinerary/screens/my_itineraries_screen.dart';
import 'package:marvel_travel/features/bookmarks/screens/bookmark_screen.dart';
import 'package:marvel_travel/features/profile/screens/personal_info_screen.dart';
import 'package:marvel_travel/features/notifications/screens/notifications_screen.dart';
import 'package:marvel_travel/features/settings/screens/security_screen.dart';
import 'package:marvel_travel/features/reviews/screens/reviews_screen.dart';
import 'package:marvel_travel/features/support/screens/help_screen.dart';
import 'package:marvel_travel/features/settings/screens/settings_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

String _avatarUrl(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final relative = value.startsWith('/') ? value.substring(1) : value;
  return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/$relative';
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onAuthChanged;
  final bool isDark;
  const ProfileScreen({super.key, this.onAuthChanged, this.isDark = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthState(),
      builder: (context, child) {
        final currentAuth = AuthState();
        if (!currentAuth.isLoggedIn) {
          return _GuestProfile(onLogin: _onLogin, isDark: widget.isDark);
        }

        return _LoggedProfile(
          username: currentAuth.username,
          email: currentAuth.email,
          avatarUrl: currentAuth.avatarUrl,
          onLogout: _onLogout,
          isDark: widget.isDark,
        );
      },
    );
  }

  Future<void> _onLogin() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (ok == true) {
      setState(() {});
      widget.onAuthChanged?.call();
    }
  }

  Future<void> _onLogout() async {
    await AuthState().logout();
    setState(() {});
    widget.onAuthChanged?.call();
  }
}

class _GuestProfile extends StatelessWidget {
  final VoidCallback onLogin;
  final bool isDark;
  const _GuestProfile({required this.onLogin, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF32D445), Color(0xFF004311)]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withAlpha(76),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child:
                      const Icon(Icons.person, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text('Chưa đăng nhập',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 8),
                Text(
                    'Đăng nhập để lưu địa điểm, tạo lịch trình, bình luận và đánh giá trong Marvel Travel.',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : AppColors.grey),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('Đăng nhập',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('Tạo tài khoản mới',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoggedProfile extends StatefulWidget {
  final String username;
  final String email;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final bool isDark;
  const _LoggedProfile({
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.onLogout,
    this.isDark = false,
  });

  @override
  State<_LoggedProfile> createState() => _LoggedProfileState();
}

class _LoggedProfileState extends State<_LoggedProfile> {
  bool _uploading = false;

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (picked == null) return;
      setState(() => _uploading = true);
      final profile = await ExtendedApiService.uploadAvatar(File(picked.path));
      AuthState().updateProfileState(
        inputName: profile['hoTen']?.toString(),
        inputEmail: profile['email']?.toString(),
        inputAvatarUrl: profile['anhDaiDien']?.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không upload được ảnh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final avatar = _avatarUrl(AuthState().avatarUrl ?? widget.avatarUrl);
    return Scaffold(
      backgroundColor:
          isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF004311), Color(0xFF00AE2C)]),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploading ? null : _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(51),
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: avatar.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 52, color: Colors.white)
                                  : Image.network(avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: Colors.white)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white),
                                child: _uploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(7),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      )
                                    : const Icon(Icons.camera_alt,
                                        size: 16, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.username,
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(widget.email,
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              color: Colors.white.withAlpha(204))),
                      const SizedBox(height: 8),
                      const Text('Chạm vào ảnh để thay đổi ảnh đại diện',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(title: 'Tài khoản', isDark: isDark, items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Thông tin cá nhân',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalInfoScreen(isDark: isDark),
                  ),
                ),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Thông báo',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(isDark: isDark),
                  ),
                ),
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                label: 'Bảo mật',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SecurityScreen(isDark: isDark),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _Section(title: 'Hoạt động', isDark: isDark, items: [
              _MenuItem(
                icon: Icons.bookmark_outline,
                label: 'Địa điểm yêu thích',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookmarkScreen(isDark: isDark)),
                ),
              ),
              _MenuItem(
                icon: Icons.rate_review_outlined,
                label: 'Đánh giá của tôi',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewsScreen(isDark: isDark),
                  ),
                ),
              ),
              _MenuItem(
                icon: Icons.calendar_month_outlined,
                label: 'Lịch trình của tôi',
                isDark: isDark,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MyItinerariesScreen(isDark: isDark))),
              ),
            ]),
            const SizedBox(height: 12),
            _Section(title: 'Khác', isDark: isDark, items: [
              _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Về chúng tôi',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AboutUsScreen(isDark: isDark)))),
              _MenuItem(
                icon: Icons.help_outline,
                label: 'Trợ giúp',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelpScreen(isDark: isDark),
                  ),
                ),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(isDark: isDark),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Đăng xuất',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<_MenuItem> items;
  const _Section(
      {required this.title, this.isDark = false, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title,
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.grey,
                      letterSpacing: 0.5)),
            ),
            Container(
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 76 : 10),
                        blurRadius: 8)
                  ]),
              child: Column(
                children: List.generate(
                    items.length,
                    (i) => Column(
                          children: [
                            items[i],
                            if (i < items.length - 1)
                              Divider(
                                  height: 1,
                                  indent: 56,
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey[300]),
                          ],
                        )),
              ),
            ),
          ],
        ),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      this.isDark = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black)),
        trailing: Icon(Icons.chevron_right,
            color: isDark ? Colors.white30 : AppColors.grey, size: 18),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );
}
