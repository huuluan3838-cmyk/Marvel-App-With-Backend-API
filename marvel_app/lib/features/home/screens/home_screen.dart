import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:marvel_travel/features/auth/screens/register_screen.dart';
import 'package:marvel_travel/features/community/screens/community_screen.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/shared/widgets/aurora_nav_bar.dart';
import 'package:marvel_travel/core/shared/widgets/marvel_app_bar.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart' hide RegisterScreen;
import 'package:marvel_travel/features/destinations/screens/map_screen.dart';
import 'package:marvel_travel/features/search/screens/search_screen.dart';
import 'package:marvel_travel/features/bookmarks/screens/bookmark_screen.dart';
import 'package:marvel_travel/features/profile/screens/profile_screen.dart';
import 'package:marvel_travel/features/about/screens/about_us_screen.dart';
import 'package:marvel_travel/features/guide/screens/guide_screen.dart';
import 'package:marvel_travel/features/itinerary/screens/itinerary_screen.dart';
import 'package:marvel_travel/features/blog/screens/blog_list_screen.dart';
import 'package:marvel_travel/features/destinations/screens/destination_list_screen.dart';
import 'package:marvel_travel/features/notifications/screens/notifications_screen.dart';
import 'package:marvel_travel/features/settings/screens/settings_screen.dart';
import 'package:marvel_travel/features/legal/screens/privacy_policy_screen.dart';
import 'package:marvel_travel/features/support/screens/help_screen.dart';
import 'package:marvel_travel/features/utilities/screens/utilities_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/shared/widgets/login_dialog.dart';

// ── CẤU HÌNH API ──
final String apiUrl = ApiConfig.baseUrl;

// ── Hàm hỗ trợ hiển thị ảnh linh hoạt (Network / Asset) ──

String _normalizeImagePath(String imagePath) {
  final raw = imagePath.trim();
  if (raw.isEmpty) return '';
  if (raw.toLowerCase().startsWith('http://') || raw.toLowerCase().startsWith('https://')) return raw;
  
  // Xử lý các đường dẫn bắt đầu bằng assets hoặc /assets
  final cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
  if (cleanPath.toLowerCase().startsWith('assets/')) {
    return cleanPath;
  }
  
  // Nếu là đường dẫn tương đối khác, nối với URL của backend
  final relative = raw.startsWith('/') ? raw.substring(1) : raw;
  return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/$relative';
}

Widget _buildImage(String imagePath, {double? width, double? height}) {
  imagePath = _normalizeImagePath(imagePath);
  if (imagePath.isEmpty) {
    return Container(color: Colors.grey.shade300);
  }
  if (imagePath.startsWith('http')) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }
  return Image.asset(
    imagePath,
    fit: BoxFit.cover,
    width: width,
    height: height,
    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
  );
}

// ── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  MarvelThemeMode _themeMode = MarvelThemeMode.system;

  bool _isDark(BuildContext ctx) {
    if (_themeMode == MarvelThemeMode.dark) return true;
    if (_themeMode == MarvelThemeMode.light) return false;
    return MediaQuery.of(ctx).platformBrightness == Brightness.dark;
  }

  Widget _buildPage(int index, bool isDark) {
    switch (index) {
      case 0:
        return _HomePage(
          isDark: isDark,
          themeMode: _themeMode,
          onThemeChanged: (m) => setState(() => _themeMode = m),
          scaffoldKey: _scaffoldKey,
        );
      case 1:
        return MapScreen(isDark: isDark);
      case 2:
        return SearchScreen(isDark: isDark);
      case 3:
        return BookmarkScreen(isDark: isDark);
      case 4:
        return ProfileScreen(
          onAuthChanged: () => setState(() {}),
          isDark: isDark,
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AuroraColors.deepSpace : AppColors.cardBg,
      extendBody: true,
      endDrawer: _MarvelDrawer(
        isDark: isDark,
        onAuthChanged: () => setState(() {}),
      ),
      body: IndexedStack(
        index: _navIndex,
        children: List.generate(5, (i) => _buildPage(i, isDark)),
      ),
      bottomNavigationBar: AuroraNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ── Home page (index 0) ───────────────────────────────────────────────────────
class _HomePage extends StatefulWidget {
  final bool isDark;
  final MarvelThemeMode themeMode;
  final Function(MarvelThemeMode) onThemeChanged;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _HomePage({
    required this.isDark,
    required this.themeMode,
    required this.onThemeChanged,
    required this.scaffoldKey,
  });

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final _scrollCtrl = ScrollController();
  bool _isScrolled = false;
  final _reviewSectionKey = GlobalKey();

  bool _isLoading = true;
  List<Map<String, dynamic>> _blogs = [];
  List<Map<String, dynamic>> _destinations = [];
  Timer? _blogStatsTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final v = _scrollCtrl.offset > 50;
      if (v != _isScrolled) setState(() => _isScrolled = v);
    });
    _fetchHomeData();
    _blogStatsTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refreshBlogStats());
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
    try {
      final destFuture = http.get(Uri.parse('$apiUrl/DiaDiem'));
      final blogFuture = http.get(Uri.parse('$apiUrl/BaiViet'));

      final responses = await Future.wait([destFuture, blogFuture]);

      List<Map<String, dynamic>> loadedDest = [];
      List<Map<String, dynamic>> loadedBlogs = [];

      // Xử lý dữ liệu Địa điểm
      if (responses[0].statusCode == 200) {
        final List<dynamic> destData = jsonDecode(responses[0].body);
        loadedDest = destData
            .map((d) => {
                  'title': d['tenDiaDiem']?.toString() ?? 'Chưa cập nhật',
                  'image': d['hinhAnh']?.toString() ?? '',
                })
            .toList();
      }

      // Xử lý dữ liệu Bài viết
      if (responses[1].statusCode == 200) {
        final List<dynamic> blogData = jsonDecode(responses[1].body);
        loadedBlogs = blogData
            .map((b) => {
                  'id': b['maBaiViet'],
                  'title': b['tieuDe']?.toString() ?? 'Bài viết mới',
                  'location': b['theLoai']?.toString() ?? 'Du lịch',
                  'reviews': '(${b['luotThich'] ?? 0} likes)',
                  'rating': 5.0,
                  'image': b['hinhAnh']?.toString() ?? '',
                })
            .toList();
      }

      if (mounted) {
        setState(() {
          _destinations = loadedDest;
          _blogs = loadedBlogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Home: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _refreshBlogStats() async {
    if (!mounted || _blogs.isEmpty) return;
    try {
      final ids = _blogs.map((b) => b['id']).where((id) => id != null).join(',');
      if (ids.isEmpty) return;
      final response = await http.get(ApiConfig.uri('BaiViet/stats', {'ids': ids}));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as List<dynamic>;
      final stats = <int, Map<String, dynamic>>{};
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final id = map['maBaiViet'] is int ? map['maBaiViet'] as int : int.tryParse(map['maBaiViet']?.toString() ?? '0') ?? 0;
        if (id > 0) stats[id] = map;
      }
      setState(() {
        for (final blog in _blogs) {
          final id = blog['id'] is int ? blog['id'] as int : int.tryParse(blog['id']?.toString() ?? '0') ?? 0;
          final stat = stats[id];
          if (stat == null) continue;
          blog['reviews'] = '(${stat['luotThich'] ?? 0} likes)';
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _blogStatsTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToReviews() {
    final ctx = _reviewSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    } else {
      _scrollCtrl.animateTo(
        MediaQuery.of(context).size.height * 0.9,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: isDark ? AuroraColors.deepSpace : AppColors.cardBg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchHomeData,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 0)),

                // ── Hero ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroSection(
                    onScrollDown: _scrollToReviews,
                    onAbout: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AboutUsScreen(isDark: isDark)),
                    ),
                    hideScrollIndicator: _isScrolled,
                  ),
                ),

                // ── Blog / Review SLIDES ────────────────────────────
                SliverToBoxAdapter(
                  key: _reviewSectionKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 24, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Blog du lịch',
                          isDark: isDark,
                          onSeeAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BlogListScreen(isDark: isDark)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isLoading
                            ? const Center(
                                child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ))
                            : _blogs.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                        child: Text('Chưa có bài viết nào',
                                            style: TextStyle(
                                                fontFamily:
                                                    AppTextStyles.fontFamily))),
                                  )
                                : SizedBox(
                                    height: 290,
                                    child: PageView.builder(
                                      controller: PageController(
                                          viewportFraction: 0.88),
                                      itemCount: _blogs.length,
                                      itemBuilder: (_, i) {
                                        final b = _blogs[i];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          child: _BlogSlideCard(
                                            title: b['title'],
                                            location: b['location'],
                                            reviewCount: b['reviews'],
                                            rating: b['rating'],
                                            imagePath: b['image'],
                                            isDark: isDark,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                      ],
                    ),
                  ),
                ),

                // ── Điểm đến hấp dẫn ───────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF0F172A) : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Điểm đến hấp dẫn',
                            isDark: isDark,
                            onSeeAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DestinationListScreen(isDark: isDark)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const Center(
                                  child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ))
                              : _destinations.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                          child: Text('Chưa có địa điểm nào',
                                              style: TextStyle(
                                                  fontFamily: AppTextStyles
                                                      .fontFamily))),
                                    )
                                  : SizedBox(
                                      height: 240,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _destinations.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (_, i) {
                                          final d = _destinations[i];
                                          return _DestinationCard(
                                            title: d['title'],
                                            imagePath: d['image'],
                                            isDark: isDark,
                                          );
                                        },
                                      ),
                                    ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Lập lịch trình ──────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: const AssetImage(
                              'assets/images/backgroundlaplich.jpg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Lập lịch trình du lịch dễ\ndàng cho chuyến đi của\nbạn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: Colors.white,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                    blurRadius: 8.0,
                                    color: Colors.black45,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.white, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Đơn giản',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.white, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Khoa học',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.white, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Thẩm mỹ',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.white, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Nhắc nhở',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!AuthState().isLoggedIn) {
                                  showLoginRequiredDialog(context,
                                      featureName: 'Lập lịch trình',
                                      isDark: isDark);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ItineraryScreen(isDark: isDark)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Lập lịch trình ngay nào',
                                style: TextStyle(
                                  color: Color(0xFF00AE2C),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ── Overlay AppBar ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MarvelAppBar(
              isScrolled: _isScrolled,
              isDark: isDark,
              currentTheme: widget.themeMode,
              onThemeChanged: widget.onThemeChanged,
              onMenuTap: () => widget.scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  final VoidCallback onScrollDown;
  final VoidCallback onAbout;
  final bool hideScrollIndicator;

  const _HeroSection({
    required this.onScrollDown,
    required this.onAbout,
    required this.hideScrollIndicator,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bounceAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    if (!widget.hideScrollIndicator) {
      _bounceCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _HeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hideScrollIndicator == widget.hideScrollIndicator) return;
    if (widget.hideScrollIndicator) {
      _bounceCtrl.stop();
      _bounceCtrl.value = 0;
    } else {
      _bounceCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/thumbnailHome2.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1a472a), Color(0xFF0d1b2a)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: h * 0.55,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 9,
            right: 9,
            top: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 67, height: 2, color: AppColors.primary),
                  const SizedBox(width: 14),
                  const Text('Hành trình mơ ước',
                      style: AppTextStyles.taglineSmall),
                ]),
                const SizedBox(height: 22),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.0, 0.5, 1.0],
                    colors: [
                      Color(0xFF32D445),
                      Color(0xFF28687E),
                      Color(0xFF1F04B3)
                    ],
                  ).createShader(b),
                  child: const Text('VIỆT NAM',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: 46,
                          color: Colors.white,
                          height: 1.2)),
                ),
                const Text('Khơi Nguồn\nTrải Nghiệm,\nLan Tỏa Giá Trị.',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 46,
                        color: Colors.white,
                        height: 1.2)),
                const SizedBox(height: 28),
                const Text(
                    'Kết nối đam mê, chia sẻ khoảnh khắc\nvà cùng xây dựng cộng đồng du lịch Việt Nam.\nCùng Marvel lan tỏa vẻ đẹp Việt Nam đến bạn bè quốc tế.',
                    style: AppTextStyles.heroSubtitle),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: widget.onScrollDown,
                  child: Container(
                      width: 221,
                      height: 68,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(15)),
                      alignment: Alignment.center,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Khám phá nào',
                                style: AppTextStyles.buttonText),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward,
                                size: 26, color: Colors.white),
                          ],
                        ),
                      )),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onAbout,
                  child: Container(
                      width: 160,
                      height: 68,
                      decoration: BoxDecoration(
                          color: const Color(0x75000000),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white38)),
                      alignment: Alignment.center,
                      child: const Text('Về chúng tôi',
                          style: AppTextStyles.buttonText)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: widget.onScrollDown,
              child: IgnorePointer(
                ignoring: widget.hideScrollIndicator,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: widget.hideScrollIndicator ? 0 : 0.78,
                  child: AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Cuộn xuống',
                              style: AppTextStyles.scrollDownText),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white60)),
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _MarvelDrawer extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onAuthChanged;
  const _MarvelDrawer({required this.isDark, this.onAuthChanged});

  @override
  State<_MarvelDrawer> createState() => _MarvelDrawerState();
}

