import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/post.dart';
import '../models/user.dart';

/// Repository responsible for user-related data operations.
class UserRepository {
  final ApiClient apiClient;

  const UserRepository({required this.apiClient});

  /// Fetches the list of all users
  Future<List<User>> getUsers() async {
    final data = await apiClient.get(ApiEndpoints.users);
    if (data is List) {
      return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Fetches a single user by ID
  Future<User> getUserById(int id) async {
    final data = await apiClient.get(ApiEndpoints.user(id));
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Fetches all posts created by a specific user
  Future<List<Post>> getUserPosts(int userId) async {
    final data = await apiClient.get(ApiEndpoints.userPosts(userId));
    if (data is List) {
      return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
