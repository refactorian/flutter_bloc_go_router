import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local key-value storage service powered by SharedPreferences.
class LocalStorageService {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyAuthUser = 'app_auth_username';
  static const String _keyAuthToken = 'app_auth_token';
  static const String _keyFavoritePostIds = 'app_favorite_post_ids';
  static const String _keyRecentlyViewedPostIds =
      'app_recently_viewed_post_ids';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Factory helper to initialize async instance
  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Theme Mode Persistence ---
  ThemeMode getThemeMode() {
    final savedMode = _prefs.getString(_keyThemeMode);
    switch (savedMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    return _prefs.setString(_keyThemeMode, mode.name);
  }

  // --- Authentication State Persistence ---
  String? getAuthUsername() => _prefs.getString(_keyAuthUser);

  String? getAuthToken() => _prefs.getString(_keyAuthToken);

  Future<void> saveAuthSession({
    required String username,
    String? token,
  }) async {
    await _prefs.setString(_keyAuthUser, username);
    if (token != null) {
      await _prefs.setString(_keyAuthToken, token);
    }
  }

  Future<void> clearAuthSession() async {
    await _prefs.remove(_keyAuthUser);
    await _prefs.remove(_keyAuthToken);
  }

  // --- Favorite Posts Persistence ---
  List<int> getFavoritePostIds() {
    final list = _prefs.getStringList(_keyFavoritePostIds);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
  }

  Future<bool> saveFavoritePostIds(List<int> ids) {
    final stringList = ids.map((id) => id.toString()).toList();
    return _prefs.setStringList(_keyFavoritePostIds, stringList);
  }

  // --- Recently Viewed Items Persistence ---
  List<int> getRecentlyViewedPostIds() {
    final list = _prefs.getStringList(_keyRecentlyViewedPostIds);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
  }

  Future<bool> addRecentlyViewedPostId(int id, {int maxItems = 10}) async {
    final current = getRecentlyViewedPostIds();
    current.remove(id);
    current.insert(0, id);
    if (current.length > maxItems) {
      current.removeRange(maxItems, current.length);
    }
    final stringList = current.map((e) => e.toString()).toList();
    return _prefs.setStringList(_keyRecentlyViewedPostIds, stringList);
  }

  Future<bool> clearRecentlyViewedPostIds() async {
    return _prefs.remove(_keyRecentlyViewedPostIds);
  }
}
