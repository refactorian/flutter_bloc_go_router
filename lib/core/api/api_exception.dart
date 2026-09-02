import 'package:dio/dio.dart';

/// Custom typed exception for network and API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your internet.',
        );
      case DioExceptionType.sendTimeout:
        return const ApiException(message: 'Send timed out. Try again later.');
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Receive timed out. Server took too long to respond.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(message: 'Bad SSL certificate.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final statusMessage = error.response?.statusMessage;
        return ApiException(
          message:
              'Server error ($statusCode): ${statusMessage ?? "Request failed"}',
          statusCode: statusCode,
          data: error.response?.data,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection or server unreachable.',
        );
      case DioExceptionType.transformTimeout:
        return const ApiException(message: 'Data transformation timed out.');
      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
