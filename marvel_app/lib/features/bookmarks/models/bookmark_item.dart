import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BookmarkItem {
  final String id;
  final String name;
  final String province;
  final double rating;
  final String category;
  final Color color;
  final IconData icon;

  const BookmarkItem({
    required this.id,
    required this.name,
    required this.province,
    this.rating = 4.5,
    required this.category,
    required this.color,
    required this.icon,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['maDiaDiem']?.toString() ?? '',
      name: json['tenDiaDiem'] ?? 'Không rõ',
      province: json['tinhThanh'] ?? '',
      rating: (json['danhGiaTrungBinh'] ?? 5.0).toDouble(),
      category: 'Điểm đến',
      color: AppColors.primary,
      icon: Icons.place_rounded,
    );
  }
}
