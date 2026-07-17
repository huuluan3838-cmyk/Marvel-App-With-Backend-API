import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static const int port = 5131;

  /// Local API host mapping:
  /// - Android emulator cannot reach host PC with localhost, use 10.0.2.2.
  /// - Windows/macOS/Linux/Web can use localhost.
  static String get host {
    if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get baseUrl => 'http://$host:$port/api';

  static Uri uri(String path, [Map<String, String>? queryParameters]) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$normalized').replace(
      queryParameters: queryParameters,
    );
  }
}
