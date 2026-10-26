import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';

String? _authToken;
const int _maxAttempts = 3;
const List<Duration> _retryDelays = [
  Duration(milliseconds: 200),
  Duration(milliseconds: 400),
  Duration(milliseconds: 800),
];

Dio buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  addInterceptors(dio);
  return dio;
}

void addInterceptors(Dio dio) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint('--> ${options.method} ${options.uri}');
        }
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
        }

        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }

        if (!_shouldRetry(error)) {
          return handler.next(error);
        }

        final attempt = (error.requestOptions.extra['_retryAttempt'] as int?) ?? 1;
        if (attempt >= _maxAttempts) {
          if (kDebugMode) {
            debugPrint('[API] исчерпаны попытки (${attempt}/${_maxAttempts}), сдаёмся');
          }
          return handler.next(error);
        }

        final delay = _retryDelays[attempt - 1];
        if (kDebugMode) {
          debugPrint('[API] retry ${attempt}/${_maxAttempts} → ${error.requestOptions.method} ${error.requestOptions.uri} after ${delay.inMilliseconds}ms');
        }
        await Future.delayed(delay);

        final options = error.requestOptions;
        options.extra['_retryAttempt'] = attempt + 1;

        try {
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      },
    ),
  );
}

bool _shouldRetry(DioException error) {
  if (error.requestOptions.method.toUpperCase() != 'GET') return false;
  if (error.type == DioExceptionType.cancel) return false;
  
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return true;
  }
  
  final status = error.response?.statusCode;
  if (status != null && status >= 500) return true;
  
  return false;
}

Future<void> autoLogin(Dio dio) async {
  try {
    final response = await dio.post('/auth/login', data: {
      'username': 'admin',
      'password': 'admin123',
    });

    final data = response.data as Map<String, dynamic>;
    _authToken = data['accessToken'] as String?;

    if (kDebugMode) {
      debugPrint('Авторизация успешна (admin). Токен получен.');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Ошибка авторизации: $e');
    }
  }
}