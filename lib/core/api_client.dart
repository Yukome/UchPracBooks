import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';

String? _globalAccessToken;
void setGlobalToken(String? token) => _globalAccessToken = token;
Future<String?> Function()? onTokenRefresh;
VoidCallback? onAuthFailed;

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
        if (kDebugMode) debugPrint('--> ${options.method} ${options.uri}');
        if (_globalAccessToken != null) {
          options.headers['Authorization'] = 'Bearer $_globalAccessToken';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        final status = response.statusCode ?? 0;
        if (kDebugMode) debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
        final path = response.requestOptions.path;
        if (status == 401 && !path.contains('/auth/login') && !path.contains('/auth/refresh')) {
          if (kDebugMode) debugPrint('[API] 401 Unauthorized. Пытаемся обновить токен...');
          
          if (onTokenRefresh != null) {
            final newToken = await onTokenRefresh!();
            
            if (newToken != null) {
              if (kDebugMode) debugPrint('[API] Токен обновлен! Повторяем запрос...');
              final options = response.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              
              try {
                final retryResponse = await dio.fetch(options);
                return handler.resolve(retryResponse);
              } on DioException catch (e) {
                return handler.reject(e);
              }
            } else {
              if (kDebugMode) debugPrint('[API] Не удалось обновить токен. Выходим.');
              if (onAuthFailed != null) onAuthFailed!();
            }
          }
        }

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
        if (kDebugMode) debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');

        if (!_shouldRetry(error)) return handler.next(error);

        final attempt = (error.requestOptions.extra['_retryAttempt'] as int?) ?? 1;
        if (attempt >= _maxAttempts) return handler.next(error);

        final delay = _retryDelays[attempt - 1];
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
      error.type == DioExceptionType.connectionError) return true;
  final status = error.response?.statusCode;
  if (status != null && status >= 500) return true;
  return false;
}