import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

String _blogText(String key) {
  const values = {
    'title': 'Blog du ịch',
    'heroTitle': 'Câu chuyện du lịch',
    'search': 'Tìm kiếm bài viết, kinh nghiệm, địa điểm...',
    'empty': 'Chưa có bài viết phù hợp.',
    'all': 'Tất cả',
    'travel': 'Du lịch',
    'newPost': 'Bài viết mới',
    'featured': 'Bài viết nổi bật',
    'read': 'Đọc bài viết',
    'likes': 'lượt thích',
    'related': 'Có thể bạn quan tâm',
  };
  return values[key] ?? key;
}

String _blogImageUrl(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  if (value.startsWith('assets/')) return value;
  if (value.startsWith('/assets/')) return value.substring(1);
  final relative = value.startsWith('/') ? value.substring(1) : value;
  return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/$relative';
}

class BlogListScreen extends StatefulWidget {
  final bool isDark;
  const BlogListScreen({super.key, this.isDark = false});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String _query = '';
  String _category = _blogText('all');
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _fetch();
    _statsTimer = Timer.periodic(const Duration(seconds: 6), (_) => _refreshStats());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(ApiConfig.uri('BaiViet'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        _posts = data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        _showMessage('Không tải được blog: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Lỗi kết nối blog: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _refreshStats() async {
    if (!mounted || _posts.isEmpty) return;
    try {
      final ids = _posts.map((p) => p['maBaiViet']).where((id) => id != null).join(',');
      if (ids.isEmpty) return;
      final headers = <String, String>{};
      if (AuthState().token != null) headers['Authorization'] = 'Bearer ${AuthState().token}';
      final response = await http.get(ApiConfig.uri('BaiViet/stats', {'ids': ids}), headers: headers);
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as List<dynamic>;
      final stats = <int, Map<String, dynamic>>{};
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final id = map['maBaiViet'] is int ? map['maBaiViet'] as int : int.tryParse(map['maBaiViet']?.toString() ?? '0') ?? 0;
        if (id > 0) stats[id] = map;
      }
      setState(() {
        for (final post in _posts) {
          final id = post['maBaiViet'] is int ? post['maBaiViet'] as int : int.tryParse(post['maBaiViet']?.toString() ?? '0') ?? 0;
          final stat = stats[id];
          if (stat == null) continue;
          post['luotThich'] = stat['luotThich'] ?? post['luotThich'];
          post['luotBinhLuan'] = stat['luotBinhLuan'] ?? post['luotBinhLuan'];
          post['luotChiaSe'] = stat['luotChiaSe'] ?? post['luotChiaSe'];
          post['isLiked'] = stat['isLiked'] == true;
        }
      });
    } catch (_) {}
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> get _categories {
    final set = <String>{_blogText('all')};
    for (final p in _posts) {
      final c = p['theLoai']?.toString().trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _posts.where((p) {
      final title = p['tieuDe']?.toString().toLowerCase() ?? '';
      final content = p['noiDung']?.toString().toLowerCase() ?? '';
      final category = p['theLoai']?.toString() ?? '';
      final okQuery = q.isEmpty || title.contains(q) || content.contains(q);
      final okCategory = _category == _blogText('all') || category == _category;
      return okQuery && okCategory;
    }).toList();
  }

  void _openDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlogDetailScreen(
          post: post,
          relatedPosts: _posts.where((e) => e != post).take(3).toList(),
          isDark: widget.isDark,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_blogText('title'),
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w900,
                color: textColor)),
        actions: [
          IconButton(
              onPressed: _fetch,
              icon: Icon(Icons.refresh_rounded, color: textColor))
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroBlogHeader(isDark: isDark, total: _posts.length),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily, color: textColor),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: _blogText('search'),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final item = _categories[i];
                        final active = item == _category;
                        return ChoiceChip(
                          selected: active,
                          label: Text(item,
                              style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.w700)),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color: active ? Colors.white : textColor),
                          backgroundColor: cardColor,
                          onSelected: (_) => setState(() => _category = item),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(_blogText('empty'),
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color:
                                    isDark ? Colors.white70 : AppColors.grey)),
                      ),
                    )
                  else ...[
                    _FeaturedPost(
                        post: _filtered.first,
                        isDark: isDark,
                        onTap: () => _openDetail(_filtered.first)),
                    const SizedBox(height: 14),
                    ..._filtered.skip(1).map((post) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BlogCard(
                              post: post,
                              isDark: isDark,
                              onTap: () => _openDetail(post)),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}

class _HeroBlogHeader extends StatelessWidget {
  final bool isDark;
  final int total;
  const _HeroBlogHeader({required this.isDark, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [Color(0xFF004311), Color(0xFF00AE2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_blogText('heroTitle'),
                  style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
              const SizedBox(height: 6),
              Text('$total bài viết, review và kinh nghiệm từ cộng đồng.',
                  style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white70,
                      height: 1.4)),
            ]),
          ),
          const Icon(Icons.travel_explore_rounded,
              size: 54, color: Colors.white),
        ],
      ),
    );
  }
}

