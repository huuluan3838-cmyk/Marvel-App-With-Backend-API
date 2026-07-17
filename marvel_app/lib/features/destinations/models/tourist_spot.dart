import 'package:latlong2/latlong.dart';

import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/destinations/models/sub_destination.dart';

double parseSpotDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

String normalizeImagePath(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  if (raw.toLowerCase().startsWith('http://') || raw.toLowerCase().startsWith('https://')) return raw;
  
  // Xử lý đường dẫn bắt đầu bằng assets hoặc /assets
  final cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
  if (cleanPath.toLowerCase().startsWith('assets/')) {
    return cleanPath;
  }
  
  final relative = raw.startsWith('/') ? raw.substring(1) : raw;
  return '${ApiConfig.baseUrl.replaceFirst('/api', '')}/$relative';
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
        parseSpotDouble(json['viDo']),
        parseSpotDouble(json['kinhDo']),
      ),
      imageUrl: normalizeImagePath(json['hinhAnh']),
      subDestinations: chiTietsList
          .map((e) => SubDestination(
                id: e['maChiTiet']?.toString() ?? '',
                name: e['tenChiTiet']?.toString() ?? 'Chưa rõ tên',
                imageUrl: normalizeImagePath(e['hinhAnh']),
              ))
          .toList(),
    );
  }
}
