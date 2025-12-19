import 'dart:convert';
import 'package:http/http.dart' as http; // HTTP istekleri için kütüphane
import '../models/weather_model.dart';
import 'dart:developer'; // log() fonksiyonu için gerekli

/// Bu sınıf, OpenWeatherMap API'si ile iletişim kurarak
/// hava durumu verilerini çeken servis katmanıdır.
class HavaDurumuService {
  // API erişimi için gerekli olan anahtar (Sizin hesabınıza özel)
  static const String apiKey = 'f0b12a731a8bc59bfd7f311ec3a6ed81';

  // Anlık hava durumu için temel API adresi
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // -------------------------------------------------------------------
  // ANLIK HAVA DURUMU (CURRENT WEATHER)
  // -------------------------------------------------------------------

  /// Belirtilen şehrin anlık hava durumu verilerini getirir.
  Future<HavaDurumu> fetchWeather(String city) async {
    // units=metric: Celsius kullanmak için, lang=tr: Türkçe açıklama için
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric&lang=tr';

    // API'ye GET isteği gönderilir
    final response = await http.get(Uri.parse(url));

    // HTTP 200: Başarılı yanıt
    if (response.statusCode == 200) {
      // Gelen JSON metnini parçalayıp HavaDurumu modeline dönüştürür (Mapping)
      return HavaDurumu.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      // HTTP 404: Şehir adı veritabanında bulunamadı
      throw Exception('Belirtilen şehir bulunamadı.');
    } else {
      // Diğer hatalar (Bağlantı sorunu, API limiti vb.)
      throw Exception('Hava durumu verisi yüklenemedi.');
    }
  }

  // -------------------------------------------------------------------
  // 5 GÜNLÜK TAHMİN (5 DAY FORECAST)
  // -------------------------------------------------------------------

  /// Belirtilen şehrin 5 günlük hava tahmin verilerini liste olarak getirir.
  Future<List<HavaDurumu>> fetch5DayForecast(String city) async {
    final url = 'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=tr';

    final response = await http.get(Uri.parse(url));

    // Hata ayıklama (Debug) için yanıt kodlarını logluyoruz
    log("5 Gunluk Tahmini Yanit Kodu: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // API her 3 saatte bir veri verir (Günde 8 veri).
      // Biz günlük tahmin istediğimiz için 8'er 8'er atlayarak 24 saatlik farklarla veri alıyoruz.
      final listForecasts = jsonResponse['list'] as List;
      List<HavaDurumu> dailyForecasts = [];

      for (int i = 0; i < listForecasts.length; i += 8) {
        final dayJson = listForecasts[i];

        if (dayJson != null) {
          // Ham JSON verisinden sadece ihtiyacımız olan alanları ayıklıyoruz
          dailyForecasts.add(
              HavaDurumu(
                sehirAdi: city,
                havaSicakligi: dayJson['main']['temp'].toDouble(),
                aciklama: dayJson['weather'][0]['description'],
                ikonBilgisi: dayJson['weather'][0]['icon'],
                // API 'unix timestamp' (saniye) döndürür, Dart bunu milisaniye olarak işler (* 1000)
                tarih: DateTime.fromMillisecondsSinceEpoch(dayJson['dt'] * 1000),
              )
          );
        }
      }
      log('Grafik için toplanan veri noktası sayısı: ${dailyForecasts.length}');
      return dailyForecasts;
    } else {
      throw Exception('5 günlük tahmin yüklenemedi: ${response.statusCode}');
    }
  }

  // -------------------------------------------------------------------
  // COĞRAFİ KONUM (GEO-CODING)
  // -------------------------------------------------------------------

  /// Şehir adını kullanarak Enlem (lat) ve Boylam (lon) bilgilerini getirir.
  Future<Map<String, double>> getCoordinates(String city) async {
    final geoUrl = 'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey';
    final response = await http.get(Uri.parse(geoUrl));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse.isNotEmpty) {
        return {
          'lat': jsonResponse[0]['lat'].toDouble(),
          'lon': jsonResponse[0]['lon'].toDouble(),
        };
      }
      throw Exception('Koordinatlar bulunamadı.');
    } else {
      throw Exception('Koordinat servisi hatası.');
    }
  }
}