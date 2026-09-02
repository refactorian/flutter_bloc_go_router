import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc_go_router/data/models/comment.dart';
import 'package:flutter_bloc_go_router/data/models/post.dart';
import 'package:flutter_bloc_go_router/data/models/user.dart';
import 'package:flutter_bloc_go_router/data/repositories/favorites_repository.dart';
import 'package:flutter_bloc_go_router/data/repositories/history_repository.dart';
import 'package:flutter_bloc_go_router/data/repositories/post_repository.dart';
import 'package:flutter_bloc_go_router/data/repositories/user_repository.dart';
import 'package:flutter_bloc_go_router/features/favorites/cubit/favorites_cubit.dart';
import 'package:flutter_bloc_go_router/features/history/cubit/history_cubit.dart';
import 'package:flutter_bloc_go_router/features/posts/bloc/posts_bloc.dart';
import 'package:flutter_bloc_go_router/features/posts/views/create_post_screen.dart';
import 'package:flutter_bloc_go_router/features/posts/views/post_details_screen.dart';
import 'package:flutter_bloc_go_router/features/users/views/user_details_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockPostRepository mockPostRepository;
  late MockUserRepository mockUserRepository;
  late MockFavoritesRepository mockFavoritesRepository;
  late MockHistoryRepository mockHistoryRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    mockUserRepository = MockUserRepository();
    mockFavoritesRepository = MockFavoritesRepository();
    mockHistoryRepository = MockHistoryRepository();

    when(() => mockFavoritesRepository.getFavoritePostIds()).thenReturn([]);
    when(() => mockHistoryRepository.getRecentlyViewedPostIds()).thenReturn([]);
  });

  Widget createTestableWidget(Widget child) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PostRepository>.value(value: mockPostRepository),
        RepositoryProvider<UserRepository>.value(value: mockUserRepository),
        RepositoryProvider<FavoritesRepository>.value(
          value: mockFavoritesRepository,
        ),
        RepositoryProvider<HistoryRepository>.value(
          value: mockHistoryRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<FavoritesCubit>(
            create: (context) => FavoritesCubit(
              favoritesRepository: mockFavoritesRepository,
              postRepository: mockPostRepository,
            ),
          ),
          BlocProvider<HistoryCubit>(
            create: (context) => HistoryCubit(
              historyRepository: mockHistoryRepository,
              postRepository: mockPostRepository,
            ),
          ),
          BlocProvider<PostsBloc>(
            create: (context) => PostsBloc(postRepository: mockPostRepository),
          ),
        ],
        child: MaterialApp(home: child),
      ),
    );
  }

  group('CreatePostScreen Widget & Form Validation Tests', () {
    testWidgets('shows validation errors when title and body are too short', (
      tester,
    ) async {
      // Set test surface size so all elements are accessible
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestableWidget(const CreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create New Post'), findsOneWidget);
      final publishButton = find.widgetWithText(ElevatedButton, 'Publish Post');
      expect(publishButton, findsOneWidget);

      // Tap Publish with empty fields
      await tester.ensureVisible(publishButton);
      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Content is required'), findsOneWidget);

      // Enter short title
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'abc');
      await tester.pumpAndSettle();
      expect(find.text('Title must be at least 5 characters'), findsOneWidget);

      // Enter valid title
      await tester.enterText(textFields.first, 'Valid Post Title');
      await tester.pumpAndSettle();
      expect(find.text('Title must be at least 5 characters'), findsNothing);
    });

    testWidgets('successfully submits when form is valid', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      when(
        () => mockPostRepository.createPost(
          title: 'Mastering Flutter BLoC',
          body:
              'A comprehensive guide to state management and testing in Flutter.',
          userId: 1,
        ),
      ).thenAnswer(
        (_) async => const Post(
          id: 101,
          userId: 1,
          title: 'Mastering Flutter BLoC',
          body:
              'A comprehensive guide to state management and testing in Flutter.',
        ),
      );

      await tester.pumpWidget(createTestableWidget(const CreatePostScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'Mastering Flutter BLoC');
      await tester.enterText(
        textFields.last,
        'A comprehensive guide to state management and testing in Flutter.',
      );
      await tester.pumpAndSettle();

      final publishButton = find.widgetWithText(ElevatedButton, 'Publish Post');
      await tester.ensureVisible(publishButton);
      await tester.tap(publishButton);
      await tester.pump(); // Pump async submission

      verify(
        () => mockPostRepository.createPost(
          title: 'Mastering Flutter BLoC',
          body:
              'A comprehensive guide to state management and testing in Flutter.',
          userId: 1,
        ),
      ).called(1);
    });
  });

  group('PostDetailsScreen Widget & Action Tests', () {
    const testPost = Post(
      id: 42,
      userId: 1,
      title: 'Testing in Flutter',
      body: 'Unit, Widget, and Integration tests ensure code reliability.',
    );
    const testComments = [
      Comment(
        id: 1,
        postId: 42,
        name: 'Jane Reviewer',
        email: 'jane@example.com',
        body: 'Great article on testing!',
      ),
    ];

    setUp(() {
      when(
        () => mockPostRepository.getPostById(42),
      ).thenAnswer((_) async => testPost);
      when(
        () => mockPostRepository.getPostComments(42),
      ).thenAnswer((_) async => testComments);
      when(
        () => mockHistoryRepository.recordRecentlyViewed(42),
      ).thenAnswer((_) async {});
    });

    testWidgets('renders post content and comments properly', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const PostDetailsScreen(postId: 42)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Post #42 Details'), findsOneWidget);
      expect(find.text('Testing in Flutter'), findsOneWidget);
      expect(
        find.text(
          'Unit, Widget, and Integration tests ensure code reliability.',
        ),
        findsOneWidget,
      );
      expect(find.text('Comments (1)'), findsOneWidget);
      expect(find.text('Jane Reviewer'), findsOneWidget);
      expect(find.text('Great article on testing!'), findsOneWidget);
    });

    testWidgets('displays confirm dialog when delete button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const PostDetailsScreen(postId: 42)),
      );
      await tester.pumpAndSettle();

      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Dialog should open
      expect(find.text('Delete Post'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete post #42? This action cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('UserDetailsScreen Widget Tests', () {
    const testUser = User(
      id: 1,
      name: 'Leanne Graham',
      username: 'Bret',
      email: 'Sincere@april.biz',
      address: Address(
        street: 'Kulas Light',
        suite: 'Apt. 556',
        city: 'Gwenborough',
        zipcode: '92998-3874',
        geo: Geo(lat: '-37.3159', lng: '81.1496'),
      ),
      phone: '1-770-736-8031',
      website: 'hildegard.org',
      company: Company(
        name: 'Romaguera-Crona',
        catchPhrase: 'Multi-layered client-server neural-net',
        bs: 'harness real-time e-markets',
      ),
    );

    setUp(() {
      when(
        () => mockUserRepository.getUserById(1),
      ).thenAnswer((_) async => testUser);
      when(
        () => mockUserRepository.getUserPosts(1),
      ).thenAnswer((_) async => []);
    });

    testWidgets(
      'renders user profile details and copyable contact information',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(const UserDetailsScreen(userId: 1)),
        );
        await tester.pumpAndSettle();

        expect(find.text('User #1 Profile'), findsOneWidget);
        expect(find.text('Leanne Graham'), findsOneWidget);
        expect(find.text('@Bret'), findsOneWidget);
        expect(find.text('Sincere@april.biz'), findsOneWidget);
        expect(find.text('1-770-736-8031'), findsOneWidget);
        expect(find.text('Romaguera-Crona'), findsOneWidget);
        expect(find.text('Authored Posts (0)'), findsOneWidget);
      },
    );
  });
}
