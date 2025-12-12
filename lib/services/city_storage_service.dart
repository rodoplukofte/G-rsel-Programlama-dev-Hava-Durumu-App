import 'package:shared_preferences/shared_preferences.dart';

class CityStorageService {
  static const String _favoritesKey = 'favoriteCities';
  static const String _recentKey = 'recentCities';

  // ------------------------- FAVORİ ŞEHİRLER -------------------------

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> addFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavorites();
    city = city.toLowerCase();

    // Zaten favorilerde yoksa ekle
    if (!favorites.map((e) => e.toLowerCase()).contains(city)) {
      favorites.add(city);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  Future<void> removeFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavorites();
    city = city.toLowerCase();

    favorites.removeWhere((e) => e.toLowerCase() == city);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // ------------------------- SON ARAMALAR -------------------------

  Future<List<String>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  Future<void> addRecent(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = await getRecents();
    city = city.toLowerCase();

    // Eğer zaten listede varsa önce sil (listenin başına gelmesi için)
    recents.removeWhere((e) => e.toLowerCase() == city);

    // Başa ekle
    recents.insert(0, city);

    // Listeyi 5 ile sınırla (istediğiniz sayı olabilir)
    if (recents.length > 5) {
      recents = recents.sublist(0, 5);
    }

    await prefs.setStringList(_recentKey, recents);
  }
}