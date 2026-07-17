import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/services/extended_api_service.dart';
import 'package:marvel_travel/features/destinations/screens/map_screen.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/itinerary/screens/itinerary_screen.dart';
import 'package:marvel_travel/features/bookmarks/screens/bookmark_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/shared/widgets/login_dialog.dart';

class DestinationDetailScreen extends StatefulWidget {
  final TouristSpot spot;
  final bool isDark;

  const DestinationDetailScreen({
    super.key,
    required this.spot,
    this.isDark = false,
  });

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  List<dynamic> _reviews = [];
  bool _reviewsLoading = false;
  Timer? _reviewTimer;
  Timer? _weatherTimer;
  double? _liveAverageRating;
  int _liveReviewCount = 0;
  final _reviewController = TextEditingController();
  double _rating = 5;
  Map<String, dynamic>? _weather;
  bool _weatherLoading = false;

  TouristSpot get spot => widget.spot;
  bool get isDark => widget.isDark;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadWeather();
    _reviewTimer = Timer.periodic(const Duration(seconds: 6), (_) => _loadReviews(silent: true));
    _weatherTimer = Timer.periodic(const Duration(minutes: 10), (_) => _loadWeather(silent: true));
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _weatherTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews({bool silent = false}) async {
    final id = int.tryParse(spot.id);
    if (id == null) return;
    if (!silent) setState(() => _reviewsLoading = true);
    try {
      final data = await ExtendedApiService.getDanhGiaByDiaDiem(id);
      final stats = await ExtendedApiService.getDanhGiaStats(id);
      if (mounted) setState(() {
        _reviews = data;
        _liveReviewCount = stats['soDanhGia'] ?? data.length;
        _liveAverageRating = (stats['danhGiaTrungBinh'] as num?)?.toDouble();
      });
    } catch (e) {
      debugPrint('Lỗi tải đánh giá: $e');
    } finally {
      if (mounted && !silent) setState(() => _reviewsLoading = false);
    }
  }


  Future<void> _loadWeather({bool silent = false}) async {
    if (!silent) setState(() => _weatherLoading = true);
    try {
      final lat = spot.location.latitude;
      final lon = spot.location.longitude;
      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=Asia%2FBangkok');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return;
      final code = current['weather_code'] is num ? (current['weather_code'] as num).toInt() : 1;
      if (!mounted) return;
      setState(() {
        _weather = {
          'temperature': (current['temperature_2m'] as num?)?.toDouble(),
          'humidity': (current['relative_humidity_2m'] as num?)?.toInt(),
          'windSpeed': (current['wind_speed_10m'] as num?)?.toDouble(),
          'description': _weatherCodeText(code),
        };
      });
    } catch (e) {
      debugPrint('Lỗi tải thời tiết theo địa điểm: $e');
    } finally {
      if (mounted && !silent) setState(() => _weatherLoading = false);
    }
  }

  String _weatherCodeText(int code) {
    if (code == 0) return 'Trời quang';
    if ([1, 2, 3].contains(code)) return 'Ít mây / nhiều mây';
    if ([45, 48].contains(code)) return 'Sương mù';
    if (code >= 51 && code <= 67) return 'Mưa phùn / mưa nhẹ';
    if (code >= 80 && code <= 82) return 'Mưa rào';
    if (code >= 95) return 'Dông';
    return 'Thời tiết ổn định';
  }

