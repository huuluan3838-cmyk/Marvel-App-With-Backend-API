import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';
import 'package:marvel_travel/features/itinerary/screens/my_itineraries_screen.dart';
import 'package:marvel_travel/features/auth/screens/auth_screen.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

class ItineraryScreen extends StatefulWidget {
  final bool isDark;
  final String? initialProvince;

  const ItineraryScreen({super.key, this.isDark = false, this.initialProvince});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  Map<String, List<Map<String, String>>> _destinationsData = {};
  List<String> _provinces = [];
  String _selectedProvince = 'Hà Nội';
  
  // Set chứa tên các địa điểm người dùng chủ động click chọn
  final Set<String> _userSelectedSpots = {};
  bool _isLoadingData = true;

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStyle = 'Khám phá';

  final List<String> _styles = [
    'Khám phá',
    'Nghỉ dưỡng',
    'Tiết kiệm',
    'Mạo hiểm',
    'Gia đình'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDestinationsFromApi();
  }

  Future<void> _fetchDestinationsFromApi() async {
    try {
      final resDiaDiem = await http.get(ApiConfig.uri('DiaDiem'));

      if (resDiaDiem.statusCode == 200) {
        final List<dynamic> diaDiemData = jsonDecode(resDiaDiem.body);

        Map<String, List<Map<String, String>>> groupedData = {};
        
        for (var item in diaDiemData) {
          String province = item['tinhThanh']?.toString().trim() ?? 'Khác';
          String desc = item['moTa']?.toString() ?? '';
          
          if (!groupedData.containsKey(province)) groupedData[province] = [];

          var chiTiets = item['diaDiemChiTiets'] as List<dynamic>?;
          if (chiTiets != null && chiTiets.isNotEmpty) {
            for (var ct in chiTiets) {
              String name = ct['tenChiTiet']?.toString() ?? '';
              String rawImage = ct['hinhAnh']?.toString() ?? '';

              // Chuẩn hoá đường dẫn ảnh ưu tiên dùng nguyên trạng từ SQL, nếu thiếu thì tự bổ sung
              String imagePath = rawImage;
              if (!imagePath.startsWith('http') && !imagePath.startsWith('assets/')) {
                if (imagePath.startsWith('/')) imagePath = imagePath.substring(1);
                if (!imagePath.contains('/')) {
                  imagePath = 'assets/images/details/$imagePath';
                }
              }

              groupedData[province]!.add({
                'name': name,
                'desc': desc,
                'image': imagePath,
              });
            }
          } else {
            // Fallback: Nếu không có chi tiết, dùng chính địa điểm đó
            String name = item['tenDiaDiem']?.toString() ?? '';
            String rawImage = item['hinhAnh']?.toString() ?? '';
            String imagePath = rawImage.startsWith('http') || rawImage.startsWith('assets/')
                ? rawImage
                : 'assets/images/$rawImage';

            groupedData[province]!.add({
              'name': name, 'desc': desc, 'image': imagePath,
            });
          }
        }
        
        // Xoá các tỉnh không có địa điểm nào
        groupedData.removeWhere((key, value) => value.isEmpty);

        if (mounted) {
          setState(() {
            _destinationsData = groupedData;
            _provinces = groupedData.keys.toList();
            _selectedProvince = widget.initialProvince ?? (_provinces.isNotEmpty ? _provinces.first : 'Hà Nội');
            if (!_provinces.contains(_selectedProvince) && _provinces.isNotEmpty) _selectedProvince = _provinces.first;
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải API Địa Điểm và Chi Tiết: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now(),
      end: _endDate ?? DateTime.now().add(const Duration(days: 2)),
    );

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _startDate = newRange.start;
        _endDate = newRange.end;
      });
    }
  }

  Future<void> _generateItinerary() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ngày đi!')));
      return;
    }
    
    if (_destinationsData[_selectedProvince] == null || _destinationsData[_selectedProvince]!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có dữ liệu địa điểm cho khu vực này!')));
      return;
    }

