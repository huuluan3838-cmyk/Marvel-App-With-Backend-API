import 'package:flutter/material.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/utilities/string_utils.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/core/constants/api_config.dart';

enum SearchResultType { post, location, guide, video, image }

class SearchResult {
  final int id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final SearchResultType type;
  final double rating;
  final int? views;
  final Color color;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    this.rating = 4.5,
    this.views,
    required this.color,
  });
}

class SearchScreen extends StatefulWidget {
  final bool isDark;
  const SearchScreen({super.key, this.isDark = false});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isLoading = true;
  List<SearchResult> _allResults = [];
  
  final List<String> _trending = [
    'Hạ Long',
    'Đà Lạt',
    'Hội An',
    'Sapa',
    'Phú Quốc',
    'Nha Trang'
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final postsFuture = ExtendedApiService.getApprovedPosts();
      final locationsFuture = ExtendedApiService.getAllDiaDiem();
      final guidesFuture = ExtendedApiService.getCamNang();

      final results = await Future.wait([postsFuture, locationsFuture, guidesFuture]);

      final List<SearchResult> temp = [];

      // Process Posts
      for (var item in results[0]) {
        temp.add(SearchResult(
          id: item['maBaiViet'],
          title: item['tieuDe'] ?? '',
          subtitle: 'Tác giả: ${item['maNguoiDung']}', 
          imageUrl: _normalizePath(item['hinhAnh']),
          type: item['theLoai'] == 'Video' ? SearchResultType.video : (item['theLoai'] == 'Image' ? SearchResultType.image : SearchResultType.post),
          views: (item['luotThich'] ?? 0) * 10 + 50,
          color: const Color(0xFF00AE2C),
        ));
      }

      // Process Locations
      for (var item in results[1]) {
        temp.add(SearchResult(
          id: item['maDiaDiem'],
          title: item['tenDiaDiem'] ?? '',
          subtitle: item['tinhThanh'] ?? '',
          imageUrl: _normalizePath(item['hinhAnh']),
          type: SearchResultType.location,
          rating: (item['danhGiaTrungBinh'] as num?)?.toDouble() ?? 4.5,
          color: const Color(0xFF1F04B3),
        ));
      }

      // Process Guides
      for (var item in results[2]) {
        temp.add(SearchResult(
          id: item['maCamNang'],
          title: item['tieuDe'] ?? '',
          subtitle: item['theLoai'] ?? 'Cẩm nang',
          imageUrl: _normalizePath(item['hinhAnh']),
          type: SearchResultType.guide,
          views: item['luotThich'] ?? 0,
          color: const Color(0xFFFF9800),
        ));
      }

      setState(() {
        _allResults = temp;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching search data: $e');
      setState(() => _isLoading = false);
    }
  }

  String? _normalizePath(dynamic path) {
    if (path == null) return null;
    String s = path.toString().trim();
    if (s.isEmpty) return null;
    if (s.toLowerCase().startsWith('http')) return s;
    final relative = s.startsWith('/') ? s.substring(1) : s;
    if (relative.toLowerCase().startsWith('assets/')) return relative;
    return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/$relative';
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SearchResult> get _filtered => _allResults
      .where((r) =>
          _query.isEmpty ||
          StringUtils.containsIgnoreCaseAndDiacritics(r.title, _query) ||
          StringUtils.containsIgnoreCaseAndDiacritics(r.subtitle, _query))
      .toList();

  List<SearchResult> _byType(SearchResultType type) =>
      _filtered.where((r) => r.type == type).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Container(
              color: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Khám phá',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                  color: widget.isDark
                                      ? Colors.white
                                      : Colors.black)),
                          Text('Bài viết · Địa điểm · Cẩm nang',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  color: widget.isDark
                                      ? Colors.white70
                                      : AppColors.grey)),
                          const SizedBox(height: 16),
                          // Search bar
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: widget.isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 15,
                                  color: widget.isDark
                                      ? Colors.white
                                      : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm địa điểm, bài viết...',
                                hintStyle: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    color: widget.isDark
                                        ? Colors.white60
                                        : AppColors.grey),
                                prefixIcon: Icon(Icons.search,
                                    color: AppColors.primary, size: 22),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        })
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trending
                    if (_query.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🔥 Xu hướng',
                                style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _trending
                                  .map((t) => GestureDetector(
                                        onTap: () {
                                          _searchCtrl.text = t;
                                          setState(() => _query = t);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Text(t,
                                              style: const TextStyle(
                                                  fontFamily:
                                                      AppTextStyles.fontFamily,
                                                  fontSize: 13,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    // Tabs
                    TabBar(
                      controller: _tab,
                      isScrollable: true,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.grey,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      tabs: const [
                        Tab(text: 'Tất cả'),
                        Tab(text: 'Địa điểm'),
                        Tab(text: 'Bài viết'),
                        Tab(text: 'Cẩm nang'),
                        Tab(text: 'Video/Ảnh'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
          controller: _tab,
          children: [
            _ResultList(results: _filtered, isDark: widget.isDark),
            _ResultList(results: _byType(SearchResultType.location), isDark: widget.isDark),
            _ResultList(results: _byType(SearchResultType.post), isDark: widget.isDark),
            _ResultList(results: _byType(SearchResultType.guide), isDark: widget.isDark),
            _ResultList(results: _filtered.where((r) => r.type == SearchResultType.video || r.type == SearchResultType.image).toList(), isDark: widget.isDark),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<SearchResult> results;
  final bool isDark;
  const _ResultList({required this.results, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: AppColors.grey),
          SizedBox(height: 12),
          Text('Không tìm thấy kết quả',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.grey,
                  fontSize: 16)),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ResultCard(result: results[i], isDark: isDark),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  const _ResultCard({required this.result, this.isDark = false});

  IconData get _typeIcon {
    switch (result.type) {
      case SearchResultType.video:
        return Icons.play_circle_outline;
      case SearchResultType.image:
        return Icons.photo_outlined;
      case SearchResultType.location:
        return Icons.location_on_outlined;
      case SearchResultType.guide:
        return Icons.menu_book_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  String get _typeLabel {
    switch (result.type) {
      case SearchResultType.video:
        return 'Video';
      case SearchResultType.image:
        return 'Hình ảnh';
      case SearchResultType.location:
        return 'Địa điểm';
      case SearchResultType.guide:
        return 'Cẩm nang';
      default:
        return 'Bài viết';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: result.color.withOpacity(0.15),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (result.imageUrl != null && result.imageUrl!.isNotEmpty)
                    result.imageUrl!.startsWith('assets/')
                        ? Image.asset(
                            result.imageUrl!,
                            fit: BoxFit.cover,
                            width: 88,
                            height: 88,
                            errorBuilder: (_, __, ___) =>
                                Icon(_typeIcon, color: result.color, size: 36),
                          )
                        : Image.network(
                            result.imageUrl!,
                            fit: BoxFit.cover,
                            width: 88,
                            height: 88,
                            errorBuilder: (_, __, ___) =>
                                Icon(_typeIcon, color: result.color, size: 36),
                          )
                  else
                    Icon(_typeIcon, color: result.color, size: 36),
                  if (result.type == SearchResultType.video)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: result.color, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: result.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(_typeLabel,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                color: result.color,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      const Icon(Icons.star,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 2),
                      Text(result.rating.toString(),
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(result.title,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: isDark ? Colors.white60 : AppColors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                          child: Text(result.subtitle,
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.grey))),
                      if (result.views != null) ...[
                        Icon(Icons.remove_red_eye_outlined,
                            size: 12,
                            color: isDark ? Colors.white60 : AppColors.grey),
                        const SizedBox(width: 2),
                        Text('${result.views}',
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11,
                                color: isDark ? Colors.white70 : AppColors.grey)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