  Widget _buildWeatherCard(Color cardColor, Color textColor, Color subColor) {
    final temp = (_weather?['temperature'] as num?)?.toDouble();
    final humidity = _weather?['humidity'];
    final wind = (_weather?['windSpeed'] as num?)?.toDouble();
    final desc = _weather?['description']?.toString() ?? 'Đang cập nhật';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.14), shape: BoxShape.circle),
          child: const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Thời tiết tại ${spot.name}', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 4),
            if (_weatherLoading && _weather == null)
              Text('Đang tải nhiệt độ, độ ẩm...', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: subColor))
            else
              Text('${temp?.toStringAsFixed(1) ?? '--'}°C • Độ ẩm ${humidity ?? '--'}% • Gió ${wind?.toStringAsFixed(0) ?? '--'} km/h\n$desc', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: subColor, height: 1.35)),
          ]),
        ),
        IconButton(
          tooltip: 'Cập nhật thời tiết',
          onPressed: _weatherLoading ? null : _loadWeather,
          icon: _weatherLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync_rounded, color: AppColors.primary),
        )
      ]),
    );
  }

  Future<void> _submitReview() async {
    if (!AuthState().isLoggedIn) {
      showLoginRequiredDialog(context, featureName: 'Đánh giá địa điểm', isDark: isDark);
      return;
    }
    final id = int.tryParse(spot.id);
    if (id == null) return;
    try {
      await ExtendedApiService.createDanhGia(
        maDiaDiem: id,
        soSao: _rating,
        noiDung: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );
      _reviewController.clear();
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá thành công!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không gửi được đánh giá: $e')));
      }
    }
  }

  void _handleBookmarkToggle(BuildContext context, bool isBookmarked) {
    final isLoggedIn = AuthState().isLoggedIn;
    if (!isLoggedIn) {
      showLoginRequiredDialog(context, featureName: 'Lưu địa điểm yêu thích', isDark: isDark);
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();

      final item = BookmarkItem(
        id: spot.id,
        name: spot.name,
        province: spot.province,
        rating: _liveAverageRating ?? 4.9,
        category: 'Điểm đến',
        color: const Color(0xFF00AE2C),
        icon: Icons.landscape_rounded,
      );

      BookmarkState().toggleBookmark(spot.id, item);

      if (isBookmarked) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã xóa ${spot.name} khỏi Yêu thích.',
              style: const TextStyle(fontFamily: AppTextStyles.fontFamily)),
          backgroundColor: Colors.redAccent,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã lưu ${spot.name} vào Yêu thích!',
              style: const TextStyle(fontFamily: AppTextStyles.fontFamily)),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.black;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final dividerColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: BookmarkState(),
        builder: (context, _) {
          final isBookmarked = BookmarkState().isBookmarked(spot.id);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor:
                    isDark ? const Color(0xFF0F172A) : AppColors.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? const Color(0xFFFFB300)
                              : Colors.white),
                      onPressed: () =>
                          _handleBookmarkToggle(context, isBookmarked),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: spot.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: spot.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                              color: isDark ? Colors.white10 : Colors.black12),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey),
                        )
                      : Image.asset(
                          spot.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: isDark ? Colors.white10 : Colors.black12),
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot.name,
                                style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                    color: textColor),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: AppColors.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${spot.province}, Việt Nam',
                                    style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: subColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB300), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '4.9',
                                style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Về địa điểm này',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      spot.description.isNotEmpty
                          ? spot.description
                          : 'Đang cập nhật thông tin giới thiệu.',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: subColor,
                          height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    Text(
                      'Đánh giá từ người dùng',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: 12),
                    _buildReviewComposer(cardColor, textColor, subColor),
                    const SizedBox(height: 12),
                    if (_reviewsLoading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(12),
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ))
                    else if (_reviews.isEmpty)
                      Text('Chưa có đánh giá nào.',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: subColor))
                    else
                      ..._reviews.map((item) => _buildReviewItem(
                          item, cardColor, textColor, subColor)),
                    _buildWeatherCard(cardColor, textColor, subColor),
                    const SizedBox(height: 20),
                    Divider(color: dividerColor),
                    const SizedBox(height: 10),
                    Text(
                      'Tiện ích & Khám phá',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeatureIcon(Icons.camera_alt_rounded, 'Check-in',
                            cardColor, textColor),
                        _buildFeatureIcon(Icons.restaurant_rounded, 'Ẩm thực',
                            cardColor, textColor),
                        _buildFeatureIcon(Icons.hotel_rounded, 'Lưu trú',
                            cardColor, textColor),
                        _buildFeatureIcon(
                            Icons.map_rounded, 'Bản đồ', cardColor, textColor),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          child: ElevatedButton(
            onPressed: () {
              if (!AuthState().isLoggedIn) {
                showLoginRequiredDialog(context,
                    featureName: 'Lập lịch trình', isDark: isDark);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItineraryScreen(
                    isDark: isDark,
                    initialProvince: spot.province,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text(
              'Lên lịch trình tự động',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewComposer(
      Color cardColor, Color textColor, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Số sao:',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          DropdownButton<double>(
            value: _rating,
            items: const [1, 2, 3, 4, 5]
                .map((e) => DropdownMenuItem<double>(
                    value: e.toDouble(), child: Text('$e sao')))
                .toList(),
            onChanged: (value) => setState(() => _rating = value ?? 5),
          ),
        ]),
        TextField(
          controller: _reviewController,
          minLines: 2,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Chia sẻ đánh giá của bạn...'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
              onPressed: _submitReview, child: const Text('Gửi đánh giá')),
        ),
      ]),
    );
  }

  Widget _buildReviewItem(
      dynamic raw, Color cardColor, Color textColor, Color subColor) {
    final review = raw as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
          const SizedBox(width: 4),
          Text('${review['soSao'] ?? 5}',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(review['hoTen']?.toString() ?? 'Người dùng',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily, color: subColor))),
        ]),
        if ((review['noiDung']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(review['noiDung'].toString(),
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily, color: textColor)),
        ],
      ]),
    );
  }

  Widget _buildFeatureIcon(
      IconData icon, String label, Color bgColor, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor),
        ),
      ],
    );
  }
}
