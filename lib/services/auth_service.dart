import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();

  static const _kLoggedInKey = 'logged_in_flag';

  final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  AuthService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_kLoggedInKey) ?? false;
    notifier.value = value;
  }

  bool get isLoggedIn => notifier.value;

  Future<void> login({String? username, String? password}) async {
    // Simple local login: accept any non-empty username/password.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, true);
    notifier.value = true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, false);
    notifier.value = false;
  }
}