class _MarvelDrawerState extends State<_MarvelDrawer> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final _allItems = const [
    {'icon': 'public', 'label': 'Cộng đồng du lịch'},
    {'icon': 'calendar', 'label': 'Lập lịch trình'},
    {'icon': 'explore', 'label': 'Cẩm nang du lịch'},
    {'icon': 'location', 'label': 'Điểm đến hấp dẫn'},
    {'icon': 'dashboard', 'label': 'Tiện ích'},
    {'icon': 'info', 'label': 'Về chúng tôi'},
    {'icon': 'notifications', 'label': 'Thông báo'},
    {'icon': 'settings', 'label': 'Cài đặt'},
    {'icon': 'privacy', 'label': 'Quyền riêng tư'},
    {'icon': 'help', 'label': 'Trợ giúp'},
  ];

  IconData _iconFor(String key) {
    switch (key) {
      case 'public':
        return Icons.public;
      case 'calendar':
        return Icons.calendar_month_outlined;
      case 'explore':
        return Icons.explore_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'info':
        return Icons.info_outline;
      case 'notifications':
        return Icons.notifications_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'help':
        return Icons.help_outline;
      case 'privacy':
        return Icons.privacy_tip_outlined;
      default:
        return Icons.circle;
    }
  }

  void _openMenuItem(String? iconKey) {
    if (iconKey == null) return;
    Navigator.pop(context);

    switch (iconKey) {
      case 'public':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CommunityScreen(isDark: widget.isDark)));
        break;
      case 'explore':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GuideScreen(isDark: widget.isDark)));
        break;
      case 'info':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AboutUsScreen(isDark: widget.isDark)));
        break;
      case 'calendar':
        if (!AuthState().isLoggedIn) {
          showLoginRequiredDialog(context,
              featureName: 'Lập lịch trình', isDark: widget.isDark);
          return;
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ItineraryScreen(isDark: widget.isDark)));
        break;
      case 'location':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DestinationListScreen(isDark: widget.isDark)));
        break;
      case 'dashboard':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UtilitiesScreen(isDark: widget.isDark)));
        break;
      case 'notifications':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => NotificationsScreen(isDark: widget.isDark)));
        break;
      case 'settings':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SettingsScreen(isDark: widget.isDark)));
        break;
      case 'privacy':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PrivacyPolicyScreen(isDark: widget.isDark)));
        break;
      case 'help':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HelpScreen(isDark: widget.isDark)));
        break;
    }
  }

  List<Map<String, String>> get _filtered => _query.isEmpty
      ? _allItems
      : _allItems
          .where(
              (e) => e['label']!.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F172A) : Colors.white;
    final txt = widget.isDark ? Colors.white : AppColors.black;
    final iconClr = widget.isDark ? Colors.white70 : AppColors.primary;
    const groupHorizontalPadding = 17.0;
    const sectionVerticalSpacing = 8.0;

    return Drawer(
      width: 340,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        color: bg,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: AuthState(),
            builder: (context, child) {
              final isLoggedIn = AuthState().isLoggedIn;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        groupHorizontalPadding, 16, groupHorizontalPadding, 12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: widget.isDark
                                ? Colors.white24
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(24),
                        color: widget.isDark
                            ? Colors.white10
                            : const Color(0xFFF5F5F5),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            color: txt),
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          hintStyle: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white38
                                  : AppColors.grey),
                          prefixIcon:
                              Icon(Icons.search, color: iconClr, size: 22),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      size: 16, color: iconClr),
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
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        groupHorizontalPadding,
                        sectionVerticalSpacing,
                        groupHorizontalPadding,
                        sectionVerticalSpacing),
                    child: Divider(height: 1),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text('Không tìm thấy',
                                style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: widget.isDark
                                        ? Colors.white54
                                        : AppColors.grey)))
                        : _query.isNotEmpty
                            ? ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final item = _filtered[i];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: groupHorizontalPadding,
                                        vertical: 2),
                                    leading: Icon(_iconFor(item['icon']!),
                                        color: iconClr, size: 26),
                                    title: Text(item['label']!,
                                        style: TextStyle(
                                            fontFamily:
                                                AppTextStyles.fontFamily,
                                            fontSize: 16,
                                            color: txt)),
                                    onTap: () => _openMenuItem(item['icon']),
                                  );
                                },
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final item = _filtered[i];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: groupHorizontalPadding,
                                        vertical: 2),
                                    leading: Icon(_iconFor(item['icon']!),
                                        color: iconClr, size: 26),
                                    title: Text(item['label']!,
                                        style: TextStyle(
                                            fontFamily:
                                                AppTextStyles.fontFamily,
                                            fontSize: 16,
                                            color: txt)),
                                    onTap: () => _openMenuItem(item['icon']),
                                  );
                                },
                                separatorBuilder: (_, i) {
                                  if (i == 4) {
                                    return const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          groupHorizontalPadding,
                                          sectionVerticalSpacing,
                                          groupHorizontalPadding,
                                          sectionVerticalSpacing),
                                      child: Divider(height: 1),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                        groupHorizontalPadding,
                        sectionVerticalSpacing,
                        groupHorizontalPadding,
                        sectionVerticalSpacing),
                    child: Divider(height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        groupHorizontalPadding, 16, groupHorizontalPadding, 16),
                    child: isLoggedIn
                        ? Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.15),
                                child: Icon(Icons.person,
                                    size: 24, color: iconClr),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(AuthState().username,
                                    style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: txt)),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await AuthState().logout();
                                  Navigator.pop(context);
                                  widget.onAuthChanged?.call();
                                },
                                icon: const Icon(Icons.logout,
                                    color: Colors.red, size: 18),
                                label: const Text('Đăng xuất',
                                    style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: Colors.red,
                                        fontSize: 13)),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final ok = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => AuthScreen(
                                                isDark: widget.isDark)));
                                    if (!mounted) return;
                                    if (ok == true)
                                      widget.onAuthChanged?.call();
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12)),
                                  child: const Text('Đăng nhập',
                                      style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final ok = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => RegisterScreen(
                                                isDark: widget.isDark)));
                                    if (!mounted) return;
                                    if (ok == true)
                                      widget.onAuthChanged?.call();
                                  },
                                  style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12)),
                                  child: const Text('Đăng ký',
                                      style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.primary)),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Blog Slide Card ───────────────────────────────────────────────────────────
