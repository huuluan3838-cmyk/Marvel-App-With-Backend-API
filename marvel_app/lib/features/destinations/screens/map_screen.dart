import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/shared/widgets/login_dialog.dart';
import 'package:marvel_travel/core/utilities/string_utils.dart';

// ── CẤU HÌNH API ──
final String apiUrl = ApiConfig.baseUrl;

// ── Hàm hỗ trợ Parse số an toàn (Tránh lỗi ép kiểu API) ──
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

String normalizeImagePath(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  if (raw.startsWith('/assets/')) return raw.substring(1);
  if (raw.startsWith('assets/')) return raw;
  final relative = raw.startsWith('/') ? raw.substring(1) : raw;
  return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/$relative';
}

// ── Models ───────────────────────────────────────────────────────────────────
class SubDestination {
  final String id;
  final String name;
  final String imageUrl;

  SubDestination(
      {required this.id, required this.name, required this.imageUrl});

  factory SubDestination.fromJson(Map<String, dynamic> json) {
    return SubDestination(
      id: json['maChiTiet']?.toString() ?? '',
      name: json['tenChiTiet']?.toString() ?? 'Chưa rõ tên',
      imageUrl: normalizeImagePath(json['hinhAnh']),
    );
  }
}

class TouristSpot {
  final String id;
  final String name;
  final String province;
  final String description;
  final LatLng location;
  final String imageUrl;
  final List<SubDestination> subDestinations;

  TouristSpot({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.subDestinations,
  });

  factory TouristSpot.fromJson(Map<String, dynamic> json) {
    var chiTietsList = json['diaDiemChiTiets'] as List? ?? [];

    return TouristSpot(
      id: json['maDiaDiem']?.toString() ?? '',
      name: json['tenDiaDiem']?.toString() ?? 'Chưa cập nhật',
      province: json['tinhThanh']?.toString() ?? '',
      description: json['moTa']?.toString() ?? '',
      location: LatLng(
          _parseDouble(json['viDo']), 
          _parseDouble(json['kinhDo'])),
      imageUrl: normalizeImagePath(json['hinhAnh']),
      subDestinations:
          chiTietsList.map((e) => SubDestination.fromJson(e)).toList(),
    );
  }
}

