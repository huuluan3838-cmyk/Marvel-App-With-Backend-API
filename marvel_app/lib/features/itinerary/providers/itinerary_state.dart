import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/features/itinerary/models/itinerary.dart';

final String apiUrl = ApiConfig.baseUrl;

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
        fetchItineraries();
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi addItinerary: $e');
    }
    return false;
  }
}
