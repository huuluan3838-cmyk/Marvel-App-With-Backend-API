import 'package:flutter/material.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isDark;
  const NotificationsScreen({super.key, this.isDark = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExtendedApiService.getThongBao();
  }

  Future<void> _reload() async {
    setState(() => _future = ExtendedApiService.getThongBao());
  }

  Future<void> _markRead(int id) async {
    await ExtendedApiService.markThongBaoRead(id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);

    if (!AuthState().isLoggedIn) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Thông báo', style: TextStyle(color: textColor))),
        body: Center(
            child: Text('Vui lòng đăng nhập để xem thông báo.',
                style: TextStyle(
                    color: textColor, fontFamily: AppTextStyles.fontFamily))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text('Thông báo',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w800,
                color: textColor)),
        actions: [
          IconButton(
              onPressed: _reload, icon: Icon(Icons.refresh, color: textColor))
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          if (snapshot.hasError)
            return Center(
                child: Text('Không tải được thông báo: ${snapshot.error}',
                    style: TextStyle(color: textColor)));
          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return Center(
                child: Text('Chưa có thông báo.',
                    style: TextStyle(
                        color: textColor,
                        fontFamily: AppTextStyles.fontFamily)));
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = items[i] as Map<String, dynamic>;
                final read = item['daDoc'] == true;
                final id = item['maThongBao'] is int
                    ? item['maThongBao']
                    : int.tryParse(item['maThongBao']?.toString() ?? '0') ?? 0;
                return ListTile(
                  tileColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  leading: Icon(
                      read
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: read ? AppColors.grey : AppColors.primary),
                  title: Text(item['tieuDe']?.toString() ?? 'Thông báo',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  subtitle: Text(item['noiDung']?.toString() ?? ''),
                  trailing: read
                      ? null
                      : TextButton(
                          onPressed: () => _markRead(id),
                          child: const Text('Đã đọc')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