class _FeaturedPost extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isDark;
  final VoidCallback onTap;
  const _FeaturedPost(
      {required this.post, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = _blogImageUrl(post['hinhAnh']);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)
            ]),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          _PostImage(image: image),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD000000)]))),
          Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _CategoryPill(
                          text: post['theLoai']?.toString() ??
                              _blogText('travel')),
                      const SizedBox(width: 8),
                      _CategoryPill(text: _blogText('featured'))
                    ]),
                    const SizedBox(height: 10),
                    Text(post['tieuDe']?.toString() ?? _blogText('newPost'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(post['noiDung']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white70)),
                  ])),
        ]),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isDark;
  final VoidCallback onTap;
  const _BlogCard(
      {required this.post, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final image = _blogImageUrl(post['hinhAnh']);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
            ]),
        child: Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                  width: 108, height: 108, child: _PostImage(image: image))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _CategoryPill(
                    text: post['theLoai']?.toString() ?? _blogText('travel')),
                const SizedBox(height: 8),
                Text(post['tieuDe']?.toString() ?? _blogText('newPost'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: textColor)),
                const SizedBox(height: 6),
                Text(post['noiDung']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: subColor,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.favorite_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('${post['luotThich'] ?? 0} ${_blogText('likes')}',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: subColor,
                          fontSize: 12))
                ]),
              ])),
        ]),
      ),
    );
  }
}

class BlogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  final List<Map<String, dynamic>> relatedPosts;
  final bool isDark;
  const BlogDetailScreen(
      {super.key,
      required this.post,
      required this.relatedPosts,
      this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final image = _blogImageUrl(post['hinhAnh']);
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.primary,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
            _PostImage(image: image),
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0xDD000000)]))),
            Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryPill(
                          text: post['theLoai']?.toString() ??
                              _blogText('travel')),
                      const SizedBox(height: 12),
                      Text(post['tieuDe']?.toString() ?? _blogText('newPost'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900)),
                    ])),
          ])),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            Row(children: [
              const Icon(Icons.favorite_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text('${post['luotThich'] ?? 0} ${_blogText('likes')}',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily, color: subColor)),
              const SizedBox(width: 16),
              Icon(Icons.schedule_rounded, color: subColor, size: 18),
              const SizedBox(width: 6),
              Text('5 phút đọc',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily, color: subColor)),
            ]),
            const SizedBox(height: 20),
            Text(post['noiDung']?.toString() ?? '',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 16,
                    height: 1.65)),
            const SizedBox(height: 28),
            Text(_blogText('related'),
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...relatedPosts.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BlogCard(
                    post: item,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BlogDetailScreen(
                                  post: item,
                                  relatedPosts: relatedPosts
                                      .where((e) => e != item)
                                      .toList(),
                                  isDark: isDark)));
                    }))),
          ])),
        ),
      ]),
    );
  }
}

class _PostImage extends StatelessWidget {
  final String image;
  const _PostImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) return _placeholder();
    if (image.startsWith('http'))
      return Image.network(image,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    return Image.asset(image,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
  }

  Widget _placeholder() => Container(
      color: AppColors.primary.withOpacity(0.12),
      child: const Icon(Icons.article_rounded,
          color: AppColors.primary, size: 48));
}

class _CategoryPill extends StatelessWidget {
  final String text;
  const _CategoryPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.92),
          borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11)),
    );
  }
}
