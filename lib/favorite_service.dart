import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _keyFavorites = 'user_favorites';

  /// Mendapatkan list ID item yang difavoritkan.
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  /// Mengecek apakah item dengan ID tertentu merupakan favorit.
  static Future<bool> isFavorite(String itemId) async {
    if (itemId.isEmpty) return false;
    final list = await getFavorites();
    return list.contains(itemId);
  }

  /// Menambah atau menghapus item dari list favorit.
  /// Mengembalikan `true` jika status setelah toggle adalah favorite, `false` jika tidak.
  static Future<bool> toggleFavorite(String itemId) async {
    if (itemId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavorites) ?? [];
    bool isFav;
    if (list.contains(itemId)) {
      list.remove(itemId);
      isFav = false;
    } else {
      list.add(itemId);
      isFav = true;
    }
    await prefs.setStringList(_keyFavorites, list);
    return isFav;
  }
}
