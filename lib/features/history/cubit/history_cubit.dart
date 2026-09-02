import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/repositories/post_repository.dart';

class HistoryState extends Equatable {
  final List<int> recentPostIds;
  final List<Post> recentPosts;
  final bool isLoading;

  const HistoryState({
    this.recentPostIds = const [],
    this.recentPosts = const [],
    this.isLoading = false,
  });

  HistoryState copyWith({
    List<int>? recentPostIds,
    List<Post>? recentPosts,
    bool? isLoading,
  }) {
    return HistoryState(
      recentPostIds: recentPostIds ?? this.recentPostIds,
      recentPosts: recentPosts ?? this.recentPosts,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [recentPostIds, recentPosts, isLoading];
}

class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository historyRepository;
  final PostRepository postRepository;

  HistoryCubit({required this.historyRepository, required this.postRepository})
    : super(const HistoryState()) {
    loadRecentHistory();
  }

  void loadRecentHistory() {
    final ids = historyRepository.getRecentlyViewedPostIds();
    emit(state.copyWith(recentPostIds: ids));
    fetchRecentPostsDetails();
  }

  Future<void> recordViewedPost(int postId) async {
    await historyRepository.recordRecentlyViewed(postId);
    final ids = historyRepository.getRecentlyViewedPostIds();
    emit(state.copyWith(recentPostIds: ids));
    fetchRecentPostsDetails();
  }

  Future<void> fetchRecentPostsDetails() async {
    if (isClosed) return;
    if (state.recentPostIds.isEmpty) {
      emit(state.copyWith(recentPosts: []));
      return;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final List<Post> loaded = [];
      for (final id in state.recentPostIds.take(5)) {
        try {
          final post = await postRepository.getPostById(id);
          loaded.add(post);
        } catch (_) {}
      }
      if (!isClosed) {
        emit(state.copyWith(recentPosts: loaded, isLoading: false));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> clearHistory() async {
    await historyRepository.clearHistory();
    emit(const HistoryState());
  }
}
