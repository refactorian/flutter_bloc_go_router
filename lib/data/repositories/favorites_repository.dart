import '../../core/storage/local_storage_service.dart';

/// Repository responsible for managing local favorite post IDs.
class FavoritesRepository {
  final LocalStorageService? storageService;

  const FavoritesRepository({this.storageService});

  List<int> getFavoritePostIds() {
    return storageService?.getFavoritePostIds() ?? [];
  }

  Future<List<int>> toggleFavorite(int postId) async {
    final current = List<int>.from(storageService?.getFavoritePostIds() ?? []);
    if (current.contains(postId)) {
      current.remove(postId);
    } else {
      current.add(postId);
    }
    await storageService?.saveFavoritePostIds(current);
    return current;
  }

  bool isFavorite(int postId) {
    return storageService?.getFavoritePostIds().contains(postId) ?? false;
  }
}
