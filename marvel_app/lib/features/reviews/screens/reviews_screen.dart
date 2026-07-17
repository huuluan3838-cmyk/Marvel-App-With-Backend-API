import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';

class _ReviewItem {
  final int id;
  final String title;
  final String location;
  final String date;
  final String content;
  final double rating;

  const _ReviewItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.content,
    required this.rating,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['ngayTao'] != null) {
      dt = DateTime.tryParse(json['ngayTao'].toString());
    }
    final formattedDate =
        dt != null ? DateFormat('dd/MM/yyyy').format(dt) : 'N/A';

    return _ReviewItem(
      id: json['maDanhGia'] ?? 0,
      title: json['tenDiaDiem'] ?? 'Địa điểm',
      location: json['tinhThanh'] ?? '',
      date: formattedDate,
      content: json['noiDung'] ?? '',
      rating: (json['soSao'] as num?)?.toDouble() ?? 5.0,
    );
  }

  _ReviewItem copyWith({String? content}) {
    return _ReviewItem(
      id: id,
      title: title,
      location: location,
      date: date,
      content: content ?? this.content,
      rating: rating,
    );
  }
}

class ReviewsScreen extends StatefulWidget {
  final bool isDark;
  const ReviewsScreen({super.key, this.isDark = false});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _filter = 'Tất cả';
  List<_ReviewItem> _reviews = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  Future<void> _loadMyReviews() async {
    setState(() => _isLoading = true);
    try {
      final data = await ExtendedApiService.getDanhGiaMine();
      if (mounted) {
        setState(() {
          _reviews = data.map((e) => _ReviewItem.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Không tải được đánh giá của bạn.');
      }
    }
  }

  List<_ReviewItem> get _filtered {
    if (_filter == 'Tất cả') return _reviews;
    if (_filter == '5 sao') {
      return _reviews.where((r) => r.rating >= 4.9).toList();
    }
    return _reviews.where((r) => r.rating < 4.9).toList();
  }

  void _editReview(_ReviewItem item) {
    final index = _reviews.indexOf(item);
    if (index == -1) return;

    final controller = TextEditingController(text: item.content);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chỉnh sửa đánh giá',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: widget.isDark ? Colors.white : AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: widget.isDark ? Colors.white : AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Nội dung đánh giá',
                filled: true,
                fillColor:
                    widget.isDark ? const Color(0xFF101827) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: widget.isDark ? Colors.white10 : Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: widget.isDark ? Colors.white10 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    _showMessage('Vui lòng nhập nội dung.');
                    return;
                  }
                  setState(
                      () => _reviews[index] = item.copyWith(content: value));
                  Navigator.pop(ctx);
                  _showMessage('Đã cập nhật đánh giá.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          'Đánh giá của tôi',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  'Tổng hợp nhận xét đã đăng',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      color: subColor),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filtered.length} bài',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  isDark: isDark,
                  label: 'Tất cả',
                  selected: _filter == 'Tất cả',
                  onTap: () => setState(() => _filter = 'Tất cả'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  isDark: isDark,
                  label: '5 sao',
                  selected: _filter == '5 sao',
                  onTap: () => setState(() => _filter = '5 sao'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  isDark: isDark,
                  label: 'Dưới 5 sao',
                  selected: _filter == 'Dưới 5 sao',
                  onTap: () => setState(() => _filter = 'Dưới 5 sao'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có đánh giá nào',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: subColor),
                        ),
                      )
                    : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReviewCard(
                      item: _filtered[index],
                      isDark: isDark,
                      onEdit: () => _editReview(_filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final bool isDark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.isDark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.grey),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _ReviewItem item;
  final bool isDark;
  final VoidCallback onEdit;

  const _ReviewCard({
    required this.item,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.location,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              _RatingBadge(rating: item.rating),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.content,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: subColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: subColor),
              const SizedBox(width: 6),
              Text(
                item.date,
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: subColor),
              ),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                child: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
