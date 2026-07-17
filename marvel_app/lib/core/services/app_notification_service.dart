
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class AppNotificationService extends StatefulWidget {
  final Widget child;
  const AppNotificationService({super.key, required this.child});

  @override
  State<AppNotificationService> createState() => _AppNotificationServiceState();
}

class _AppNotificationServiceState extends State<AppNotificationService> {
  Timer? _timer;
  int? _lastShownNotificationId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _checkNewNotification());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNewNotification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  

  Future<void> _checkNewNotification() async {
    if (!mounted || !AuthState().isLoggedIn || AuthState().token == null) return;
    try {
      final item = await ExtendedApiService.getLatestUnreadThongBao();
      if (item == null) return;
      final id = item['maThongBao'] is int
          ? item['maThongBao'] as int
          : int.tryParse(item['maThongBao']?.toString() ?? '0') ?? 0;
      if (id == 0 || id == _lastShownNotificationId) return;
      _lastShownNotificationId = id;
      _showInAppNotification(
        id: id,
        title: item['tieuDe']?.toString() ?? 'Thông báo mới',
        content: item['noiDung']?.toString() ?? '',
      );
    } catch (_) {
      // Im lặng để không làm phiền người dùng khi API tạm thời lỗi.
    }
  }

  void _showInAppNotification({required int id, required String title, required String content}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        backgroundColor: AppColors.primary,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Đã đọc',
          textColor: Colors.white,
          onPressed: () => ExtendedApiService.markThongBaoRead(id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
