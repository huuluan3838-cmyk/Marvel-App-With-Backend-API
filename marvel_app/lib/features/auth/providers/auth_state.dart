import 'package:flutter/material.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';
import 'package:marvel_travel/core/services/fcm_service.dart';

class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  bool isLoggedIn = false;
  String username = 'Nhà Khám Phá';
  String email = 'explorer@marveltravel.vn';
  String role = 'User';
  int? userId;
  String? token;
  String? avatarUrl;

  void login(String inputName, String inputEmail, String inputRole,
      {int? inputUserId, String? inputToken, String? inputAvatarUrl}) {
    isLoggedIn = true;
    username = inputName.isEmpty ? 'Nhà Khám Phá' : inputName;
    email = inputEmail;
    role = inputRole;
    userId = inputUserId;
    token = inputToken;
    avatarUrl = inputAvatarUrl;
    notifyListeners();
  }

  void updateProfileState(
      {String? inputName, String? inputEmail, String? inputAvatarUrl}) {
    if (inputName != null && inputName.isNotEmpty) username = inputName;
    if (inputEmail != null && inputEmail.isNotEmpty) email = inputEmail;
    if (inputAvatarUrl != null) avatarUrl = inputAvatarUrl;
    notifyListeners();
  }

  Future<void> logout() async {
    await FcmService.unregisterCurrentDeviceToken();

    isLoggedIn = false;
    role = 'User';
    userId = null;
    token = null;
    avatarUrl = null;
    notifyListeners();
  }
}
