import 'package:flutter/material.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class SupportRequestScreen extends StatefulWidget {
  final bool isDark;
  const SupportRequestScreen({super.key, this.isDark = false});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Hỗ trợ kỹ thuật';
  bool _loading = false;
  List<dynamic> _mine = [];

  final List<String> _categories = const [
    'Hỗ trợ kỹ thuật',
    'Góp ý ứng dụng',
    'Báo cáo vi phạm',
    'Vấn đề tài khoản',
    'Khác'
  ];

  @override
  void initState() {
    super.initState();
    if (AuthState().isLoggedIn) _loadMine();
  }

  Future<void> _loadMine() async {
    try {
      final data = await ExtendedApiService.getYeuCauHoTroMine();
      if (mounted) setState(() => _mine = data);
    } catch (_) {}
  }

  Future<void> _submitRequest() async {
    if (!AuthState().isLoggedIn) {
      _showMessage('Vui lòng đăng nhập để gửi hỗ trợ.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ExtendedApiService.createYeuCauHoTro(
          loaiYeuCau: _selectedCategory,
          tieuDe: _titleController.text.trim(),
          noiDung: _contentController.text.trim());
      _titleController.clear();
      _contentController.clear();
      await _loadMine();
      _showMessage('Gửi yêu cầu hỗ trợ thành công!');
    } catch (e) {
      _showMessage('Không gửi được yêu cầu: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message,
              style: const TextStyle(fontFamily: AppTextStyles.fontFamily))));

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text('Tạo yêu cầu hỗ trợ',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w800,
                color: textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _selectedCategory = v ?? _selectedCategory),
                  decoration: const InputDecoration(labelText: 'Loại yêu cầu'),
                ),
                TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tiêu đề'
                        : null),
                TextFormField(
                    controller: _contentController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Nội dung'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập nội dung'
                        : null),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _loading ? null : _submitRequest,
                        child: Text(_loading ? 'Đang gửi...' : 'Gửi yêu cầu'))),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('Yêu cầu đã gửi',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
          const SizedBox(height: 8),
          ..._mine.map((e) => Card(
                color: cardColor,
                child: ListTile(
                  title: Text(e['tieuDe']?.toString() ?? '',
                      style: TextStyle(color: textColor)),
                  subtitle: Text(
                      '${e['loaiYeuCau'] ?? ''} ? ${e['trangThai'] ?? ''}'),
                ),
              )),
        ]),
      ),
    );
  }
}
