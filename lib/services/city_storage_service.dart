import 'package:shared_preferences/shared_preferences.dart';

/// Bu sınıf, kullanıcının favori şehirlerini ve son aramalarını
/// cihazın yerel hafızasında saklamak için kullanılır.
/// Depolama birimi olarak Flutter'ın popüler 'shared_preferences' kütüphanesi tercih edilmiştir.
class CityStorageService {
  // Veritabanı anahtarları (Key-Value yapısı için benzersiz isimler)
  static const String _favoritesKey = 'favoriteCities';
  static const String _recentKey = 'recentCities';

  // -------------------------------------------------------------------
  // FAVORİ ŞEHİRLER (FAVORITES) MANTIĞI
  // -------------------------------------------------------------------

  /// Yerel hafızadan favori şehir listesini getirir.
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance(); // Hafıza erişim izni al
    // Veri yoksa boş bir liste döndür (Null check)
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  /// Yeni bir şehri favorilere ekler.
  Future<void> addFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavorites();
    city = city.toLowerCase(); // Veri tutarlılığı için küçük harfe çevir

    // Mükerrer (tekrar eden) kaydı önlemek için kontrol yapıyoruz:
    // Eğer şehir listede yoksa ekleme işlemini gerçekleştir.
    if (!favorites.map((e) => e.toLowerCase()).contains(city)) {
      favorites.add(city);
      // Güncellenmiş listeyi cihaza kalıcı olarak kaydet
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  /// Bir şehri favori listesinden siler.
  Future<void> removeFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = await getFavorites();
    city = city.toLowerCase();

    // Listeden belirtilen şehri temizle (Case-insensitive silme)
    favorites.removeWhere((e) => e.toLowerCase() == city);
    // Yeni listeyi kaydet
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // -------------------------------------------------------------------
  // SON ARAMALAR (HISTORY) MANTIĞI
  // -------------------------------------------------------------------

  /// Kullanıcının daha önce arattığı şehirlerin geçmişini getirir.
  Future<List<String>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  /// Yapılan son aramayı listeye ekler ve listeyi güncel tutar.
  Future<void> addRecent(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = await getRecents();
    city = city.toLowerCase();

    // EĞER ŞEHİR ZATEN VARSA: Önce eski yerinden siliyoruz.
    // Çünkü en son aranan şehrin listenin en üstünde (0. index) görünmesini istiyoruz.
    recents.removeWhere((e) => e.toLowerCase() == city);

    // Listeye en baştan (0. pozisyon) ekleme yap
    recents.insert(0, city);

    // BELLEK YÖNETİMİ: Geçmiş listesinin sonsuza kadar uzayıp hafızayı şişirmemesi için
    // listeyi son 5 kayıt ile sınırlandırıyoruz (LIFO - Last In First Out mantığı).
    if (recents.length > 5) {
      recents = recents.sublist(0, 5); // Sadece ilk 5 elemanı tut, gerisini sil
    }

    // Güncellenmiş geçmiş listesini cihaza kaydet
    await prefs.setStringList(_recentKey, recents);
  }
}