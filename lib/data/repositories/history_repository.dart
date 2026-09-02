import '../../core/storage/local_storage_service.dart';

/// Repository managing recently viewed items history.
class HistoryRepository {
  final LocalStorageService? storageService;

  const HistoryRepository({this.storageService});

  List<int> getRecentlyViewedPostIds() {
    return storageService?.getRecentlyViewedPostIds() ?? [];
  }

  Future<void> recordRecentlyViewed(int postId) async {
    await storageService?.addRecentlyViewedPostId(postId);
  }

  Future<void> clearHistory() async {
    await storageService?.clearRecentlyViewedPostIds();
  }
}
