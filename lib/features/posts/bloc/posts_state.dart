import 'package:equatable/equatable.dart';
import '../../../data/models/post.dart';

enum PostsStatus { initial, loading, success, failure }

class PostsState extends Equatable {
  final PostsStatus status;
  final List<Post> posts;
  final List<Post> filteredPosts;
  final int? activeFilterUserId;
  final String searchQuery;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? errorMessage;
  final String? paginationErrorMessage;

  const PostsState({
    this.status = PostsStatus.initial,
    this.posts = const [],
    this.filteredPosts = const [],
    this.activeFilterUserId,
    this.searchQuery = '',
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.paginationErrorMessage,
  });

  PostsState copyWith({
    PostsStatus? status,
    List<Post>? posts,
    List<Post>? filteredPosts,
    int? Function()? activeFilterUserId,
    String? searchQuery,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? errorMessage,
    String? paginationErrorMessage,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      filteredPosts: filteredPosts ?? this.filteredPosts,
      activeFilterUserId: activeFilterUserId != null
          ? activeFilterUserId()
          : this.activeFilterUserId,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage ?? this.errorMessage,
      paginationErrorMessage:
          paginationErrorMessage ?? this.paginationErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    posts,
    filteredPosts,
    activeFilterUserId,
    searchQuery,
    currentPage,
    hasReachedMax,
    isLoadingMore,
    isRefreshing,
    errorMessage,
    paginationErrorMessage,
  ];
}
