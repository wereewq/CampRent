import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'camp_access_token';
  static const _kRefresh = 'camp_refresh_token';
  static const _kUser = 'camp_user_data';

  final SharedPreferences _prefs;
  final Dio _dio;

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;

  AuthNotifier(this._prefs, this._dio);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  Role get role => _user?.role ?? Role.reader;

  bool has(Role targetRole) =>
      _user != null && _user!.role.level >= targetRole.level;

  Future<void> restore() async {
    _accessToken = _prefs.getString(_kAccess);
    _refreshToken = _prefs.getString(_kRefresh);
    final rawUser = _prefs.getString(_kUser);

    if (_accessToken == null) return;
    if (rawUser != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {}
    }

    try {
      final res = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );
      _user = AppUser.fromJson(res.data as Map<String, dynamic>);
      await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final res = await guard(
      () => _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      ),
    );
    final data = res.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    _refreshToken = data['refreshToken'] as String;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, _refreshToken!);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> register(
    String username,
    String password,
    String fullName,
    Role role,
  ) async {
    final res = await guard(
      () => _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
          'role': role.name,
        },
      ),
    );
    final data = res.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    _refreshToken = data['refreshToken'] as String;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, _refreshToken!);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_refreshToken == null) throw const UnauthorizedException();
    final res = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': _refreshToken},
    );
    final data = res.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    await _prefs.setString(_kAccess, _accessToken!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    notifyListeners();
  }
}
