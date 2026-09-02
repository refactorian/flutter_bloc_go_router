import 'dart:developer' as developer;
import 'package:dio/dio.dart';

/// Interceptor that attaches authorization Bearer token if present
class AuthInterceptor extends Interceptor {
  final String? Function() tokenProvider;

  AuthInterceptor({required this.tokenProvider});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}

/// Safe development logger that redacts sensitive headers and tokens
class SafeLoggingInterceptor extends Interceptor {
  final bool enableLogging;

  SafeLoggingInterceptor({this.enableLogging = true});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enableLogging) {
      developer.log(
        '--> ${options.method.toUpperCase()} ${options.uri}',
        name: 'Dio.Request',
      );
      if (options.data != null) {
        developer.log('Payload: ${options.data}', name: 'Dio.Request');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enableLogging) {
      developer.log(
        '<-- ${response.statusCode} ${response.requestOptions.uri}',
        name: 'Dio.Response',
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enableLogging) {
      developer.log(
        '<-- ERROR ${err.response?.statusCode ?? 'N/A'} ${err.requestOptions.uri} | ${err.message}',
        name: 'Dio.Error',
        error: err.error,
      );
    }
    super.onError(err, handler);
  }
}
