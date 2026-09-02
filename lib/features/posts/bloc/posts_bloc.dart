import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_exception.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/post_repository.dart';
import 'posts_event.dart';
import 'posts_state.dart';

/// Event-driven BLoC managing Posts feed, pagination, filtering, search, and refresh.
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  static const int _pageSize = 10;
  final PostRepository postRepository;

  PostsBloc({required this.postRepository}) : super(const PostsState()) {
    on<PostsFetchRequested>(_onPostsFetchRequested);
    on<PostsNextPageRequested>(_onPostsNextPageRequested);
    on<PostsSearchChanged>(_onPostsSearchChanged);
    on<PostsFilterByUserRequested>(_onPostsFilterByUserRequested);
    on<PostsRefreshRequested>(_onPostsRefreshRequested);
    on<PostAddedOptimistically>(_onPostAddedOptimistically);
  }

  Future<void> _onPostsFetchRequested(
    PostsFetchRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PostsStatus.loading,
        activeFilterUserId: () => event.userId,
        currentPage: 1,
        hasReachedMax: false,
        errorMessage: null,
        paginationErrorMessage: null,
      ),
    );

    try {
      final posts = await postRepository.getPaginatedPosts(
        page: 1,
        limit: _pageSize,
        userId: event.userId,
      );

      final filtered = _applyFilter(posts, state.searchQuery);

      emit(
        state.copyWith(
          status: PostsStatus.success,
          posts: posts,
          filteredPosts: filtered,
          currentPage: 1,
          hasReachedMax: posts.length < _pageSize,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: PostsStatus.failure, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostsStatus.failure,
          errorMessage: 'An unexpected error occurred while loading posts.',
        ),
      );
    }
  }

  Future<void> _onPostsNextPageRequested(
    PostsNextPageRequested event,
    Emitter<PostsState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != PostsStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, paginationErrorMessage: null));

    try {
      final nextPage = state.currentPage + 1;
      final newPosts = await postRepository.getPaginatedPosts(
        page: nextPage,
        limit: _pageSize,
        userId: state.activeFilterUserId,
      );

      final updatedPosts = List<Post>.from(state.posts)..addAll(newPosts);
      final filtered = _applyFilter(updatedPosts, state.searchQuery);

      emit(
        state.copyWith(
          posts: updatedPosts,
          filteredPosts: filtered,
          currentPage: nextPage,
          hasReachedMax: newPosts.length < _pageSize,
          isLoadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(isLoadingMore: false, paginationErrorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: 'Failed to load more posts.',
        ),
      );
    }
  }

  void _onPostsSearchChanged(
    PostsSearchChanged event,
    Emitter<PostsState> emit,
  ) {
    final filtered = _applyFilter(state.posts, event.query);
    emit(state.copyWith(searchQuery: event.query, filteredPosts: filtered));
  }

  Future<void> _onPostsFilterByUserRequested(
    PostsFilterByUserRequested event,
    Emitter<PostsState> emit,
  ) async {
    add(PostsFetchRequested(userId: event.userId));
  }

  Future<void> _onPostsRefreshRequested(
    PostsRefreshRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, errorMessage: null));

    try {
      final posts = await postRepository.getPaginatedPosts(
        page: 1,
        limit: _pageSize,
        userId: state.activeFilterUserId,
      );

      final filtered = _applyFilter(posts, state.searchQuery);

      emit(
        state.copyWith(
          status: PostsStatus.success,
          posts: posts,
          filteredPosts: filtered,
          currentPage: 1,
          hasReachedMax: posts.length < _pageSize,
          isRefreshing: false,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isRefreshing: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: 'Failed to refresh posts feed.',
        ),
      );
    }
  }

  void _onPostAddedOptimistically(
    PostAddedOptimistically event,
    Emitter<PostsState> emit,
  ) {
    final updatedPosts = [event.post, ...state.posts];
    final filtered = _applyFilter(updatedPosts, state.searchQuery);
    emit(
      state.copyWith(
        status: PostsStatus.success,
        posts: updatedPosts,
        filteredPosts: filtered,
      ),
    );
  }

  List<Post> _applyFilter(List<Post> posts, String query) {
    if (query.trim().isEmpty) return posts;
    final lower = query.toLowerCase();
    return posts.where((p) {
      return p.title.toLowerCase().contains(lower) ||
          p.body.toLowerCase().contains(lower);
    }).toList();
  }
}
