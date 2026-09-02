import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../models/comment.dart';
import '../models/post.dart';

/// Repository responsible for post-related data operations with local in-memory caching.
class PostRepository {
  final ApiClient apiClient;

  // Local cache for created mock posts (ID >= 101) so they can be viewed & saved without 404 errors
  final Map<int, Post> _localCreatedPosts = {};

  PostRepository({required this.apiClient});

  /// Fetches posts, optionally filtered by [userId]
  Future<List<Post>> getPosts({int? userId}) async {
    final queryParams = userId != null ? {'userId': userId} : null;
    final data = await apiClient.get(
      ApiEndpoints.posts,
      queryParameters: queryParams,
    );

    List<Post> posts = [];
    if (data is List) {
      posts = data
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Merge in locally created posts
    final localPosts = _localCreatedPosts.values.where((p) {
      return userId == null || p.userId == userId;
    }).toList();

    return [...localPosts, ...posts];
  }

  /// Fetches paginated posts using JSONPlaceholder `_page` and `_limit` parameters
  Future<List<Post>> getPaginatedPosts({
    int page = 1,
    int limit = 10,
    int? userId,
  }) async {
    final queryParams = <String, dynamic>{'_page': page, '_limit': limit};
    if (userId != null) {
      queryParams['userId'] = userId;
    }

    final data = await apiClient.get(
      ApiEndpoints.posts,
      queryParameters: queryParams,
    );

    List<Post> posts = [];
    if (data is List) {
      posts = data
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Prepend local created posts on page 1
    if (page == 1) {
      final localPosts = _localCreatedPosts.values.where((p) {
        return userId == null || p.userId == userId;
      }).toList();
      posts = [...localPosts, ...posts];
    }

    return posts;
  }

  /// Fetches a single post by ID (checks local cache first for created posts)
  Future<Post> getPostById(int id) async {
    if (_localCreatedPosts.containsKey(id)) {
      return _localCreatedPosts[id]!;
    }

    try {
      final data = await apiClient.get(ApiEndpoints.post(id));
      return Post.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404 && _localCreatedPosts.containsKey(id)) {
        return _localCreatedPosts[id]!;
      }
      rethrow;
    }
  }

  /// Fetches comments for a specific post
  Future<List<Comment>> getPostComments(int postId) async {
    if (_localCreatedPosts.containsKey(postId)) {
      return [
        Comment(
          id: 1,
          postId: postId,
          name: 'Welcome to this post!',
          email: 'system@example.com',
          body: 'This is a newly published post.',
        ),
      ];
    }

    try {
      final data = await apiClient.get(ApiEndpoints.postComments(postId));
      if (data is List) {
        return data
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  /// Creates a new post (mock API endpoint) and stores in local cache
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final data = await apiClient.post(
      ApiEndpoints.posts,
      data: {'title': title, 'body': body, 'userId': userId},
    );

    final post = Post.fromJson(data as Map<String, dynamic>);
    // Store in local created posts cache
    _localCreatedPosts[post.id] = post;
    return post;
  }

  /// Deletes a post (mock API endpoint)
  Future<void> deletePost(int id) async {
    _localCreatedPosts.remove(id);
    try {
      await apiClient.delete(ApiEndpoints.post(id));
    } catch (_) {}
  }
}
