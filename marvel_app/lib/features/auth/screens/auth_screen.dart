import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/shared/widgets/auth/auth_widgets.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/admin/screens/admin_dashboard_screen.dart';
import 'package:marvel_travel/features/auth/screens/register_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/services/fcm_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// Auth State  –  Kế thừa ChangeNotifier để phát tín hiệu đồng bộ UI lập tức
// GIỮ NGUYÊN BẢN GỐC ĐỂ ĐẢM BẢO API VÀ STATE HOẠT ĐỘNG
// ════════════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════════════
// Màn Hình Đăng Nhập  (AuthScreen) - Giao diện mới với API cũ
// ════════════════════════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  final bool isDark;
  const AuthScreen({super.key, this.isDark = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 0 = Email, 1 = Số điện thoại
  int _tabIndex = 0;
  bool _obscurePassword = true;
  bool _isPhoneWithPassword = false;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // LOGIC ĐĂNG NHẬP API
  Future<void> _handleLogin() async {
    final credential =
        _tabIndex == 0 ? _emailCtrl.text.trim() : _phoneCtrl.text.trim();
    final passwordOrOtp = _tabIndex == 0
        ? _passCtrl.text
        : (_isPhoneWithPassword ? _passCtrl.text : _otpCtrl.text);

    if (credential.isEmpty || passwordOrOtp.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Xác định endpoint dựa trên loại đăng nhập
      String endpoint = 'Auth/login';
      Map<String, dynamic> body = {
        'email': credential,
        'password': passwordOrOtp,
      };

      if (_tabIndex == 1 && !_isPhoneWithPassword) {
        endpoint = 'Auth/login-otp';
        body = {
          'phone': credential,
          'otp': passwordOrOtp,
        };
      }

      final url = ApiConfig.uri(endpoint);

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user =
            data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final token = data['token']?.toString();

        String vaiTro = user['vaiTro']?.toString() ?? 'User';

        AuthState().login(
          user['hoTen']?.toString() ?? 'Nhà Khám Phá',
          user['email']?.toString() ?? credential,
          vaiTro,
          inputUserId: user['maNguoiDung'] is int
              ? user['maNguoiDung']
              : int.tryParse(user['maNguoiDung']?.toString() ?? ''),
          inputToken: token,
          inputAvatarUrl: user['anhDaiDien']?.toString(),
        );

        await FcmService.registerCurrentDeviceToken();

        if (!mounted) return;
        _showSnackBar('Đăng nhập thành công!', isError: false);

        if (vaiTro == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(isDark: widget.isDark),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Thông tin đăng nhập không đúng!',
            isError: true);
      }
    } catch (e) {
      debugPrint('Lỗi Login API: $e');
      _showSnackBar(
          'Máy chủ không phản hồi. Vui lòng kiểm tra lại backend API!',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(isDark: widget.isDark),
      ),
    );
  }

  Future<void> _sendLoginOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại trước', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = ApiConfig.uri('Auth/send-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackBar('Mã OTP đã được gửi thành công!',
            isError: false);
      } else {
        _showSnackBar(data['message'] ?? 'Không thể gửi OTP', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối máy chủ', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
Future<void> _handleGoogleLogin() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();

      setState(() => _isLoading = true);

      final response = await http
          .post(
            ApiConfig.uri('Auth/google-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': googleUser.email,
              'name': googleUser.displayName,
              'photoUrl': googleUser.photoUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        final user =
            data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final token = data['token']?.toString();
        final vaiTro = user['vaiTro']?.toString() ?? 'User';

        AuthState().login(
          user['hoTen']?.toString() ??
              googleUser.displayName ??
              'Người dùng Google',
          user['email']?.toString() ?? googleUser.email,
          vaiTro,
          inputUserId: user['maNguoiDung'] is int
              ? user['maNguoiDung']
              : int.tryParse(user['maNguoiDung']?.toString() ?? ''),
          inputToken: token,
          inputAvatarUrl: user['anhDaiDien']?.toString() ?? googleUser.photoUrl,
        );

        await FcmService.registerCurrentDeviceToken();

        if (mounted) {
          _showSnackBar('Đăng nhập Google thành công!', isError: false);
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        _showSnackBar(data['message'] ?? 'Đăng nhập Google thất bại!',
            isError: true);
      }
    } catch (error) {
      debugPrint('Lỗi Google Login: $error');
      if (mounted) {
        _showSnackBar('Đăng nhập Google thất bại: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ảnh nền toàn màn hình ───────────────────────────────────────
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

          // ── Overlay tối giúp chữ dễ đọc hơn ──────────────────────────────
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

          // ── Nội dung ────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Tab: Email / Số điện thoại
                      TabToggle(
                        labels: const ['Email', 'Số điện thoại'],
                        selected: _tabIndex,
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                      const SizedBox(height: 24),

                      // Input Forms
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _tabIndex == 0
                            ? _buildEmailTab()
                            : _buildPhoneTab(),
                      ),

                      const SizedBox(height: 24),

                      // Google Login Button
                      GoogleOutlineButton(
                        label: 'Đăng nhập bằng google',
                        onPressed: _handleGoogleLogin,
                      ),
                      const SizedBox(height: 16),

                      // Footer
                      AuthFooter(
                        prefix: 'Chưa có tài khoản ? ',
                        action: 'Đăng ký ngay',
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterScreen(isDark: widget.isDark),
                          ),
                        ),
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

  Widget _buildEmailTab() {
    return Column(
      key: const ValueKey('email_tab'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthInput(
          hint: 'example@gmail.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          controller: _emailCtrl,
        ),
        const SizedBox(height: 16),
        AuthInput(
          hint: '••••••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          controller: _passCtrl,
          suffixIcon: EyeButton(
            obscure: _obscurePassword,
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 20),
        GreenButton(
          label: 'Đăng nhập',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleLogin,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openForgotPassword,
          child: const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneTab() {
    return Column(
      key: const ValueKey('phone_tab'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthInput(
          hint: 'Số điện thoại',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          controller: _phoneCtrl,
        ),
        const SizedBox(height: 16),
        if (_isPhoneWithPassword)
          AuthInput(
            hint: 'Mật khẩu',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            controller: _passCtrl,
            suffixIcon: EyeButton(
              obscure: _obscurePassword,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          )
        else
          AuthInput(
            hint: 'Mã OTP',
            icon: Icons.message_outlined,
            keyboardType: TextInputType.number,
            controller: _otpCtrl,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _sendLoginOtp,
                    child: const Text(
                      'Gửi mã',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Color(0xFFE6A23C), // Màu cam vàng
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GreenButton(
                label: _isPhoneWithPassword
                    ? 'Đăng nhập'
                    : 'Đăng nhập bằng OTP',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleLogin,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
              ),
              child: IconButton(
                icon: Icon(
                  _isPhoneWithPassword
                      ? Icons.message_outlined
                      : Icons.lock_outline,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPhoneWithPassword = !_isPhoneWithPassword;
                  });
                },
              ),
            ),
          ],
        ),
        if (_isPhoneWithPassword) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openForgotPassword,
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Màn Hình Quên Mật Khẩu (ForgotPasswordScreen)
// ════════════════════════════════════════════════════════════════════════════
class ForgotPasswordScreen extends StatefulWidget {
  final bool isDark;
  const ForgotPasswordScreen({super.key, this.isDark = false});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  final _contactCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _contactCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final contact = _contactCtrl.text.trim();
    if (contact.isEmpty) {
      _showMessage('Vui lòng nhập email hoặc số điện thoại');
      return;
    }

    setState(() => _loading = true);
    try {
      final isEmail = contact.contains('@');
      final response = await http.post(
        ApiConfig.uri('Auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (isEmail) 'email': contact else 'phone': contact,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage(data['message'] ?? 'Mã xác nhận đã được gửi thành công!');
        setState(() {
          _step = 1;
          _loading = false;
        });
      } else {
        _showMessage(data['message'] ?? 'Lỗi gửi OTP', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      _showMessage('Lỗi kết nối máy chủ', isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      _showMessage('Vui lòng nhập mã xác nhận');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.post(
        ApiConfig.uri('Auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': _contactCtrl.text.trim(),
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage('Xác thực thành công');
        setState(() {
          _step = 2;
          _loading = false;
        });
      } else {
        _showMessage(data['message'] ?? 'Mã xác nhận không đúng', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      _showMessage('Lỗi kết nối máy chủ', isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    if (newPass.isEmpty || _confirmCtrl.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ mật khẩu mới');
      return;
    }
    if (newPass != _confirmCtrl.text) {
      _showMessage('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.post(
        ApiConfig.uri('Auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': _contactCtrl.text.trim(),
          'otp': _otpCtrl.text.trim(),
          'newPassword': newPass,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage('Đặt lại mật khẩu thành công');
        if (mounted) Navigator.pop(context, true);
      } else {
        _showMessage(data['message'] ?? 'Lỗi đặt lại mật khẩu', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      _showMessage('Lỗi kết nối máy chủ', isError: true);
      setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
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
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildStep(),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Quay lại đăng nhập',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white70,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
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


  Widget _buildStep() {
    switch (_step) {
      case 1:
        return Column(
          key: const ValueKey('otp_step'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 64, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Nhập mã xác nhận',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã OTP đã được gửi đến ${_contactCtrl.text.trim()}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            AuthInput(
              hint: 'Mã OTP',
              icon: Icons.security_rounded,
              keyboardType: TextInputType.number,
              controller: _otpCtrl,
            ),
            const SizedBox(height: 20),
            GreenButton(label: 'Xác nhận', onPressed: _verifyOtp),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _sendOtp,
              child: const Text(
                'Gửi lại mã xác nhận',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Color(0xFFE6A23C),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: const Text(
                'Sửa thông tin liên hệ',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey('reset_step'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset_outlined,
                size: 64, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Tạo mật khẩu mới',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            AuthInput(
              hint: 'Mật khẩu mới',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureNew,
              controller: _newPassCtrl,
              suffixIcon: EyeButton(
                obscure: _obscureNew,
                onTap: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            GreenButton(label: 'Hoàn tất', onPressed: _resetPassword),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: const Text(
                'Nhập lại mã xác nhận',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      default:
        return Column(
          key: const ValueKey('contact_step'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset_outlined,
                size: 64, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Quên mật khẩu',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập email hoặc số điện thoại để nhận mã xác nhận.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            AuthInput(
              hint: 'Email hoặc số điện thoại',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              controller: _contactCtrl,
            ),
            const SizedBox(height: 20),
            GreenButton(label: 'Gửi mã xác nhận', onPressed: _sendOtp),
          ],
        );
    }
  }
}
