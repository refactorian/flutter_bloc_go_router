import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc_go_router/core/api/api_exception.dart';
import 'package:flutter_bloc_go_router/core/api/api_interceptors.dart';
import 'package:flutter_bloc_go_router/core/storage/local_storage_service.dart';
import 'package:flutter_bloc_go_router/core/utils/debouncer.dart';

void main() {
  group('ApiClient & Interceptors Unit Tests', () {
    test('AuthInterceptor attaches Bearer token when token is available', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'sample_jwt_token_123',
      );
      final options = RequestOptions(path: '/test');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(
        options.headers['Authorization'],
        equals('Bearer sample_jwt_token_123'),
      );
    });

    test(
      'AuthInterceptor does not attach header when token is null or empty',
      () {
        final interceptor = AuthInterceptor(tokenProvider: () => null);
        final options = RequestOptions(path: '/test');

        interceptor.onRequest(options, RequestInterceptorHandler());

        expect(options.headers.containsKey('Authorization'), isFalse);
      },
    );

    test(
      'ApiException.fromDioException maps DioExceptionType.badResponse properly',
      () {
        final requestOptions = RequestOptions(path: '/posts/999');
        final dioException = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 404,
            statusMessage: 'Not Found',
          ),
        );

        final apiException = ApiException.fromDioException(dioException);

        expect(apiException.statusCode, equals(404));
        expect(apiException.message, contains('Server error (404)'));
      },
    );

    test('ApiException.fromDioException maps connection timeout properly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.message, contains('Connection timed out'));
    });
  });

  group('LocalStorageService Unit Tests', () {
    late LocalStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = LocalStorageService(prefs);
    });

    test(
      'ThemeMode persistence defaults to system and saves correctly',
      () async {
        expect(storageService.getThemeMode(), equals(ThemeMode.system));

        await storageService.setThemeMode(ThemeMode.dark);
        expect(storageService.getThemeMode(), equals(ThemeMode.dark));

        await storageService.setThemeMode(ThemeMode.light);
        expect(storageService.getThemeMode(), equals(ThemeMode.light));
      },
    );

    test('Auth session saves, retrieves, and clears correctly', () async {
      expect(storageService.getAuthUsername(), isNull);
      expect(storageService.getAuthToken(), isNull);

      await storageService.saveAuthSession(
        username: 'bappy',
        token: 'token_abc_123',
      );
      expect(storageService.getAuthUsername(), equals('bappy'));
      expect(storageService.getAuthToken(), equals('token_abc_123'));

      await storageService.clearAuthSession();
      expect(storageService.getAuthUsername(), isNull);
      expect(storageService.getAuthToken(), isNull);
    });

    test('Favorite post IDs persistence sanitizes and stores list', () async {
      expect(storageService.getFavoritePostIds(), isEmpty);

      await storageService.saveFavoritePostIds([1, 5, 42]);
      final saved = storageService.getFavoritePostIds();

      expect(saved, equals([1, 5, 42]));
    });

    test(
      'Recently viewed items maintains most recent order and max limit',
      () async {
        expect(storageService.getRecentlyViewedPostIds(), isEmpty);

        await storageService.addRecentlyViewedPostId(1);
        await storageService.addRecentlyViewedPostId(2);
        await storageService.addRecentlyViewedPostId(3);
        await storageService.addRecentlyViewedPostId(
          2,
        ); // Re-visiting 2 should push to top

        final recent = storageService.getRecentlyViewedPostIds();
        expect(recent, equals([2, 3, 1]));

        await storageService.clearRecentlyViewedPostIds();
        expect(storageService.getRecentlyViewedPostIds(), isEmpty);
      },
    );
  });

  group('Debouncer Utility Tests', () {
    test('executes action only after duration elapses', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      // Rapidly trigger 3 times
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      // Immediately count should still be 0
      expect(callCount, equals(0));

      // Wait for debounce window
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, equals(1));

      debouncer.dispose();
    });
  });
}
