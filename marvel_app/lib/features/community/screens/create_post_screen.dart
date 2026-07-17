import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

class CommunityPostDraft {
  final String authorName;
  final String title;
  final String content;
  final String location;
  final String category;
  final String imagePath;

  const CommunityPostDraft({
    required this.authorName,
    required this.title,
    required this.content,
    required this.location,
    required this.category,
    required this.imagePath,
  });
}

class _ImageOption {
  final String label;
  final String path;

  const _ImageOption(this.label, this.path);
}

const List<_ImageOption> _imageOptions = [
  _ImageOption('Không có ảnh', ''),
  _ImageOption('Vịnh Hạ Long', 'assets/images/VinhHaLong.jpg'),
  _ImageOption('Phố Cổ Hội An', 'assets/images/PhoCoHoiAn.jpg'),
  _ImageOption('Hồ Hoàn Kiếm', 'assets/images/HoHoanKiem.jpg'),
  _ImageOption('Lang Biang', 'assets/images/LangBiang.jpg'),
  _ImageOption('Nam Cát Tiên', 'assets/images/NamCatTien.jpg'),
];

class CreatePostScreen extends StatefulWidget {
  final bool isDark;
  final List<String> categories;

  const CreatePostScreen({
    super.key,
    required this.categories,
    this.isDark = false,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _authorCtrl = TextEditingController(text: 'Nhà Khám Phá');
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _selectedCategory = 'Review';
  String _selectedImage = '';

  @override
  void initState() {
    super.initState();
    final available = widget.categories.where((c) => c != 'Mới nhất').toList();
    if (available.isNotEmpty) {
      _selectedCategory = available.first;
    }
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_authorCtrl.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập tên hiển thị');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập tiêu đề');
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập nội dung bài viết');
      return;
    }

    final draft = CommunityPostDraft(
      authorName: _authorCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      category: _selectedCategory,
      imagePath: _selectedImage,
    );

    Navigator.pop(context, draft);
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
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;

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
          'Tạo bài viết',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chia sẻ trải nghiệm của bạn',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: subColor)),
            const SizedBox(height: 16),
            _InputField(
              label: 'Tên hiển thị',
              controller: _authorCtrl,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Tiêu đề bài viết',
              controller: _titleCtrl,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Địa điểm (không bắt buộc)',
              controller: _locationCtrl,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Text('Danh mục',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.categories
                  .where((c) => c != 'Mới nhất')
                  .map((cat) => ChoiceChip(
                        label: Text(cat,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily)),
                        selected: cat == _selectedCategory,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: cat == _selectedCategory
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.grey),
                          fontWeight: cat == _selectedCategory
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Ảnh minh họa',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: DropdownButton<String>(
                value: _selectedImage,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: cardColor,
                icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily, color: textColor),
                items: _imageOptions
                    .map((opt) => DropdownMenuItem<String>(
                          value: opt.path,
                          child: Text(opt.label,
                              style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily)),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedImage = value ?? ''),
              ),
            ),
            if (_selectedImage.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _selectedImage,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _InputField(
              label: 'Nội dung bài viết',
              controller: _contentCtrl,
              isDark: isDark,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Đăng bài',
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


class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.controller,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final fillColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600,
                color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