// ── Giao Diện MapScreen ───────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  final bool isDark;
  const MapScreen({super.key, this.isDark = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<TouristSpot> _spots = [];
  List<TouristSpot> _filteredSpots = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _initMapData();
  }

  Future<void> _initMapData() async {
    await _startLocationTracking();
    await _fetchSpots();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_userLocation!, 15.0);
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((Position pos) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      });
    } catch (e) {
      debugPrint('Lỗi định vị: $e');
    }
  }

  Future<void> _fetchSpots() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http
          .get(Uri.parse('$apiUrl/DiaDiem'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _spots = data.map((json) => TouristSpot.fromJson(json)).toList();
            _filteredSpots = List.from(_spots);
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitAllMarkers();
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi kết nối API: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fitAllMarkers() {
    if (_filteredSpots.isEmpty) return;
    final points = _filteredSpots.map((s) => s.location).toList();
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 120),
      ),
    );
  }

  void _filterSpots(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpots = List.from(_spots);
      } else {
        _filteredSpots = _spots
            .where((spot) =>
                StringUtils.containsIgnoreCaseAndDiacritics(spot.name, query) ||
                StringUtils.containsIgnoreCaseAndDiacritics(
                    spot.province, query))
            .toList();
      }
    });
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 14.0);
    FocusScope.of(context).unfocus();
  }

  Widget _buildMarkerImage(String url) {
    if (url.isEmpty) return const Icon(Icons.place, color: AppColors.primary);
    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.place, color: AppColors.primary));
    }
    return Image.asset(url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.place, color: AppColors.primary));
  }

  void _showSpotDetails(TouristSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpotDetailSheet(
        spot: spot,
        isDark: widget.isDark,
        userLocation: _userLocation,
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7F5),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(16.047079, 108.206230),
              initialZoom: 5.2,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.marvel_app',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      child: ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  ..._filteredSpots.map((spot) => Marker(
                        point: spot.location,
                        width: 58,
                        height: 70,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showSpotDetails(spot),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: _buildMarkerImage(spot.imageUrl),
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _filterSpots,
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Tìm điểm đến, tỉnh thành...',
                      hintStyle: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: isDark ? Colors.white54 : Colors.grey),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: isDark ? Colors.white54 : Colors.grey),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: isDark ? Colors.white54 : Colors.grey),
                              onPressed: () {
                                _searchCtrl.clear();
                                _filterSpots('');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                if (_searchCtrl.text.isNotEmpty && _filteredSpots.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10)
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredSpots.length,
                      itemBuilder: (context, index) {
                        final spot = _filteredSpots[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.location_on,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(spot.name,
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 14)),
                          subtitle: Text(spot.province,
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                  fontSize: 12)),
                          onTap: () {
                            _moveToLocation(spot.location);
                            _showSpotDetails(spot);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'fit_all',
                  mini: true,
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  onPressed: _fitAllMarkers,
                  child: const Icon(Icons.zoom_out_map_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'my_location',
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  onPressed: () {
                    if (_userLocation != null) {
                      _moveToLocation(_userLocation!);
                    } else {
                      _startLocationTracking();
                    }
                  },
                  child: const Icon(Icons.my_location_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOTTOM SHEET CHI TIẾT ĐỊA ĐIỂM ──────────────────────────────────────────
class _SpotDetailSheet extends StatefulWidget {
  final TouristSpot spot;
  final bool isDark;
  final LatLng? userLocation;

  const _SpotDetailSheet({
    required this.spot,
    required this.isDark,
    this.userLocation,
  });

  @override
  State<_SpotDetailSheet> createState() => _SpotDetailSheetState();
}

class _SpotDetailSheetState extends State<_SpotDetailSheet> {
  final Set<String> _selectedSubDestinations = {};
  String _distanceText = '';

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  void _calculateDistance() {
    if (widget.userLocation != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
        widget.spot.location.latitude,
        widget.spot.location.longitude,
      );

      setState(() {
        if (distanceInMeters >= 1000) {
          _distanceText =
              'Cách bạn ${(distanceInMeters / 1000).toStringAsFixed(1)} km';
        } else {
          _distanceText = 'Cách bạn ${distanceInMeters.toStringAsFixed(0)} m';
        }
      });
    }
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) return Container(color: Colors.grey);
    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey));
    }
    return Image.asset(url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: _buildImage(widget.spot.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.spot.name,
                                style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    color: textColor)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(widget.spot.province,
                                    style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        color: subColor,
                                        fontWeight: FontWeight.w500)),
                                if (_distanceText.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _distanceText,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB300), size: 18),
                            const SizedBox(width: 4),
                            Text('4.8',
                                style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.spot.description,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: subColor,
                          height: 1.5)),
                  const SizedBox(height: 24),
                  if (widget.spot.subDestinations.isNotEmpty) ...[
                    Text('Điểm tham quan nổi bật',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: textColor)),
                    const SizedBox(height: 12),
                    ...widget.spot.subDestinations.map((sub) {
                      final isSelected =
                          _selectedSubDestinations.contains(sub.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white10 : Colors.black12),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _showSubDestinationDetail(context, sub);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: _buildImage(sub.imageUrl),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(sub.name,
                                          style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: textColor)),
                                      const SizedBox(height: 4),
                                      Text('Nhấn để xem chi tiết',
                                          style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 12,
                                              color: subColor)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedSubDestinations.remove(sub.id);
                                      } else {
                                        _selectedSubDestinations.add(sub.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 18, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _selectedSubDestinations.isEmpty
                    ? null
                    : () {
                        if (!AuthState().isLoggedIn) {
                          showLoginRequiredDialog(context,
                              featureName: 'Lập lịch trình', isDark: isDark);
                          return;
                        }
                        final selectedNames = widget.spot.subDestinations
                            .where(
                                (s) => _selectedSubDestinations.contains(s.id))
                            .map((s) => s.name)
                            .join(', ');

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Đã chọn điểm để lập lịch trình: $selectedNames',
                                style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily)),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                child: const Text('Tạo lịch trình từ các điểm đã chọn',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubDestinationDetail(BuildContext context, SubDestination sub) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: _buildImage(sub.imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Thông tin chi tiết',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đây là một trong những điểm vui chơi giải trí và tham quan nổi bật tại ${widget.spot.name}. Nơi đây thu hút đông đảo du khách bởi vẻ đẹp độc đáo và những trải nghiệm thú vị.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        height: 1.6,
                        color: widget.isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
