/// Constant endpoint paths for the JSONPlaceholder API.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // Endpoints
  static const String users = '/users';
  static String user(int id) => '/users/$id';
  static String userPosts(int id) => '/users/$id/posts';

  static const String posts = '/posts';
  static String post(int id) => '/posts/$id';
  static String postComments(int id) => '/posts/$id/comments';
}
