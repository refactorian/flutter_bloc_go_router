import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_go_router/data/models/comment.dart';
import 'package:flutter_bloc_go_router/data/models/post.dart';
import 'package:flutter_bloc_go_router/data/models/user.dart';

void main() {
  group('Data Models Unit Tests', () {
    test('User.fromJson creates valid model and handles missing fields', () {
      final json = {
        'id': 10,
        'name': 'Clementina DuBuque',
        'username': 'Moriah.Stanton',
        'email': 'Rey.Padberg@karina.biz',
        'address': {
          'street': 'Kattie Turnpike',
          'suite': 'Suite 198',
          'city': 'Lebsackbury',
          'zipcode': '31428-2261',
          'geo': {'lat': '-38.2386', 'lng': '57.2232'},
        },
        'phone': '024-648-3804',
        'website': 'ambrose.net',
        'company': {
          'name': 'Hoeger LLC',
          'catchPhrase': 'Centralized empowering task-force',
          'bs': 'target end-to-end models',
        },
      };

      final user = User.fromJson(json);
      expect(user.id, 10);
      expect(user.name, 'Clementina DuBuque');
      expect(user.initials, 'CD');
      expect(user.address.city, 'Lebsackbury');
      expect(user.address.geo.lat, '-38.2386');
      expect(user.company.name, 'Hoeger LLC');

      final serialized = user.toJson();
      expect(serialized['id'], 10);
      expect(serialized['email'], 'Rey.Padberg@karina.biz');
    });

    test('Post.fromJson decodes correctly', () {
      final json = {
        'userId': 2,
        'id': 15,
        'title': 'eveniet quod temporibus',
        'body': 'reprehenderit quos placeat',
      };

      final post = Post.fromJson(json);
      expect(post.id, 15);
      expect(post.userId, 2);
      expect(post.title, 'eveniet quod temporibus');
      expect(post.body, 'reprehenderit quos placeat');

      final map = post.toJson();
      expect(map['title'], 'eveniet quod temporibus');
    });

    test('Comment.fromJson decodes correctly', () {
      final json = {
        'postId': 15,
        'id': 71,
        'name': 'vel voluptatem',
        'email': 'Hayden@althea.biz',
        'body': 'ipsam mollitia architecto',
      };

      final comment = Comment.fromJson(json);
      expect(comment.id, 71);
      expect(comment.postId, 15);
      expect(comment.name, 'vel voluptatem');
      expect(comment.email, 'Hayden@althea.biz');
    });
  });
}
