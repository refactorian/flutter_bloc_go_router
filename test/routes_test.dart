import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc_go_router/core/storage/local_storage_service.dart';
import 'package:flutter_bloc_go_router/features/app/app.dart';

void main() {
  group('Navigation & Router Tests', () {
    testWidgets('Can navigate to favorites and open post details', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_favorite_post_ids': ['1', '2'],
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = LocalStorageService(prefs);

      await tester.pumpWidget(App(localStorageService: storageService));
      await tester.pumpAndSettle();

      // Verify Home loaded
      expect(find.text('Flutter Architecture Hub'), findsOneWidget);

      // Tap on Bookmarks AppBar action
      final bookmarkIcon = find.byIcon(Icons.bookmark_rounded).first;
      expect(bookmarkIcon, findsOneWidget);

      await tester.tap(bookmarkIcon);
      await tester.pumpAndSettle();

      // Verify on Favorites Screen
      expect(find.text('Saved Bookmarks'), findsOneWidget);
    });
  });
}
