import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

// ── Glassmorphism Card ────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Toggle Tab (Email / SĐT) ──────────────────────────────────────────────────
class TabToggle extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const TabToggle({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: sel ? Colors.white.withOpacity(0.35) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────
class AuthInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final TextEditingController? controller;

  const AuthInput({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: Colors.white, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

// ── Eye Button (hiện/ẩn mật khẩu) ────────────────────────────────────────────
class EyeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const EyeButton({super.key, required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.remove_red_eye_outlined : Icons.visibility_off_outlined,
        color: Colors.white70,
        size: 18,
      ),
      onPressed: onTap,
    );
  }
}

// ── Nút Xanh Lá Chính ────────────────────────────────────────────────────────
class GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GreenButton({
    super.key,
    required this.label, 
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00AE2C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: const Color(0xFF00AE2C).withOpacity(0.6),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label),
      ),
    );
  }
}

// ── Nút Google ────────────────────────────────────────────────────────────────
class GoogleOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const GoogleOutlineButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GoogleLogo(),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo Google Vẽ Tay ────────────────────────────────────────────────────────
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(20, 20), painter: _GoogleLogoPainter());
}

class _GoogleLogoPainter extends CustomPainter {
  static const _red = Color(0xFFEA4335);
  static const _blue = Color(0xFF4285F4);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  static double _r(double deg) => deg * 3.14159265 / 180;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    final ir = r * 0.60;
    final sw = s.width * 0.22;

    canvas.drawCircle(c, r, Paint()..color = Colors.white);

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: ir),
        _r(start),
        _r(sweep),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }

    arc(_red, 205, 115);
    arc(_yellow, 90, 115);
    arc(_green, 145, 60);
    arc(_blue, 320, 115);

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + ir, c.dy),
      Paint()
        ..color = _blue
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Footer Text (Chưa có tài khoản? Đăng ký ngay) ────────────────────────────
class AuthFooter extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;

  const AuthFooter({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            color: Colors.white,
          ),
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: action,
              style: const TextStyle(
                color: Color(0xFFE6A23C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
