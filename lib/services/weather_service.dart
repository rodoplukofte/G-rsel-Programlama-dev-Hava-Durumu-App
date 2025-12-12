import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'dart:developer';

class HavaDurumuService {

  static const String apiKey = 'f0b12a731a8bc59bfd7f311ec3a6ed81';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<HavaDurumu> fetchWeather(String city) async {
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric&lang=tr';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return HavaDurumu.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Belirtilen şehir bulunamadı.');
    } else {
      throw Exception('Hava durumu verisi yüklenemedi.');
    }
  }



  Future<List<HavaDurumu>> fetch5DayForecast(String city) async {
    final url = 'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=tr';

    final response = await http.get(Uri.parse(url));

    log("5 Gunluk Tahmini Yanit Kodu: ${response.statusCode}");

    if (response.statusCode !=200){
      log("API Hata Icerigi: ${response.body}");
    }else{
      log("Basarili JSON Yaniti: ${response.body.substring(0, 500)} ...");
    }
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      final listForecasts = jsonResponse['list'] as List;

      List <HavaDurumu> dailyForecasts = [];

      for (int i = 0; i < listForecasts.length; i += 8) {
        final dayJson = listForecasts[i];

        if (dayJson != null) {
          dailyForecasts.add(
              HavaDurumu(
                sehirAdi: city,
                // Sıcaklık verisi 'main' içinde 'temp' alanındadır.
                havaSicakligi: dayJson['main']['temp'].toDouble(),
                aciklama: dayJson['weather'][0]['description'],
                ikonBilgisi: dayJson['weather'][0]['icon'],
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