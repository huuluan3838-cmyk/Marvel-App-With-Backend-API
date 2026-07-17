import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class PersonalInfoScreen extends StatefulWidget {
  final bool isDark;
  const PersonalInfoScreen({super.key, this.isDark = false});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _bioCtrl;

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: AuthState().username);
    _emailCtrl = TextEditingController(text: AuthState().email);
    _phoneCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _bioCtrl = TextEditingController();

    _loadProfile();
    _nameCtrl.addListener(_syncHeader);
    _emailCtrl.addListener(_syncHeader);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_syncHeader);
    _emailCtrl.removeListener(_syncHeader);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _syncHeader() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ExtendedApiService.getProfile();
      if (mounted) {
        setState(() {
          _nameCtrl.text = data['hoTen']?.toString() ?? AuthState().username;
          _emailCtrl.text = data['email']?.toString() ?? AuthState().email;
          _phoneCtrl.text = data['soDienThoai']?.toString() ?? '';
          _locationCtrl.text = data['diaChi']?.toString() ?? '';
          _bioCtrl.text = data['gioiThieu']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin cá nhân: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ExtendedApiService.updateProfile(
        hoTen: _nameCtrl.text.trim(),
        soDienThoai: _phoneCtrl.text.trim(),
      );
      // Đồng bộ vào AuthState để màn hình khác cập nhật theo
      AuthState().updateProfileState(
        inputName: _nameCtrl.text.trim(),
        inputEmail: _emailCtrl.text.trim(),
      );
      _showMessage('Đã lưu cập nhật thông tin.');
    } catch (e) {
      _showMessage('Không thể cập nhật: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _startVerify() {
    _showMessage('Đã gửi yêu cầu xác minh tài khoản.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
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
          'Thông tin cá nhân',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(
                isDark: isDark,
                name: _nameCtrl.text,
                email: _emailCtrl.text,
                onAvatarTap: () => _showMessage('Đang tải ảnh đại diện...')),
            const SizedBox(height: 20),
            _SectionTitle(text: 'Thông tin cơ bản', isDark: isDark),
            const SizedBox(height: 12),
            _InfoField(
                label: 'Họ và tên', controller: _nameCtrl, isDark: isDark),
            const SizedBox(height: 12),
            _InfoField(label: 'Email', controller: _emailCtrl, isDark: isDark, readOnly: true),
            const SizedBox(height: 12),
            _InfoField(
                label: 'Số điện thoại', controller: _phoneCtrl, isDark: isDark),
            const SizedBox(height: 12),
            _InfoField(
                label: 'Khu vực', controller: _locationCtrl, isDark: isDark),
            const SizedBox(height: 20),
            _SectionTitle(text: 'Giới thiệu', isDark: isDark),
            const SizedBox(height: 12),
            _InfoField(
                label: 'Về tôi',
                controller: _bioCtrl,
                isDark: isDark,
                maxLines: 4),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Xác minh tài khoản để tăng độ tin cậy khi chia sẻ bài viết.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: subColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _startVerify,
                    child: const Text(
                      'Bắt đầu',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool isDark;
  final String name;
  final String email;
  final VoidCallback? onAvatarTap;

  const _ProfileHeader(
      {required this.isDark,
      required this.name,
      required this.email,
      this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004311), Color(0xFF00AE2C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tài khoản cá nhân',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAvatarTap,
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
          ),
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

class _InfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final int maxLines;
  final bool readOnly;

  const _InfoField({
    required this.label,
    required this.controller,
    required this.isDark,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final fillColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: readOnly ? (isDark ? Colors.white54 : Colors.black54) : textColor,
              fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
