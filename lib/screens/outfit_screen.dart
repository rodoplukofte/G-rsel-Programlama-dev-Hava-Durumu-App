import 'package:flutter/material.dart';

class OutfitScreen extends StatelessWidget {
  final double temperature;
  final String weatherCode;
  final String cityName;

  const OutfitScreen({
    super.key,
    required this.temperature,
    required this.weatherCode,
    required this.cityName,
  });

  // 🎨 RENK PALETİ MANTIĞI BURADA
  // Hava durumu koduna göre arka plan renk listesi (Gradient) döndürür
  List<Color> _getBackgroundGradient(String code) {
    // 1. GÜNEŞLİ / AÇIK (Day & Night)
    if (code == '01d') {
      // Gündüz: Turuncudan Maviye (Canlı gün doğumu hissi)
      return [Colors.orangeAccent, Colors.lightBlueAccent];
    } else if (code == '01n') {
      // Gece: Koyu Lacivertten Siyaha
      return [const Color(0xFF1A237E), Colors.black];
    }

    // 2. BULUTLU (02, 03, 04)
    if (code.startsWith('02') || code.startsWith('03') || code.startsWith('04')) {
      // Gündüz veya Gece fark etmeksizin Grimsi Mavi
      return [Colors.blueGrey, Colors.grey.shade300];
    }

    // 3. YAĞMURLU (09, 10)
    if (code.startsWith('09') || code.startsWith('10')) {
      // Koyu Gri ve Kasvetli Mavi
      return [const Color(0xFF37474F), const Color(0xFF455A64)];
    }

    // 4. FIRTINA / ŞİMŞEK (11)
    if (code.startsWith('11')) {
      // Koyu Mor (Elektrik hissi)
      return [Colors.deepPurple.shade900, const Color(0xFF212121)];
    }

    // 5. KARLI (13)
    if (code.startsWith('13')) {
      // Çok açık mavi ve beyaz
      return [Colors.blue.shade100, Colors.white];
    }

    // 6. SİSLİ (50)
    if (code.startsWith('50')) {
      return [Colors.grey.shade400, Colors.grey.shade200];
    }

    // Varsayılan (Eşleşme olmazsa)
    return [Colors.blue, Colors.lightBlueAccent];
  }

  @override
  Widget build(BuildContext context) {
    // Fonksiyondan renkleri alıyoruz
    final gradientColors = _getBackgroundGradient(weatherCode);

    return Scaffold(
      extendBodyBehindAppBar: true, // AppBar'ın arkasına da renk gitmesi için
      appBar: AppBar(
        title: const Text('Ne Giymeliyim?'),
        backgroundColor: Colors.transparent, // Şeffaf AppBar
        elevation: 0,
        foregroundColor: Colors.white, // Geri butonu ve yazı rengi
      ),
      body: Container(
        decoration: BoxDecoration(
          // 🌈 DİNAMİK GRADYAN BURADA UYGULANIYOR
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Şehir ve Derece Bilgisi
              Text(
                cityName,
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))]
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "${temperature.toStringAsFixed(1)}°C",
                style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))]
                ),
              ),
              const SizedBox(height: 40),

              // Kıyafet Öneri Kartı
              _OutfitRecommendationWidget(
                temperature: temperature,
                weatherCode: weatherCode,
              ),

              const SizedBox(height: 40),

              // Geri Dön Butonu
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Geri Dön"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.white.withOpacity(0.2), // Yarı saydam buton
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Colors.white70, width: 1), // İnce beyaz çerçeve
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET AYNI KALIYOR ---
class _OutfitRecommendationWidget extends StatelessWidget {
  final double temperature;
  final String weatherCode;

  const _OutfitRecommendationWidget({
    required this.temperature,
    required this.weatherCode,
  });

  @override
  Widget build(BuildContext context) {
    final outfitList = _getOutfitSuggestions();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90), // Kartın içi her zaman beyaz kalsın ki okunsun
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            " Kombin Önerin",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: outfitList.map((item) {
              return Column(
                children: [
                  Text(
                    item['emoji']!,
                    style: const TextStyle(fontSize: 45),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name']!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getOutfitSuggestions() {
    List<Map<String, String>> items = [];

    // Sıcaklık Kontrolü
    if (temperature < 5) {
      items.add({'name': 'Mont', 'emoji': '🧥'});
      items.add({'name': 'Atkı', 'emoji': '🧣'});
      items.add({'name': 'Eldiven', 'emoji': '🧤'});
    } else if (temperature >= 5 && temperature < 15) {
      items.add({'name': 'Kaban', 'emoji': '🧥'});
      items.add({'name': 'Kazak', 'emoji': '🧶'});
      items.add({'name': 'Bot', 'emoji': '🥾'});
    } else if (temperature >= 15 && temperature < 23) {
      items.add({'name': 'Tişört', 'emoji': '👕'});
      items.add({'name': 'Hırka', 'emoji': '👚'});
      items.add({'name': 'Jean', 'emoji': '👖'});
    } else {
      items.add({'name': 'Tişört', 'emoji': '👕'});
      items.add({'name': 'Şort', 'emoji': '🩳'});
      items.add({'name': 'Gözlük', 'emoji': '🕶️'});
    }

    // Hava Durumu Ekstraları
    if (weatherCode.startsWith('09') || weatherCode.startsWith('10') || weatherCode.startsWith('11')) {
      if (items.length >= 3) items.removeLast();
      items.add({'name': 'Şemsiye', 'emoji': '☂️'});
    }

    return items;
  }
}
