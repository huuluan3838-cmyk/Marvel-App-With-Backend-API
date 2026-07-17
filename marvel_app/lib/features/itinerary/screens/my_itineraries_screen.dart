import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

// ── CẤU HÌNH API ──
final String apiUrl = ApiConfig.baseUrl;

// ── Model Lịch Trình (Mapping với JSON từ Server) ────────────────────────────
class Itinerary {
  final int id;
  final String title;
  final String destination;
  final String date;
  final String duration;
  final String imagePath;
  final bool isUpcoming;

  Itinerary({
    required this.id,
    required this.title,
    required this.destination,
    required this.date,
    required this.duration,
    required this.imagePath,
    required this.isUpcoming,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    // Xử lý chuỗi ngày tháng từ Server
    String dateRange = '';
    String durationStr = '';

    if (json['ngayBatDau'] != null && json['ngayKetThuc'] != null) {
      DateTime start = DateTime.parse(json['ngayBatDau']);
      DateTime end = DateTime.parse(json['ngayKetThuc']);
      dateRange =
          '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';

      int days = end.difference(start).inDays + 1;
      int nights = days > 1 ? days - 1 : 0;
      durationStr = '$days Ngày $nights Đêm';
    }

    return Itinerary(
      id: json['maLichTrinh'] ?? 0,
      title: json['tieuDe'] ?? 'Hành trình mới',
      destination: json['danhSachDiaDiem'] ?? 'Nhiều địa điểm',
      date: dateRange,
      duration: durationStr,
      imagePath: 'assets/images/VinhHaLong.jpg', // Tạm dùng ảnh mặc định
      isUpcoming: json['trangThai'] == 'Upcoming',
    );
  }
}

// ── Quản lý State Lịch trình (Gọi API) ───────────────────────────────────────
class ItineraryState extends ChangeNotifier {
  static final ItineraryState _i = ItineraryState._();
  factory ItineraryState() => _i;
  ItineraryState._();

  List<Itinerary> _itineraries = [];
  bool isLoading = false;

  List<Itinerary> get itineraries => _itineraries;
  List<Itinerary> get upcomingItineraries =>
      _itineraries.where((i) => i.isUpcoming).toList();
  List<Itinerary> get pastItineraries =>
      _itineraries.where((i) => !i.isUpcoming).toList();

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  // TẢI DANH SÁCH TỪ API
  Future<void> fetchItineraries() async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return;

    final int userId = AuthState().userId ?? 2;

    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/LichTrinh/user/$userId'),
        headers: {'Authorization': 'Bearer ${AuthState().token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _itineraries = data.map((json) => Itinerary.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Lỗi fetchItineraries: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // THÊM LỊCH TRÌNH MỚI LÊN API
  Future<bool> addItinerary({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String style,
  }) async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return false;

    final int userId = AuthState().userId ?? 2;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/LichTrinh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState().token}'
        },
        body: jsonEncode({
          'maNguoiDung': userId,
          'tieuDe': title,
          'danhSachDiaDiem': destination,
          'ngayBatDau': _dateOnly(startDate),
          'ngayKetThuc': _dateOnly(endDate),
          'phongCach': style,
          'soNguoi': 1,
          'trangThai': 'Upcoming'
        }),
      );

      if (response.statusCode == 200) {
        fetchItineraries(); // Tải lại danh sách sau khi thêm thành công
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi addItinerary: $e');
    }
    return false;
  }
}

// ── Giao diện danh sách ──────────────────────────────────────────────────────
class MyItinerariesScreen extends StatefulWidget {
  final bool isDark;
  const MyItinerariesScreen({super.key, this.isDark = false});

  @override
  State<MyItinerariesScreen> createState() => _MyItinerariesScreenState();
}

class _MyItinerariesScreenState extends State<MyItinerariesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Gọi API lấy dữ liệu khi vừa mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState().isLoggedIn) {
        ItineraryState().fetchItineraries();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final textColor = widget.isDark ? Colors.white : AppColors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Lịch trình của tôi',
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: textColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: widget.isDark ? Colors.white54 : AppColors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16),
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Đã hoàn thành'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([AuthState(), ItineraryState()]),
        builder: (context, child) {
          if (!AuthState().isLoggedIn) {
            return Center(
              child: Text('Vui lòng đăng nhập để xem lịch trình',
                  style: TextStyle(
                      color: textColor, fontFamily: AppTextStyles.fontFamily)),
            );
          }

          if (ItineraryState().isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(ItineraryState().upcomingItineraries,
                  'Bạn chưa có lịch trình nào sắp tới', widget.isDark),
              _buildList(ItineraryState().pastItineraries,
                  'Bạn chưa có lịch trình nào đã hoàn thành', widget.isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Itinerary> list, String emptyMsg, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff_rounded,
                size: 80,
                color:
                    isDark ? Colors.white24 : AppColors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(emptyMsg,
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    color: isDark ? Colors.white54 : AppColors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ItineraryCard(itinerary: list[index], isDark: isDark),
        );
      },
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final bool isDark;

  const _ItineraryCard({required this.itinerary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Image.asset(itinerary.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(itinerary.title,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(itinerary.duration,
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(itinerary.destination,
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(itinerary.date,
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            color: subColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
