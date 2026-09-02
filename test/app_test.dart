import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc_go_router/core/storage/local_storage_service.dart';
import 'package:flutter_bloc_go_router/data/models/comment.dart';
import 'package:flutter_bloc_go_router/data/models/post.dart';
import 'package:flutter_bloc_go_router/data/models/user.dart';
import 'package:flutter_bloc_go_router/features/app/app.dart';

void main() {
  group('Models Unit Tests', () {
    test('User fromJson decodes correctly', () {
      final json = {
        'id': 1,
        'name': 'Leanne Graham',
        'username': 'Bret',
        'email': 'Sincere@april.biz',
        'address': {
          'street': 'Kulas Light',
          'suite': 'Apt. 556',
          'city': 'Gwenborough',
          'zipcode': '92998-3874',
          'geo': {'lat': '-37.3159', 'lng': '81.1496'},
        },
        'phone': '1-770-736-8031 x56442',
        'website': 'hildegard.org',
        'company': {
          'name': 'Romaguera-Crona',
          'catchPhrase': 'Multi-layered client-server neural-net',
          'bs': 'harness real-time e-markets',
        },
      };

      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
      expect(user.initials, 'LG');
      expect(user.company.name, 'Romaguera-Crona');
    });

    test('Post fromJson decodes correctly', () {
      final json = {
        'userId': 1,
        'id': 1,
        'title': 'sunt aut facere repellat provident',
        'body': 'quia et suscipit suscipit recusandae consequuntur',
      };

      final post = Post.fromJson(json);
      expect(post.id, 1);
      expect(post.userId, 1);
      expect(post.title, 'sunt aut facere repellat provident');
    });

    test('Comment fromJson decodes correctly', () {
      final json = {
        'postId': 1,
        'id': 1,
        'name': 'id labore ex et quam laborum',
        'email': 'Eliseo@gardner.biz',
        'body': 'laudantium enim quasi est quidem magnam voluptate',
      };

      final comment = Comment.fromJson(json);
      expect(comment.id, 1);
      expect(comment.postId, 1);
      expect(comment.email, 'Eliseo@gardner.biz');
    });
  });

  group('App Widget Test', () {
    testWidgets('App renders Home dashboard and navigates properly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = LocalStorageService(prefs);

      await tester.pumpWidget(App(localStorageService: storageService));
      await tester.pumpAndSettle();

      expect(find.text('Flutter Architecture Hub'), findsOneWidget);
      expect(find.text('Explore Features'), findsOneWidget);
      expect(find.text('Users Directory'), findsOneWidget);
      expect(find.text('Posts Feed'), findsOneWidget);
    });
  });
}
