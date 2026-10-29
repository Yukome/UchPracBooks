import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  AuthResult(this.accessToken, this.refreshToken, this.user);
}

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<AuthResult> login(String username, String password) => guard(() async {
        final response = await _dio.post('/auth/login', data: {
          'username': username,
          'password': password,
        });
        final data = response.data as Map<String, dynamic>;
        return AuthResult(
          data['accessToken'] as String,
          data['refreshToken'] as String,
          AppUser.fromJson(data['user'] as Map<String, dynamic>),
        );
      });

  Future<AuthResult> register(String username, String password, String email, String fullName) => guard(() async {
        final response = await _dio.post('/auth/register', data: {
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
        });
        return await login(username, password);
      });

  Future<AppUser> me() => guard(() async {
        final response = await _dio.get('/auth/me');
        return AppUser.fromJson(response.data as Map<String, dynamic>);
      });

  Future<AuthResult> refresh(String refreshToken) => guard(() async {
        final response = await _dio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
        });
        final data = response.data as Map<String, dynamic>;
        return AuthResult(
          data['accessToken'] as String,
          data['refreshToken'] as String,
          AppUser.fromJson(data['user'] as Map<String, dynamic>),
        );
      });

  Future<void> logout(String refreshToken) => guard(() async {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      });
}