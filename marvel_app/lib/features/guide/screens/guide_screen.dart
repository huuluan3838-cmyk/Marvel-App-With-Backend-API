import 'package:flutter/material.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

class GuideScreen extends StatefulWidget {
  final bool isDark;
  const GuideScreen({super.key, this.isDark = false});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  late Future<List<dynamic>> _future;
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _future = ExtendedApiService.getCamNang();
  }

  List<dynamic> _filter(List<dynamic> data) {
    if (_selectedCategory == 'Tất cả') return data;
    return data
        .where((e) => e['theLoai']?.toString() == _selectedCategory)
        .toList();
  }

  List<String> _categories(List<dynamic> data) {
    final set = <String>{'Tất cả'};
    for (final item in data) {
      final value = item['theLoai']?.toString();
      if (value != null && value.isNotEmpty) set.add(value);
    }
    return set.toList();
  }

  Future<void> _reload() async {
    setState(() => _future = ExtendedApiService.getCamNang());
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cẩm nang du lịch',
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
                child: Text('Không tải được cẩm nang: ${snapshot.error}',
                    style: TextStyle(color: textColor)));
          final data = snapshot.data ?? [];
          final categories = _categories(data);
          final filtered = _filter(data);
          return Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    return ChoiceChip(
                      label: Text(cat,
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily)),
                      selected: cat == _selectedCategory,
                      selectedColor: AppColors.primary,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: categories.length,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final item = filtered[i] as Map<String, dynamic>;
                      return _GuideCard(item: item, isDark: isDark);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  const _GuideCard({required this.item, required this.isDark});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  late int likes = widget.item['luotThich'] is int
      ? widget.item['luotThich']
      : int.tryParse(widget.item['luotThich']?.toString() ?? '0') ?? 0;

  Future<void> _like() async {
    final id = widget.item['maCamNang'];
    if (id == null) return;
    try {
      final result = await ExtendedApiService.likeCamNang(
          id is int ? id : int.parse(id.toString()));
      setState(() => likes = result['luotThich'] ?? likes + 1);
    } catch (_) {
      setState(() => likes++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.black;
    final cardColor = widget.isDark ? const Color(0xFF0F172A) : Colors.white;
    final hinhAnh = widget.item['hinhAnh']?.toString() ?? '';
    final imagePath = hinhAnh.contains('assets') ? hinhAnh : 'assets/images/cam_nang/$hinhAnh';

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hinhAnh.isNotEmpty)
            Image.asset(
              imagePath,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                width: double.infinity,
                color: widget.isDark ? Colors.white10 : Colors.black12,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.item['tieuDe']?.toString() ?? 'Cẩm nang',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 6),
              Text(widget.item['theLoai']?.toString() ?? '',
                  style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(widget.item['noiDung']?.toString() ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: widget.isDark ? Colors.white70 : AppColors.grey)),
              const SizedBox(height: 10),
              Row(children: [
                Text(widget.item['thoiGianDoc']?.toString() ?? '',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: widget.isDark ? Colors.white54 : AppColors.grey)),
                const Spacer(),
                TextButton.icon(
                    onPressed: _like,
                    icon: const Icon(Icons.favorite_border),
                    label: Text('$likes')),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
