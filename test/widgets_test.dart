import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_go_router/core/widgets/app_empty_state.dart';
import 'package:flutter_bloc_go_router/core/widgets/app_error_state.dart';
import 'package:flutter_bloc_go_router/core/widgets/app_loading_indicator.dart';
import 'package:flutter_bloc_go_router/core/widgets/app_shimmer_skeleton.dart';

void main() {
  group('Core Reusable Widgets Tests', () {
    testWidgets('AppEmptyState displays title, message, and action button', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              title: 'No Data Found',
              message: 'Try refreshing or changing filters.',
              actionLabel: 'Refresh',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('Try refreshing or changing filters.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState displays error message and retry button', (
      tester,
    ) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              message: 'Failed to reach server.',
              statusCode: 500,
              onRetry: () => retryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to reach server.'), findsOneWidget);
      expect(find.text('Status Code: 500'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);
    });

    testWidgets('AppLoadingIndicator displays message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(message: 'Loading posts...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading posts...'), findsOneWidget);
    });

    testWidgets('AppShimmerSkeleton renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppShimmerSkeleton(height: 20, width: 100)),
        ),
      );

      expect(find.byType(AppShimmerSkeleton), findsOneWidget);
    });
  });
}
