import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kLoginTime = 'auth_login_time';

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  Timer? _sessionTimer;

  static const sessionDuration = Duration(minutes: 60);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    if (access == null) return;

    final loginTimeMs = _prefs.getInt(_kLoginTime);
    if (loginTimeMs != null) {
      final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimeMs);
      if (DateTime.now().difference(loginTime) > sessionDuration) {
        await logout();
        return;
      }
    } else {
      await _prefs.setInt(_kLoginTime, DateTime.now().millisecondsSinceEpoch);
    }
    _accessToken = access;
    _refreshToken = refresh;
    setGlobalToken(access);
    try {
      _user = await _api.me();
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          final res = await _api.refresh(refresh);
          _accessToken = res.accessToken;
          _refreshToken = res.refreshToken;
          _user = res.user;
          setGlobalToken(_accessToken);
          await _saveTokens();
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {}
    _startSessionTimer();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    setGlobalToken(_accessToken);
    await _prefs.setInt(_kLoginTime, DateTime.now().millisecondsSinceEpoch);
    await _saveTokens();
    _startSessionTimer();
    notifyListeners();
  }

  Future<void> logout() async {
    _sessionTimer?.cancel();
    if (_refreshToken != null) {
      try { await _api.logout(_refreshToken!); } catch (_) {}
    }
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    setGlobalToken(null);
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kLoginTime);
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_refreshToken == null) throw Exception('Нет refresh токена');
    
    final res = await _api.refresh(_refreshToken!);
    _accessToken = res.accessToken;
    _refreshToken = res.refreshToken;
    _user = res.user;
    setGlobalToken(_accessToken);
    await _saveTokens();
    notifyListeners();
  }

  Future<void> _saveTokens() async {
    if (_accessToken != null) await _prefs.setString(_kAccess, _accessToken!);
    if (_refreshToken != null) await _prefs.setString(_kRefresh, _refreshToken!);
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    final loginTimeMs = _prefs.getInt(_kLoginTime);
    if (loginTimeMs == null) return;

    final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimeMs);
    final elapsed = DateTime.now().difference(loginTime);
    final remaining = sessionDuration - elapsed;

    if (remaining.isNegative) {
      logout();
      return;
    }

    _sessionTimer = Timer(remaining, () async {
      if (isAuthenticated) {
        print('=== SESSION TIMEOUT: Общая длительность сессии истекла ===');
        await logout();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}