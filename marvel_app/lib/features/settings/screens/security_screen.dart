import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  final bool isDark;
  const SecurityScreen({super.key, this.isDark = false});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactor = true;
  bool _biometric = false;
  bool _loginAlert = true;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _updatePassword() {
    if (_currentCtrl.text.isEmpty) {
      _showMessage('Vui lòng nhập mật khẩu hiện tại.');
      return;
    }
    if (_newCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _showMessage('Mật khẩu xác nhận không khớp.');
      return;
    }
    _showMessage('Đã cập nhật mật khẩu.');
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
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
          'Bảo mật',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF004311), Color(0xFF00AE2C)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tài khoản an toàn',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kích hoạt đầy đủ các lớp bảo vệ để an tâm hơn.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ToggleCard(
            isDark: isDark,
            title: 'Xác thực 2 bước',
            subtitle: 'Bật mã OTP mỗi lần đăng nhập.',
            value: _twoFactor,
            onChanged: (val) => setState(() => _twoFactor = val),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            isDark: isDark,
            title: 'Đăng nhập sinh trắc học',
            subtitle: 'Sử dụng vân tay/Face ID nếu thiết bị hỗ trợ.',
            value: _biometric,
            onChanged: (val) => setState(() => _biometric = val),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            isDark: isDark,
            title: 'Cảnh báo đăng nhập',
            subtitle: 'Nhận thông báo khi có đăng nhập mới.',
            value: _loginAlert,
            onChanged: (val) => setState(() => _loginAlert = val),
          ),
          const SizedBox(height: 20),
          Text(
            'Đổi mật khẩu',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'Mật khẩu hiện tại',
            controller: _currentCtrl,
            obscure: _obscureCurrent,
            isDark: isDark,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'Mật khẩu mới',
            controller: _newCtrl,
            obscure: _obscureNew,
            isDark: isDark,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'Xác nhận mật khẩu',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            isDark: isDark,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Cập nhật mật khẩu',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Thiết bị đăng nhập',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _DeviceTile(
            isDark: isDark,
            title: 'iPhone 15 Pro',
            subtitle: 'Đăng nhập 2 giờ trước - Hồ Chí Minh',
            icon: Icons.phone_iphone,
            onSignOut: () => _showMessage('Đã đăng xuất iPhone 15 Pro.'),
          ),
          const SizedBox(height: 10),
          _DeviceTile(
            isDark: isDark,
            title: 'Macbook Air',
            subtitle: 'Đăng nhập hôm qua - Hà Nội',
            icon: Icons.laptop_mac,
            onSignOut: () => _showMessage('Đã đăng xuất Macbook Air.'),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
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
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
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
            color: subColor,
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final bool isDark;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.isDark,
    required this.onToggle,
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
          obscureText: obscure,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
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
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textColor,
                  size: 18),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onSignOut;

  const _DeviceTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSignOut,
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
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
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
        trailing: TextButton(
          onPressed: onSignOut,
          child: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
