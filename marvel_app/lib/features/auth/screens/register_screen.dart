import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/shared/widgets/auth/auth_widgets.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDark;
  const RegisterScreen({super.key, this.isDark = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _registerOtpCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isOtpStep = false;
  String _otpContact = '';
  String _otpChannel = 'email';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _registerOtpCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: AppTextStyles.fontFamily)),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _chooseOtpChannel() async {
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (email.isNotEmpty && phone.isNotEmpty) {
      return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ch?n ph??ng th?c nh?n OTP'),
          content: const Text('B?n mu?n nh?n m? x?c nh?n qua email hay s? ?i?n tho?i?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 'email'), child: Text(email)),
            TextButton(onPressed: () => Navigator.pop(context, 'phone'), child: Text(phone)),
          ],
        ),
      );
    }
    if (email.isNotEmpty) return 'email';
    if (phone.isNotEmpty) return 'phone';
    return null;
  }

  Future<void> _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text;
    final confirmPassword = _confirmCtrl.text;

    if (name.isEmpty || password.isEmpty || confirmPassword.isEmpty ||
        (email.isEmpty && phone.isEmpty)) {
      _showSnackBar('Vui l?ng nh?p h? t?n, m?t kh?u v? email ho?c s? ?i?n tho?i!', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('M?t kh?u x?c nh?n kh?ng tr?ng kh?p!', isError: true);
      return;
    }

    final channel = await _chooseOtpChannel();
    if (channel == null) return;
    _otpChannel = channel;
    _otpContact = channel == 'email' ? email : phone;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        ApiConfig.uri('Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hoTen': name,
          'email': email.isEmpty ? null : email,
          'soDienThoai': phone.isEmpty ? null : phone,
          'password': password,
          'otpChannel': channel,
        }),
      ).timeout(const Duration(seconds: 10));
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
      if (response.statusCode == 200) {
        setState(() => _isOtpStep = true);
        _showSnackBar('Đăng ký thành công! Vui lòng kiểm tra mã OTP đã được gửi.', isError: false);
      } else {
        _showSnackBar(data['message'] ?? '??ng k? th?t b?i!', isError: true);
      }
    } catch (e) {
      _showSnackBar('Kh?ng th? k?t n?i ??n m?y ch?: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleRegister() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();
      final response = await http.post(
        ApiConfig.uri('Auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
      if (response.statusCode == 200) {
        _showSnackBar('??ng k?/??ng nh?p Google th?nh c?ng!', isError: false);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(data['message'] ?? 'Email Google ?? t?n t?i ho?c ??ng k? th?t b?i!', isError: true);
      }
    } catch (e) {
      _showSnackBar('??ng k? Google th?t b?i: $e', isError: true);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_registerOtpCtrl.text.trim().isEmpty) {
      _showSnackBar('Vui l?ng nh?p m? x?c nh?n!', isError: true);
      return;
    }
    try {
      final response = await http.post(
        ApiConfig.uri('Auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact': _otpContact, 'otp': _registerOtpCtrl.text.trim()}),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
      if (response.statusCode == 200) {
        _showSnackBar('??ng k? th?nh c?ng! Vui l?ng ??ng nh?p.', isError: false);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(data['message'] ?? 'OTP kh?ng h?p l?!', isError: true);
      }
    } catch (e) {
      _showSnackBar('L?i x?c th?c OTP: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgroundLogin4.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A4A28), Color(0xFF0A1E0F)],
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.2)),
          
          // ── Nút Quay Lại ──────────────────────────────────────────────────
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isOtpStep ? _buildOtpStep() : _buildFormStep(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      key: const ValueKey('form_step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthInput(
          hint: 'Họ và tên',
          icon: Icons.person_outline_rounded,
          controller: _nameCtrl,
        ),
        const SizedBox(height: 16),
        AuthInput(
          hint: 'Email',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          controller: _emailCtrl,
        ),
        const SizedBox(height: 16),
        AuthInput(
          hint: 'Số điện thoại (tùy chọn)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          controller: _phoneCtrl,
        ),
        const SizedBox(height: 16),
        AuthInput(
          hint: 'Mật khẩu',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePass,
          controller: _passCtrl,
          suffixIcon: EyeButton(
            obscure: _obscurePass,
            onTap: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 16),
        AuthInput(
          hint: 'Xác nhận mật khẩu',
          icon: Icons.lock_outline_rounded,
          obscure: _obscureConfirm,
          controller: _confirmCtrl,
          suffixIcon: EyeButton(
            obscure: _obscureConfirm,
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 24),
        GreenButton(
          label: 'Đăng ký',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleRegister,
        ),
        const SizedBox(height: 24),
        GoogleOutlineButton(
          label: 'Đăng ký bằng google',
          onPressed: _handleGoogleRegister,
        ),
        const SizedBox(height: 16),
        AuthFooter(
          prefix: 'Đã có tài khoản ? ',
          action: 'Đăng nhập ngay',
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AuthScreen(isDark: widget.isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp_step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: Colors.white),
        const SizedBox(height: 16),
        const Text(
          'Xác thực tài khoản',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng nhập mã gồm 6 chữ số được gửi đến\n${_emailCtrl.text.isNotEmpty ? _emailCtrl.text : "email/số điện thoại của bạn"}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        AuthInput(
          hint: 'Mã xác nhận OTP',
          icon: Icons.security_rounded,
          keyboardType: TextInputType.number,
          controller: _registerOtpCtrl,
        ),
        const SizedBox(height: 24),
        GreenButton(
          label: 'Xác nhận & Hoàn tất',
          onPressed: _handleVerifyOtp,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _isOtpStep = false),
          child: const Text(
            'Quay lại chỉnh sửa thông tin',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Colors.white70,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
