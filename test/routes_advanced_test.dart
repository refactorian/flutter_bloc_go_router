import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc_go_router/core/storage/local_storage_service.dart';
import 'package:flutter_bloc_go_router/features/app/app.dart';

void main() {
  group('Advanced GoRouter & Navigation Tests', () {
    testWidgets(
      'Unauthenticated user navigating to /create-post is guarded and redirected to /login',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storageService = LocalStorageService(prefs);

        await tester.pumpWidget(App(localStorageService: storageService));
        await tester.pumpAndSettle();

        // Find and tap Create Post feature card on Home
        final createPostCard = find.text('Create Post').first;
        await tester.ensureVisible(createPostCard);
        expect(createPostCard, findsOneWidget);

        await tester.tap(createPostCard);
        await tester.pumpAndSettle();

        // Because user is unauthenticated, Route Guard redirects to Sign In screen
        expect(find.text('Sign In'), findsWidgets);
        expect(find.text('Welcome Back'), findsOneWidget);

        // Log in
        final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
        expect(signInButton, findsOneWidget);

        await tester.tap(signInButton);
        // Pump delayed login simulation
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // After login, router should complete redirect to Create New Post screen!
        expect(find.text('Create New Post'), findsOneWidget);
      },
    );

    testWidgets('Switching bottom navigation bar tabs preserves shell state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = LocalStorageService(prefs);

      await tester.pumpWidget(App(localStorageService: storageService));
      await tester.pumpAndSettle();

      // 1. Initial tab: Home
      expect(find.text('Flutter Architecture Hub'), findsOneWidget);

      // 2. Switch to Users tab
      final usersNav = find.byIcon(Icons.people_outline);
      await tester.tap(usersNav);
      await tester.pumpAndSettle();
      expect(find.text('Users Directory'), findsOneWidget);

      // 3. Switch to Posts tab
      final postsNav = find.byIcon(Icons.article_outlined);
      await tester.tap(postsNav);
      await tester.pumpAndSettle();
      expect(find.text('Posts Feed'), findsOneWidget);

      // 4. Switch to Settings tab
      final settingsNav = find.byIcon(Icons.settings_outlined);
      await tester.tap(settingsNav);
      await tester.pumpAndSettle();
      expect(find.text('Settings & Configuration'), findsOneWidget);

      // 5. Switch back to Home tab
      final homeNav = find.byIcon(Icons.home_outlined);
      await tester.tap(homeNav);
      await tester.pumpAndSettle();
      expect(find.text('Flutter Architecture Hub'), findsOneWidget);
    });
  });
}