    // Hiển thị Dialog Loading AI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AILoadingDialog(isDark: widget.isDark),
    );

    // Giả lập thời gian AI xử lý
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) Navigator.pop(context); // Đóng Loading Dialog

    int days = _endDate!.difference(_startDate!).inDays + 1;
    final availablePlaces = _destinationsData[_selectedProvince]!;

    // 1. Chia tách điểm đến: Ưu tiên người dùng chọn, còn lại để AI tự lấy
    List<Map<String, String>> userPicks = [];
    List<Map<String, String>> aiPicks = [];
    
    for (var place in availablePlaces) {
      if (_userSelectedSpots.contains(place['name'])) {
        userPicks.add(place);
      } else {
        aiPicks.add(place);
      }
    }
    
    aiPicks.shuffle(); // Randomize AI picks
    List<Map<String, String>> finalPool = [...userPicks, ...aiPicks];

    // Phân bổ lịch trình theo từng ngày
    int totalToPick = (days * 2).clamp(1, finalPool.length); 
    List<Map<String, String>> selectedPool = finalPool.take(totalToPick).toList();
    if (userPicks.length > totalToPick) selectedPool = userPicks; // Đảm bảo lấy đủ ý muốn của user

    Map<int, List<Map<String, String>>> dailyPlan = {};
    int placesPerDay = (selectedPool.length / days).ceil();
    if (placesPerDay == 0) placesPerDay = 1;

    int currentIndex = 0;
    for (int i = 1; i <= days; i++) {
      dailyPlan[i] = [];
      for (int j = 0; j < placesPerDay; j++) {
        if (currentIndex < selectedPool.length) {
          dailyPlan[i]!.add(selectedPool[currentIndex]);
          currentIndex++;
        }
      }
      // Đảm bảo ngày nào cũng có điểm đi nếu hết điểm để chọn
      if (dailyPlan[i]!.isEmpty && selectedPool.isNotEmpty) {
        dailyPlan[i]!.add(selectedPool.first);
      }
    }

    _showResultBottomSheet(dailyPlan, days);
  }

  void _showResultBottomSheet(Map<int, List<Map<String, String>>> dailyPlan, int days) {
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.black;
    final subColor = widget.isDark ? Colors.white70 : AppColors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Lịch trình hoàn hảo của bạn',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: textColor)),
            const SizedBox(height: 8),
            Text(
                '$_selectedProvince • ${_startDate != null ? DateFormat('dd/MM').format(_startDate!) : ""} - ${_endDate != null ? DateFormat('dd/MM').format(_endDate!) : ""} • $_selectedStyle',
                style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: days,
                itemBuilder: (context, index) {
                  int dayNum = index + 1;
                  var places = dailyPlan[dayNum] ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: Text(
                          'Ngày $dayNum',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          )
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...places.asMap().entries.map((entry) {
                         int pIndex = entry.key;
                         var p = entry.value;
                         bool isLast = pIndex == places.length - 1;
                         return Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Column(
                               children: [
                                 Container(
                                   width: 12, height: 12,
                                   decoration: const BoxDecoration(
                                     color: AppColors.primary,
                                     shape: BoxShape.circle
                                   )
                                 ),
                                 if (!isLast)
                                   Container(
                                     width: 2,
                                     height: 80, // Chiều cao đường viền Timeline
                                     color: AppColors.primary.withOpacity(0.3),
                                   )
                                 else
                                   const SizedBox(height: 20),
                               ],
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Container(
                                 margin: const EdgeInsets.only(bottom: 20),
                                 decoration: BoxDecoration(
                                   color: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                                   borderRadius: BorderRadius.circular(16)
                                 ),
                                 clipBehavior: Clip.antiAlias,
                                 child: Row(
                                   children: [
                                      Image.asset(
                                        p['image']!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_,__,___) => Container(width: 80, height: 80, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p['name']!, style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                                              const SizedBox(height: 4),
                                              Text(p['desc']!, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: subColor, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ]
                                          ),
                                        ),
                                      )
                                   ]
                                 ),
                               ),
                             ),
                           ],
                         );
                      }).toList(),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),

            // Nút Lưu lên API
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
                ]
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!AuthState().isLoggedIn) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Vui lòng đăng nhập để lưu!')));
                      return;
                    }

                    String savedStr = dailyPlan.values.expand((l) => l).map((p) => p['name']).join(', ');

                    // Gọi hàm addItinerary để POST lên Server
                    bool success = await ItineraryState().addItinerary(
                      title: 'Hành trình $_selectedProvince',
                      destination: savedStr,
                      startDate: _startDate ?? DateTime.now(),
                      endDate: _endDate ?? DateTime.now(),
                      style: _selectedStyle,
                    );

                    if (mounted) {
                      Navigator.pop(context); // Đóng BottomSheet
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Đã lưu thành công! Bạn có thể xem ở "Lịch trình của tôi".')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Lưu thất bại. Vui lòng thử lại!')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Lưu lịch trình này',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5);
    final cardColor = widget.isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.black;
    final subColor = widget.isDark ? Colors.white54 : AppColors.grey;

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
                color: widget.isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
          ),
        ),
        title: Text('Lập lịch trình AI',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: textColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded,
                color: AppColors.primary),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        MyItinerariesScreen(isDark: widget.isDark))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điểm đến của bạn',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: widget.isDark ? Colors.white10 : Colors.black12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProvince,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary),
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w600),
                  items: _provinces
                      .map((prov) =>
                          DropdownMenuItem(value: prov, child: Text(prov)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null && val != _selectedProvince) {
                      setState(() {
                         _selectedProvince = val;
                         _userSelectedSpots.clear(); // Xoá điểm chọn khi đổi tỉnh
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Các điểm đến nổi bật',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('(Chọn để thêm, hoặc AI tự gợi ý)',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: subColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingData
             ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
             : _destinationsData[_selectedProvince] == null || _destinationsData[_selectedProvince]!.isEmpty
             ? Text('Chưa có dữ liệu chi tiết.', style: TextStyle(color: subColor, fontFamily: AppTextStyles.fontFamily))
             : SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _destinationsData[_selectedProvince]!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = _destinationsData[_selectedProvince]![index];
                  final isSelected = _userSelectedSpots.contains(place['name']);
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _userSelectedSpots.remove(place['name']);
                        } else {
                          _userSelectedSpots.add(place['name']!);
                        }
                      });
                    },
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                           color: isSelected ? AppColors.primary : (widget.isDark ? Colors.white10 : Colors.black12),
                           width: isSelected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              place['image']!.startsWith('http')
                               ? Image.network(place['image']!, height: 90, width: 140, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 90, color: Colors.grey))
                               : Image.asset(place['image']!, height: 90, width: 140, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 90, color: Colors.grey)),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(place['name']!, style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 13, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(place['desc']!, style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, color: subColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ]
                                )
                              )
                            ]
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            )
                        ],
                      )
                    ),
                  );
                }
              )
            ),
            const SizedBox(height: 24),
            Text('Thời gian đi',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            widget.isDark ? Colors.white10 : Colors.black12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _startDate == null
                            ? 'Chọn ngày đi và về'
                            : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            color: _startDate == null ? subColor : textColor,
                            fontWeight: _startDate == null
                                ? FontWeight.normal
                                : FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Phong cách du lịch',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _styles.map((style) {
                final isSelected = style == _selectedStyle;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStyle = style),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      style,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : textColor),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _generateItinerary,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4),
                child: const Text('Lên lịch trình tự động',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Màn hình Dialog Loading hiệu ứng AI sinh lịch trình
class _AILoadingDialog extends StatefulWidget {
  final bool isDark;
  const _AILoadingDialog({required this.isDark});

  @override
  State<_AILoadingDialog> createState() => _AILoadingDialogState();
}

class _AILoadingDialogState extends State<_AILoadingDialog> {
  int _step = 0;
  final List<String> _steps = [
    'AI đang phân tích sở thích...',
    'Đang chọn lọc các điểm đến tốt nhất...',
    'Đang tối ưu hóa khoảng di chuyển...',
    'Hoàn thiện lịch trình của bạn!'
  ];

  @override
  void initState() {
    super.initState();
    _animateSteps();
  }

  void _animateSteps() async {
    for (int i = 0; i < _steps.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
               height: 60, width: 60,
               child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
            ),
            const SizedBox(height: 24),
            const Text(
              'Lên lịch trình thông minh',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                 _steps[_step],
                 key: ValueKey<int>(_step),
                 style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.grey),
                 textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
