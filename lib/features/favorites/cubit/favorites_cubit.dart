import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/repositories/post_repository.dart';

enum FavoritesStatus { initial, loading, success, failure }

class FavoritesState extends Equatable {
  final FavoritesStatus status;
  final Set<int> favoriteIds;
  final List<Post> favoritePosts;
  final String? errorMessage;

  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.favoriteIds = const {},
    this.favoritePosts = const [],
    this.errorMessage,
  });

  bool isFavorite(int postId) => favoriteIds.contains(postId);

  FavoritesState copyWith({
    FavoritesStatus? status,
    Set<int>? favoriteIds,
    List<Post>? favoritePosts,
    String? errorMessage,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      favoritePosts: favoritePosts ?? this.favoritePosts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, favoriteIds, favoritePosts, errorMessage];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository favoritesRepository;
  final PostRepository postRepository;

  FavoritesCubit({
    required this.favoritesRepository,
    required this.postRepository,
  }) : super(const FavoritesState()) {
    _loadInitialFavorites();
  }

  void _loadInitialFavorites() {
    final ids = favoritesRepository.getFavoritePostIds().toSet();
    emit(state.copyWith(favoriteIds: ids));
  }

  Future<void> toggleFavorite(int postId) async {
    final updatedList = await favoritesRepository.toggleFavorite(postId);
    final updatedSet = updatedList.toSet();

    // Also update favoritePosts list if already loaded
    final updatedPosts = state.favoritePosts
        .where((p) => updatedSet.contains(p.id))
        .toList();

    emit(state.copyWith(favoriteIds: updatedSet, favoritePosts: updatedPosts));
  }

  Future<void> loadFavoritePosts() async {
    final ids = favoritesRepository.getFavoritePostIds().toSet();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: FavoritesStatus.loading,
        favoriteIds: ids,
        errorMessage: null,
      ),
    );

    if (ids.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(status: FavoritesStatus.success, favoritePosts: []),
        );
      }
      return;
    }

    try {
      // Fetch the posts corresponding to favorited IDs
      final allPosts = await postRepository.getPosts();
      if (isClosed) return;
      final favPosts = allPosts.where((post) => ids.contains(post.id)).toList();

      emit(
        state.copyWith(
          status: FavoritesStatus.success,
          favoritePosts: favPosts,
        ),
      );
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: FavoritesStatus.failure,
            errorMessage: 'Failed to load favorite posts.',
          ),
        );
      }
    }
  }
}
