import 'package:shared_preferences/shared_preferences.dart';

// Избранные валюты храним просто списком кодов в shared_preferences
class FavoritesStorage {
  static const String _key = 'favorite_currencies';

  // при первом запуске что-то уже отмечено, чтобы список не был пустым
  static const List<String> defaultFavorites = ['USD', 'EUR', 'CNY'];

  Future<List<String>> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? List.of(defaultFavorites);
  }

  Future<void> save(List<String> codes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, codes);
  }
}
