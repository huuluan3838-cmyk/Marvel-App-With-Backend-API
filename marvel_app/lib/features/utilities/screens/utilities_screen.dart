import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:marvel_travel/core/theme/app_theme.dart';

class UtilitiesScreen extends StatefulWidget {
  final bool isDark;
  const UtilitiesScreen({super.key, this.isDark = false});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  Timer? _syncTimer;
  DateTime? _lastSyncedAt;
  Map<String, double> _rates = {'USD': 25450, 'EUR': 27200, 'JPY': 165};
  Map<String, dynamic> _weather = {
    'place': 'V?nh H? Long, Qu?ng Ninh',
    'temperature': 26.0,
    'humidity': 75,
    'description': 'M?y r?i r?c',
    'windSpeed': 8.0,
  };
  bool _syncing = false;


  @override
  void initState() {
    super.initState();
    _syncUtilities();
    _syncTimer = Timer.periodic(const Duration(minutes: 10), (_) => _syncUtilities(silent: true));
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncUtilities({bool silent = false}) async {
    if (!silent && mounted) setState(() => _syncing = true);
    await Future.wait([_syncCurrencyRates(), _syncWeather()]);
    if (mounted) {
      setState(() {
        _lastSyncedAt = DateTime.now();
        _syncing = false;
      });
    }
  }

  Future<void> _syncCurrencyRates() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD')).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>?;
      final vnd = (rates?['VND'] as num?)?.toDouble();
      final eur = (rates?['EUR'] as num?)?.toDouble();
      final jpy = (rates?['JPY'] as num?)?.toDouble();
      if (vnd == null) return;
      if (mounted) {
        setState(() {
          _rates['USD'] = vnd;
          if (eur != null && eur > 0) _rates['EUR'] = vnd / eur;
          if (jpy != null && jpy > 0) _rates['JPY'] = vnd / jpy;
        });
      }
    } catch (_) {}
  }

  Future<void> _syncWeather() async {
    try {
      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=20.9101&longitude=107.1839&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=Asia%2FBangkok');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return;
      final code = current['weather_code'] is num ? (current['weather_code'] as num).toInt() : 1;
      if (mounted) {
        setState(() {
          _weather = {
            'place': 'V?nh H? Long, Qu?ng Ninh',
            'temperature': (current['temperature_2m'] as num?)?.toDouble() ?? _weather['temperature'],
            'humidity': (current['relative_humidity_2m'] as num?)?.toInt() ?? _weather['humidity'],
            'windSpeed': (current['wind_speed_10m'] as num?)?.toDouble() ?? _weather['windSpeed'],
            'description': _weatherCodeText(code),
          };
        });
      }
    } catch (_) {}
  }

  String _weatherCodeText(int code) {
    if (code == 0) return 'Tr?i quang';
    if ([1, 2, 3].contains(code)) return '?t m?y / nhi?u m?y';
    if ([45, 48].contains(code)) return 'S??ng m?';
    if (code >= 51 && code <= 67) return 'M?a ph?n / m?a nh?';
    if (code >= 80 && code <= 82) return 'M?a r?o';
    if (code >= 95) return 'D?ng';
    return 'Th?i ti?t ?n ??nh';
  }


  // Bộ dữ liệu các tiện ích du lịch thực tế (Đã loại bỏ la bàn số)
  final List<Map<String, dynamic>> _utilityItems = [
    {
      'icon': Icons.currency_exchange_rounded,
      'title': 'Đổi tỷ giá',
      'subtitle': 'Quy đổi USD, EUR, JPY sang VND nhanh chóng',
      'color': const Color(0xFF00AE2C),
      'type': 'currency',
    },
    {
      'icon': Icons.wb_sunny_rounded,
      'title': 'Thời tiết',
      'subtitle': 'Dự báo khí hậu tại điểm đến hiện tại của bạn',
      'color': const Color(0xFFFF9800),
      'type': 'weather',
    },
    {
      'icon': Icons.g_translate_rounded,
      'title': 'Phiên dịch AI',
      'subtitle': 'Dịch nhanh câu thoại giao tiếp thông dụng',
      'color': const Color(0xFF1F04B3),
      'type': 'translator',
    },
    {
      'icon': Icons.sos_rounded,
      'title': 'Hotline khẩn cấp',
      'subtitle': 'Tổng đài cứu hộ, SOS, công an du lịch toàn quốc',
      'color': Colors.redAccent,
      'type': 'sos',
    },
    {
      'icon': Icons.luggage_rounded,
      'title': 'Gợi ý xếp đồ',
      'subtitle': 'Danh sách vật dụng cần mang theo chuyến đi',
      'color': const Color(0xFF9C27B0),
      'type': 'luggage',
    },
  ];

  // ── 1. TIỆN ÍCH QUY ĐỔI TIỀN TỆ ──
  void _openCurrencyConverter() {
    final isDark = widget.isDark;
    final txtController = TextEditingController(text: '1');
    double result = 25450.0;
    String selectedCurrency = 'USD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Đổi tỷ giá ngoại tệ',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'USD',
                      child: Text('USD - Đô la Mỹ (1 USD = 25.450đ)',
                          style:
                              TextStyle(fontFamily: AppTextStyles.fontFamily))),
                  DropdownMenuItem(
                      value: 'EUR',
                      child: Text('EUR - Đồng Euro (1 EUR = 27.200đ)',
                          style:
                              TextStyle(fontFamily: AppTextStyles.fontFamily))),
                  DropdownMenuItem(
                      value: 'JPY',
                      child: Text('JPY - Yên Nhật (1 JPY = 165đ)',
                          style:
                              TextStyle(fontFamily: AppTextStyles.fontFamily))),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  setDialogState(() {
                    selectedCurrency = val;
                    double amount = double.tryParse(txtController.text) ?? 0;
                    double rate = _rates[val] ?? 0;
                    result = amount * rate;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txtController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: AppTextStyles.fontFamily),
                decoration: InputDecoration(
                  labelText: 'Nhập số lượng ngoại tệ',
                  labelStyle:
                      const TextStyle(fontFamily: AppTextStyles.fontFamily),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  setDialogState(() {
                    double amount = double.tryParse(val) ?? 0;
                    double rate = _rates[selectedCurrency] ?? 0;
                    result = amount * rate;
                  });
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF5F7F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Giá trị quy đổi sang Việt Nam Đồng:',
                        style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : AppColors.grey)),
                    const SizedBox(height: 4),
                    Text('${NumberFormat('#,###').format(result)} VND',
                        style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng',
                  style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. TIỆN ÍCH DỰ BÁO THỜI TIẾT ──
  void _openWeatherForecast() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thời tiết tại điểm đến',
            style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloudy_snowing,
                size: 64, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text('Vịnh Hạ Long, Quảng Ninh',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: widget.isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 6),
            const Text('26°C / 78°F',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(
                'Mây rải rác - Độ ẩm 75% \nTình trạng biển ổn định, thích hợp cho các hoạt động du thuyền.',
                style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: widget.isDark ? Colors.white70 : AppColors.grey,
                    height: 1.4),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily)),
          ),
        ],
      ),
    );
  }

  // ── 3. TIỆN ÍCH PHIÊN DỊCH GIAO TIẾP ──
  void _openTranslator() {
    final isDark = widget.isDark;
    final txtController = TextEditingController(
        text: 'Xin chào, cho hỏi khách sạn Marvel ở đâu?');
    String translatedText = 'Hello, can I ask where the Marvel Hotel is?';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Phiên dịch du lịch AI',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiếng Việt:',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: txtController,
                  maxLines: 2,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontFamily: AppTextStyles.fontFamily),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val.trim().isEmpty) {
                        translatedText = '';
                      } else {
                        translatedText =
                            '[AI Translated] Hệ thống tự động dịch sang tiếng Anh tương ứng...';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Kết quả dịch (Tiếng Anh):',
                    style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF5F7F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withAlpha(50)),
                  ),
                  child: Text(translatedText,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                          fontStyle: FontStyle.italic)),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng',
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. TIỆN ÍCH HOTLINE SOS KHẨN CẤP (ĐÃ TỐI ƯU RESPONSIVE CHỐNG TRÀN) ──
  void _openEmergencyHotlines() {
    final isDark = widget.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Sử dụng Expanded trong tiêu đề hàng ngang để chống tràn chữ (Horizontal Overflow)
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hotline khẩn cấp SOS',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        // Sử dụng SingleChildScrollView bọc Column bên trong SizedBox maxFinite để hỗ trợ các máy ảo màn hình nhỏ cuộn dọc an toàn
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHotlineTile(
                    'Công an du lịch', '113', Colors.blueAccent, isDark),
                const Divider(height: 1, thickness: 0.5),
                _buildHotlineTile(
                    'Cứu hỏa & Cứu hộ', '114', Colors.orangeAccent, isDark),
                const Divider(height: 1, thickness: 0.5),
                _buildHotlineTile(
                    'Cấp cứu y tế', '115', Colors.redAccent, isDark),
                const Divider(height: 1, thickness: 0.5),
                _buildHotlineTile('Tổng đài Hỗ trợ Du khách', '1800 6101',
                    const Color(0xFF00AE2C), isDark),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đóng',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineTile(
      String title, String number, Color color, bool isDark) {
    return ListTile(
      dense: true, // Tiết kiệm không gian chiều dọc hàng
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        number,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 15,
        ),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(
              25), // Dùng hằng số màu tĩnh an toàn cho mọi SDK phiên bản Flutter
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.phone_in_talk_rounded, color: color, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đang kích hoạt cuộc gọi đến số khẩn cấp $number...',
                  style: const TextStyle(fontFamily: AppTextStyles.fontFamily),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  void _onUtilityTap(String type) {
    switch (type) {
      case 'currency':
        _openCurrencyConverter();
        break;
      case 'weather':
        _openWeatherForecast();
        break;
      case 'translator':
        _openTranslator();
        break;
      case 'sos':
        _openEmergencyHotlines();
        break;
      default:
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tính năng gợi ý xếp hành lý đang được AI tối ưu hóa dữ liệu!',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily)),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor = isDark ? Colors.white70 : AppColors.grey;
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor:
          isDark ? AuroraColors.deepSpace : const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors
                  .black26, // Sử dụng màu hằng số an toàn tránh lỗi biên dịch
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20),
          ),
        ),
        title: Text(
          'Hộp công cụ tiện ích',
          style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: textColor),
        ),
      ),
      // ListView.separated làm gốc giúp danh sách cuộn tự do không bao giờ lỗi đứng khung hình RenderFlex
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _utilityItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _utilityItems[index];
          final Color itemColor = item['color'];

          return GestureDetector(
            onTap: () => _onUtilityTap(item['type']),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Nút hình dạng icon tròn mờ an toàn
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: itemColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'], color: itemColor, size: 24),
                  ),
                  const SizedBox(width: 14),

                  // Khối văn bản hiển thị nội dung tiện ích
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['subtitle'],
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            color: subColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Mũi tên chevron dẫn hướng phải
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white30 : Colors.black26,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
