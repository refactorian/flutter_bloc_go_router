import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc_go_router/core/storage/local_storage_service.dart';
import 'package:flutter_bloc_go_router/data/models/post.dart';
import 'package:flutter_bloc_go_router/data/models/user.dart';
import 'package:flutter_bloc_go_router/data/repositories/history_repository.dart';
import 'package:flutter_bloc_go_router/data/repositories/post_repository.dart';
import 'package:flutter_bloc_go_router/data/repositories/user_repository.dart';
import 'package:flutter_bloc_go_router/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_bloc_go_router/features/history/cubit/history_cubit.dart';
import 'package:flutter_bloc_go_router/features/posts/bloc/posts_bloc.dart';
import 'package:flutter_bloc_go_router/features/posts/bloc/posts_event.dart';
import 'package:flutter_bloc_go_router/features/posts/bloc/posts_state.dart';
import 'package:flutter_bloc_go_router/features/posts/cubit/create_post_cubit.dart';
import 'package:flutter_bloc_go_router/features/users/cubit/users_cubit.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  group('AuthCubit Tests', () {
    blocTest<AuthCubit, AuthState>(
      'emits authenticated state when login is called',
      build: () => AuthCubit(),
      act: (cubit) => cubit.login('johndoe'),
      expect: () => [
        const AuthState(
          status: AuthStatus.authenticated,
          username: 'johndoe',
          token: 'mock_jwt_token_123',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits unauthenticated state when logout is called',
      build: () => AuthCubit(),
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        username: 'johndoe',
      ),
      act: (cubit) => cubit.logout(),
      expect: () => [
        const AuthState(
          status: AuthStatus.unauthenticated,
          username: null,
          token: null,
        ),
      ],
    );
  });

  group('UsersCubit Tests', () {
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockUserRepository = MockUserRepository();
    });

    final testUsers = [
      const User(
        id: 1,
        name: 'Alice Johnson',
        username: 'alice',
        email: 'alice@example.com',
        address: Address(
          street: '',
          suite: '',
          city: '',
          zipcode: '',
          geo: Geo(lat: '', lng: ''),
        ),
        phone: '',
        website: '',
        company: Company(name: 'Tech Inc', catchPhrase: '', bs: ''),
      ),
    ];

    blocTest<UsersCubit, UsersState>(
      'emits [loading, success] when fetchUsers succeeds',
      build: () {
        when(
          () => mockUserRepository.getUsers(),
        ).thenAnswer((_) async => testUsers);
        return UsersCubit(userRepository: mockUserRepository);
      },
      act: (cubit) => cubit.fetchUsers(),
      expect: () => [
        const UsersState(status: UsersStatus.loading),
        UsersState(
          status: UsersStatus.success,
          users: testUsers,
          filteredUsers: testUsers,
        ),
      ],
    );

    blocTest<UsersCubit, UsersState>(
      'filters users correctly by search query',
      build: () => UsersCubit(userRepository: mockUserRepository),
      seed: () => UsersState(
        status: UsersStatus.success,
        users: testUsers,
        filteredUsers: testUsers,
      ),
      act: (cubit) => cubit.searchUsers('nonexistent'),
      expect: () => [
        UsersState(
          status: UsersStatus.success,
          users: testUsers,
          filteredUsers: const [],
          searchQuery: 'nonexistent',
        ),
      ],
    );
  });

  group('PostsBloc Tests', () {
    late MockPostRepository mockPostRepository;

    setUp(() {
      mockPostRepository = MockPostRepository();
    });

    final testPosts = [
      const Post(
        id: 1,
        userId: 1,
        title: 'Flutter Clean Code',
        body: 'Best practices',
      ),
      const Post(
        id: 2,
        userId: 1,
        title: 'State Management',
        body: 'BLoC and Cubit',
      ),
    ];

    blocTest<PostsBloc, PostsState>(
      'emits [loading, success] on PostsFetchRequested',
      build: () {
        when(
          () => mockPostRepository.getPaginatedPosts(
            page: 1,
            limit: any(named: 'limit'),
            userId: null,
          ),
        ).thenAnswer((_) async => testPosts);
        return PostsBloc(postRepository: mockPostRepository);
      },
      act: (bloc) => bloc.add(const PostsFetchRequested()),
      expect: () => [
        const PostsState(status: PostsStatus.loading),
        PostsState(
          status: PostsStatus.success,
          posts: testPosts,
          filteredPosts: testPosts,
          currentPage: 1,
          hasReachedMax: true,
        ),
      ],
    );
  });

  group('CreatePostCubit Tests', () {
    late MockPostRepository mockPostRepository;

    setUp(() {
      mockPostRepository = MockPostRepository();
    });

    blocTest<CreatePostCubit, CreatePostState>(
      'validates title and body correctly and submits',
      build: () {
        when(
          () => mockPostRepository.createPost(
            title: 'Clean Architecture',
            body: 'A complete Flutter reference guide',
            userId: 1,
          ),
        ).thenAnswer(
          (_) async => const Post(
            id: 101,
            title: 'Clean Architecture',
            body: 'A complete Flutter reference guide',
            userId: 1,
          ),
        );
        return CreatePostCubit(postRepository: mockPostRepository);
      },
      act: (cubit) async {
        cubit.onTitleChanged('Clean Architecture');
        cubit.onBodyChanged('A complete Flutter reference guide');
        await cubit.submit();
      },
      expect: () => [
        const CreatePostState(
          title: 'Clean Architecture',
          titleError: null,
          status: FormSubmissionStatus.initial,
        ),
        const CreatePostState(
          title: 'Clean Architecture',
          body: 'A complete Flutter reference guide',
          titleError: null,
          bodyError: null,
          status: FormSubmissionStatus.initial,
        ),
        const CreatePostState(
          title: 'Clean Architecture',
          body: 'A complete Flutter reference guide',
          titleError: null,
          bodyError: null,
          status: FormSubmissionStatus.submitting,
        ),
        const CreatePostState(
          title: 'Clean Architecture',
          body: 'A complete Flutter reference guide',
          titleError: null,
          bodyError: null,
          status: FormSubmissionStatus.success,
          createdPost: Post(
            id: 101,
            title: 'Clean Architecture',
            body: 'A complete Flutter reference guide',
            userId: 1,
          ),
        ),
      ],
    );
  });

  group('HistoryCubit Tests', () {
    late MockPostRepository mockPostRepository;

    setUp(() {
      mockPostRepository = MockPostRepository();
    });

    test('records viewed post properly', () async {
      SharedPreferences.setMockInitialValues({
        'app_recently_viewed_post_ids': ['1'],
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final historyRepo = HistoryRepository(storageService: storage);

      when(() => mockPostRepository.getPostById(1)).thenAnswer(
        (_) async => const Post(
          id: 1,
          userId: 1,
          title: 'Flutter Title',
          body: 'Flutter Body',
        ),
      );

      final cubit = HistoryCubit(
        historyRepository: historyRepo,
        postRepository: mockPostRepository,
      );

      expect(cubit.state.recentPostIds, contains(1));
    });
  });
}