class _BlogSlideCard extends StatelessWidget {
  final String title, location, reviewCount, imagePath;
  final double rating;
  final bool isDark;

  const _BlogSlideCard({
    required this.title,
    required this.location,
    required this.reviewCount,
    required this.rating,
    required this.imagePath,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(imagePath),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.6, 1.0],
                        colors: [Colors.transparent, Color(0xAA000000)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.white)),
                      const SizedBox(width: 4),
                      Text(reviewCount,
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 10,
                              color: Colors.white70)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.primaryLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                            child: Text(location,
                                style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 11,
                                    color: AppColors.grey),
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Xem',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final bool isDark;

  const _SectionHeader(
      {required this.title, this.onSeeAll, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 3, height: 25, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: AppTextStyles.sectionTitle
                  .copyWith(color: isDark ? Colors.white : AppColors.black)),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white.withOpacity(0.3),
                border: Border.all(
                    color: isDark ? Colors.white30 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(children: [
                Text('Tất cả',
                    style: AppTextStyles.seeAllText.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.primaryLight)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right,
                    color: isDark ? Colors.white70 : AppColors.primaryLight,
                    size: 14),
              ]),
            ),
          ),
        ],
      );
}

// ── Destination Card ──────────────────────────────────────────────────────────
class _DestinationCard extends StatelessWidget {
  final String title, imagePath;
  final bool isDark;

  const _DestinationCard(
      {required this.title, required this.imagePath, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 200,
              height: 195,
              child: _buildImage(imagePath),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 200,
            child: Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                  color: isDark ? Colors.white : AppColors.primaryLight),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}
