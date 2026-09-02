import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_interceptors.dart';

/// Central HTTP Client powered by Dio.
/// Configures base options, interceptors, timeouts, and wraps Dio exceptions.
class ApiClient {
  final Dio _dio;
  final AppConfig config;

  ApiClient({
    Dio? dio,
    this.config = const AppConfig(),
    String? Function()? tokenProvider,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               sendTimeout: config.connectTimeout,
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    if (tokenProvider != null) {
      _dio.interceptors.add(AuthInterceptor(tokenProvider: tokenProvider));
    }
    _dio.interceptors.add(
      SafeLoggingInterceptor(enableLogging: config.enableNetworkLogging),
    );
  }

  /// Generic GET request with automatic error mapping
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generic POST request with automatic error mapping
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generic DELETE request
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
