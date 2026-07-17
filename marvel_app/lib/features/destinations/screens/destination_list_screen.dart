import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/destinations/screens/map_screen.dart'; // Sử dụng nguồn dữ liệu TouristSpot
import 'package:marvel_travel/features/destinations/screens/destination_detail_screen.dart';

final String apiUrl = ApiConfig.baseUrl;

class DestinationListScreen extends StatefulWidget {
  final bool isDark;
  const DestinationListScreen({super.key, this.isDark = false});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQueryNormalized = '';
  String _selectedRegion = 'Tất cả';

  List<TouristSpot> _spots = [];
  bool _isLoading = true;

  final List<String> _regions = const [
    'Tất cả',
    'Miền Bắc',
    'Miền Trung',
    'Miền Nam'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDestinations();
  }

  // Gọi API lấy dữ liệu điểm đến
  Future<void> _fetchDestinations() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl/DiaDiem'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _spots = data.map((json) => TouristSpot.fromJson(json)).toList();
          });
        }
      } else {
        debugPrint('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi kết nối API Destination: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _normalizeString(String source) {
    var withSign =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    var noSign =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    String result = source;
    for (int i = 0; i < withSign.length; i++) {
      result = result.replaceAll(withSign[i], noSign[i]);
    }
    return result.toLowerCase().trim();
  }

  String _getRegionOfProvince(String province) {
    final p = province.toLowerCase();
    if (p.contains('hà nội') ||
        p.contains('quảng ninh') ||
        p.contains('lào cai') ||
        p.contains('hà giang') ||
        p.contains('ninh bình')) {
      return 'Miền Bắc';
    } else if (p.contains('quảng nam') ||
        p.contains('đà nẵng') ||
        p.contains('khánh hòa') ||
        p.contains('huế')) {
      return 'Miền Trung';
    } else {
      return 'Miền Nam';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final bgColor = isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final subColor = isDark ? Colors.white60 : AppColors.grey;

    // Lọc điểm đến dựa trên API thực tế
    final filteredSpots = _spots.where((spot) {
      final region = _getRegionOfProvince(spot.province);
      final matchesRegion =
          _selectedRegion == 'Tất cả' || region == _selectedRegion;
      if (!matchesRegion) return false;

      if (_searchQueryNormalized.isEmpty) return true;

      final nameNormalized = _normalizeString(spot.name);
      final provinceNormalized = _normalizeString(spot.province);

      return nameNormalized.contains(_searchQueryNormalized) ||
          provinceNormalized.contains(_searchQueryNormalized);
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
          'Điểm đến hấp dẫn',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF004311),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    color: textColor),
                onChanged: (text) => setState(
                    () => _searchQueryNormalized = _normalizeString(text)),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm điểm đến, tỉnh thành...',
                  hintStyle: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: isDark ? Colors.white60 : AppColors.grey),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.primary, size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQueryNormalized = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _regions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = region == _selectedRegion;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRegion = region),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF006D32)
                          : (isDark ? Colors.white10 : const Color(0xFFE8EFEA)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      region,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : filteredSpots.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy địa điểm phù hợp',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: subColor),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filteredSpots.length,
                        itemBuilder: (context, index) {
                          final spot = filteredSpots[index];
                          final spotRegion =
                              _getRegionOfProvince(spot.province);
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DestinationDetailScreen(
                                      spot: spot, isDark: isDark),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.3 : 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        spot.imageUrl.startsWith('http')
                                            ? CachedNetworkImage(
                                                imageUrl: spot.imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                        color: isDark
                                                            ? Colors.white10
                                                            : Colors.black12),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black12,
                                                  child: const Icon(
                                                      Icons.landscape_rounded,
                                                      size: 40,
                                                      color: Colors.grey),
                                                ),
                                              )
                                            : Image.asset(
                                                spot.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black12,
                                                  child: const Icon(
                                                      Icons.landscape_rounded,
                                                      size: 40,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF006D32)
                                                  .withOpacity(0.85),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              spotRegion.toUpperCase(),
                                              style: const TextStyle(
                                                fontFamily:
                                                    AppTextStyles.fontFamily,
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          spot.name,
                                          style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${spot.province}, Việt Nam',
                                          style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 12,
                                              color: subColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: Color(0xFFFFB300),
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '4.9',
                                              style: TextStyle(
                                                  fontFamily:
                                                      AppTextStyles.fontFamily,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor),
                                            ),
                                            const Spacer(),
                                            Icon(Icons.chevron_right_rounded,
                                                color: isDark
                                                    ? Colors.white30
                                                    : AppColors.grey
                                                        .withOpacity(0.5),
                                                size: 18),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
