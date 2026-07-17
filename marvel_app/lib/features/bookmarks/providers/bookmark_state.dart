import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/features/bookmarks/models/bookmark_item.dart';

final String apiUrl = ApiConfig.baseUrl;

class BookmarkState extends ChangeNotifier {
  static final BookmarkState _instance = BookmarkState._internal();
  factory BookmarkState() => _instance;
  BookmarkState._internal();

  List<BookmarkItem> _items = [];
  bool isLoading = false;

  List<BookmarkItem> get items => _items;

  Future<void> fetchBookmarks() async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return;

    final int userId = AuthState().userId ?? 2;

    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/Bookmark/user/$userId'),
        headers: {'Authorization': 'Bearer ${AuthState().token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _items = data.map((json) => BookmarkItem.fromJson(json)).toList();
      } else {
        debugPrint('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi fetchBookmarks: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String diaDiemId, BookmarkItem item) async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return;

    final int userId = AuthState().userId ?? 2;
    int dId = int.tryParse(diaDiemId) ?? 0;

    if (isBookmarked(diaDiemId)) {
      _items.removeWhere((i) => i.id == diaDiemId);
    } else {
      _items.add(item);
    }
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/Bookmark'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState().token}'
        },
        body: jsonEncode({
          'maNguoiDung': userId,
          'maDiaDiem': dId,
        }),
      );

      if (response.statusCode != 200) {
        fetchBookmarks();
      }
    } catch (e) {
      debugPrint('Lỗi toggleBookmark: $e');
      fetchBookmarks();
    }
  }

  void removeBookmark(String id) {
    toggleBookmark(
        id,
        BookmarkItem(
            id: id,
            name: '',
            province: '',
            category: '',
            color: Colors.transparent,
            icon: Icons.error));
  }

  bool isBookmarked(String id) {
    return _items.any((item) => item.id == id);
  }
}
