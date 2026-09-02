import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/favorites/views/favorites_screen.dart';
import '../features/home/views/home_screen.dart';
import '../features/posts/views/create_post_screen.dart';
import '../features/posts/views/post_details_screen.dart';
import '../features/posts/views/posts_screen.dart';
import '../features/settings/views/login_screen.dart';
import '../features/settings/views/settings_screen.dart';
import '../features/users/views/user_details_screen.dart';
import '../features/users/views/users_screen.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Helper to convert a Stream into a Listenable for GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Central GoRouter configuration for the application.
class AppRouter {
  final AuthCubit authCubit;

  AppRouter({required this.authCubit});

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authCubit.state.isAuthenticated;
      final location = state.matchedLocation;
      final isLoggingIn = location == AppRoutes.login;

      // 1. Protected routes that require authentication
      final isProtected = location == AppRoutes.createPost;

      if (!isAuthenticated && isProtected) {
        // Redirect to login with return target
        return '${AppRoutes.login}?from=$location';
      }

      // 2. If user is already authenticated and visits /login, redirect back
      if (isAuthenticated && isLoggingIn) {
        final from = state.uri.queryParameters['from'];
        return from ?? AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Full-screen / Standalone detail routes (on root navigator key)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.favorites,
        name: AppRoutes.favoritesName,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.createPost,
        name: AppRoutes.createPostName,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.userDetails,
        name: AppRoutes.userDetailsName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return UserDetailsScreen(userId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.postDetails,
        name: AppRoutes.postDetailsName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PostDetailsScreen(postId: id);
        },
      ),

      // StatefulShellRoute preserves bottom navigation tab states
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Users
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.users,
                name: AppRoutes.usersName,
                builder: (context, state) => const UsersScreen(),
              ),
            ],
          ),

          // Branch 2: Posts (with query parameter support)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.posts,
                name: AppRoutes.postsName,
                builder: (context, state) {
                  final userIdStr = state.uri.queryParameters['userId'];
                  final userId = userIdStr != null
                      ? int.tryParse(userIdStr)
                      : null;
                  return PostsScreen(initialUserId: userId);
                },
              ),
            ],
          ),

          // Branch 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settingsName,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'No route defined for ${state.uri.toString()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Scaffold wrapper containing the persistent BottomNavigationBar
class ScaffoldWithNestedNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNestedNavigation({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
