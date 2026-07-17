import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';

void showLoginRequiredDialog(BuildContext context, {required String featureName, required bool isDark}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Yêu cầu đăng nhập',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? Colors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Bạn cần đăng nhập tài khoản để sử dụng tính năng $featureName.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? Colors.white70 : AppColors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy bỏ',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AuthScreen(isDark: isDark)),
              );
            },
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
            child: const Text('Đăng nhập ngay',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white)),
          ),
        ],
      );
    },
  );
}
