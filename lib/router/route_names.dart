/// Named constants for route paths and route names.
class AppRoutes {
  AppRoutes._();

  // Root / Tabs
  static const String home = '/';
  static const String homeName = 'home';

  static const String users = '/users';
  static const String usersName = 'users';

  static const String userDetails = '/users/:id';
  static const String userDetailsName = 'userDetails';
  static String userDetailsPath(int id) => '/users/$id';

  static const String posts = '/posts';
  static const String postsName = 'posts';
  static String postsWithQuery({int? userId}) =>
      userId != null ? '/posts?userId=$userId' : '/posts';

  static const String postDetails = '/posts/:id';
  static const String postDetailsName = 'postDetails';
  static String postDetailsPath(int id) => '/posts/$id';

  static const String favorites = '/favorites';
  static const String favoritesName = 'favorites';

  static const String createPost = '/create-post';
  static const String createPostName = 'createPost';

  static const String settings = '/settings';
  static const String settingsName = 'settings';

  static const String login = '/login';
  static const String loginName = 'login';
}
