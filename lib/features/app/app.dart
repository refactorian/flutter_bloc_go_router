import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../router/app_router.dart';
import '../auth/cubit/auth_cubit.dart';
import '../favorites/cubit/favorites_cubit.dart';
import '../history/cubit/history_cubit.dart';
import '../posts/bloc/posts_bloc.dart';
import '../settings/cubit/settings_cubit.dart';
import '../users/cubit/users_cubit.dart';

/// Root App widget configuring MultiRepositoryProvider, MultiBlocProvider, and GoRouter.
class App extends StatefulWidget {
  final LocalStorageService? localStorageService;
  final AppConfig config;

  const App({
    super.key,
    this.localStorageService,
    this.config = const AppConfig(),
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final LocalStorageService? _storageService;
  late final ApiClient _apiClient;
  late final UserRepository _userRepository;
  late final PostRepository _postRepository;
  late final FavoritesRepository _favoritesRepository;
  late final HistoryRepository _historyRepository;
  late final AuthCubit _authCubit;
  late final SettingsCubit _settingsCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // 1. Initialize Storage & State Cubits first
    _storageService = widget.localStorageService;
    _authCubit = AuthCubit(storageService: _storageService);
    _settingsCubit = SettingsCubit(storageService: _storageService);

    // 2. Initialize API Client with safe token provider
    _apiClient = ApiClient(
      config: widget.config,
      tokenProvider: () => _authCubit.state.token,
    );

    // 3. Initialize Repositories
    _userRepository = UserRepository(apiClient: _apiClient);
    _postRepository = PostRepository(apiClient: _apiClient);
    _favoritesRepository = FavoritesRepository(storageService: _storageService);
    _historyRepository = HistoryRepository(storageService: _storageService);

    // 4. Initialize Router with AuthCubit
    _appRouter = AppRouter(authCubit: _authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    _settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<UserRepository>.value(value: _userRepository),
        RepositoryProvider<PostRepository>.value(value: _postRepository),
        RepositoryProvider<FavoritesRepository>.value(
          value: _favoritesRepository,
        ),
        RepositoryProvider<HistoryRepository>.value(value: _historyRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<SettingsCubit>.value(value: _settingsCubit),
          BlocProvider<FavoritesCubit>(
            create: (context) => FavoritesCubit(
              favoritesRepository: context.read<FavoritesRepository>(),
              postRepository: context.read<PostRepository>(),
            ),
          ),
          BlocProvider<HistoryCubit>(
            create: (context) => HistoryCubit(
              historyRepository: context.read<HistoryRepository>(),
              postRepository: context.read<PostRepository>(),
            ),
          ),
          BlocProvider<UsersCubit>(
            create: (context) =>
                UsersCubit(userRepository: context.read<UserRepository>())
                  ..fetchUsers(),
          ),
          BlocProvider<PostsBloc>(
            create: (context) =>
                PostsBloc(postRepository: context.read<PostRepository>()),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select(
      (SettingsCubit cubit) => cubit.state.themeMode,
    );
    final router = context
        .findAncestorStateOfType<_AppState>()!
        ._appRouter
        .router;

    return MaterialApp.router(
      title: 'Flutter BLoC & GoRouter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
