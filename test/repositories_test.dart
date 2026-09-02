import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc_go_router/core/api/api_client.dart';
import 'package:flutter_bloc_go_router/data/repositories/post_repository.dart';
import 'package:flutter_bloc_go_router/data/repositories/user_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late UserRepository userRepository;
  late PostRepository postRepository;

  setUp(() {
    mockApiClient = MockApiClient();
    userRepository = UserRepository(apiClient: mockApiClient);
    postRepository = PostRepository(apiClient: mockApiClient);
  });

  group('UserRepository Tests', () {
    test('getUsers returns list of users on success', () async {
      when(() => mockApiClient.get('/users')).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'name': 'Test User',
            'username': 'test',
            'email': 'test@example.com',
          },
        ],
      );

      final users = await userRepository.getUsers();
      expect(users.length, 1);
      expect(users.first.name, 'Test User');
      verify(() => mockApiClient.get('/users')).called(1);
    });

    test('getUserById returns a user', () async {
      when(() => mockApiClient.get('/users/1')).thenAnswer(
        (_) async => {
          'id': 1,
          'name': 'User One',
          'username': 'u1',
          'email': 'u1@example.com',
        },
      );

      final user = await userRepository.getUserById(1);
      expect(user.id, 1);
      expect(user.name, 'User One');
    });
  });

  group('PostRepository Tests', () {
    test('getPaginatedPosts passes _page and _limit query params', () async {
      when(
        () => mockApiClient.get(
          '/posts',
          queryParameters: {'_page': 1, '_limit': 10},
        ),
      ).thenAnswer(
        (_) async => [
          {'userId': 1, 'id': 1, 'title': 'Test Post', 'body': 'Test content'},
        ],
      );

      final posts = await postRepository.getPaginatedPosts(page: 1, limit: 10);
      expect(posts.length, 1);
      expect(posts.first.title, 'Test Post');
    });

    test('createPost posts payload and returns created model', () async {
      when(
        () => mockApiClient.post(
          '/posts',
          data: {'title': 'New Post', 'body': 'New body', 'userId': 1},
        ),
      ).thenAnswer(
        (_) async => {
          'id': 101,
          'title': 'New Post',
          'body': 'New body',
          'userId': 1,
        },
      );

      final created = await postRepository.createPost(
        title: 'New Post',
        body: 'New body',
        userId: 1,
      );

      expect(created.id, 101);
      expect(created.title, 'New Post');
    });
  });
}
