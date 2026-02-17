import 'package:flutter/material.dart';
import 'services/weather_service.dart';
import 'models/weather_model.dart';
import 'screens/forecast_screen.dart';
import 'services/city_storage_service.dart';
import 'screens/outfit_screen.dart';


void main() {
  runApp(const MyApp());
}

/// Uygulamanın kök widget'ı. Tema ayarlarını ve ana sayfayı (Home) belirler.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hava Durumu',
      debugShowCheckedModeBanner: false, // Debug bandını kaldırır
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WeatherScreen(), // Uygulama açıldığında WeatherScreen yüklenir
    );
  }
}

/// Hava durumu verilerinin anlık değiştiği, dinamik içeriğe sahip ekran.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // --- Servis ve Kontrolcü Tanımlamaları ---
  final HavaDurumuService _weatherService = HavaDurumuService(); // API isteklerini yönetir
  final TextEditingController _cityController = TextEditingController(); // Kullanıcıdan input alır
  final CityStorageService _cityStorageService = CityStorageService(); // Yerel hafıza işlemlerini yönetir

  // --- State (Durum) Değişkenleri ---
  HavaDurumu? _currentWeather; // API'den dönen hava durumu nesnesini tutar
  bool _isLoading = false; // Yükleme animasyonunun gösterilip gösterilmeyeceğini kontrol eder
  String? _errorMessage; // Hata durumunda kullanıcıya gösterilecek mesaj

  @override
  void initState() {
    super.initState();
    // Widget ilk oluştuğunda yapılacak işlemler buraya yazılır.
  }

  /// Kullanıcının girdiği şehir ismine göre hava durumunu çeken asenkron metot.
  void _fetchWeather(String city) async {
    // Şehir adı boşsa hata mesajı set et ve işlemi durdur
    if (city.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir şehir adı giriniz.';
        _isLoading = false;
      });
      return;
    }

    // Arama başlamadan önce ekranı temizle ve yükleme durumuna geç (Progress Indicator)
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentWeather = null;
    });

    try {
      // API'den veriyi al
      final weather = await _weatherService.fetchWeather(city);
      // Başarılı aramayı cihaz hafızasındaki "Son Aramalar" listesine ekle
      await _cityStorageService.addRecent(city);

      setState(() {
        _currentWeather = weather; // Başarılı veriyi nesneye ata
        _isLoading = false; // Yüklemeyi sonlandır
      });
    } catch (e) {
      // Hata yakalama: 404 ise şehir bulunamadı, değilse genel bağlantı hatası
      setState(() {
        _errorMessage = e.toString().contains("404")
            ? 'Şehir bulunamadı.'
            : 'Veri yüklenirken bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DynamicSky'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      // Sol taraftan açılan yan menü (Drawer)
      drawer: _buildDrawer(context),
      // SingleChildScrollView: Klavye açıldığında ekranın taşmasını önler
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                // --- Şehir Arama Alanı (Input) ---
                TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Şehir Adı Giriniz',
                    hintText: 'Örn: İstanbul',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _fetchWeather(_cityController.text),
                    ),
                  ),
                  onSubmitted: _fetchWeather, // Enter tuşuna basınca arama yapar
                ),
                const SizedBox(height: 30),

                // --- Dinamik İçerik Yönetimi ---
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.blueAccent)
                else if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  )
                else if (_currentWeather != null)
                    _buildWeatherDisplayContent(_currentWeather!) // Veri varsa göster
                  else
                    _buildPlaceholder(), // Veri yoksa karşılama ekranını göster

                // --- 5 Günlük Tahmin Butonu ---
                if (_currentWeather != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton.icon(
                      onPressed: _navigateToForecast,
                      icon: const Icon(Icons.show_chart),
                      label: const Text('5 Günlük Tahmini Gör'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                    ),
                  ),
                if (_currentWeather != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OutfitScreen(
                              cityName: _currentWeather!.sehirAdi,
                              temperature: _currentWeather!.havaSicakligi,
                              weatherCode: _currentWeather!.ikonBilgisi,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.checkroom), // Elbise askısı ikonu
                      label: const Text('Ne Giymeliyim?'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent, // Dikkat çekici renk
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Henüz veri aranmamışken ekranda duran karşılama görseli.
  Widget _buildPlaceholder() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.cloud_queue,
          size: 120,
          color: Colors.lightBlueAccent.withOpacity(0.5),
        ),
        const SizedBox(height: 20),
        const Text(
          'Hava Durumunu Merak mı Ediyorsun?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text(
            'Hemen yukarıya bir şehir adı yazarak aramaya başla!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  /// Hava durumu sonuçlarının (Sıcaklık, İkon, Favori Butonu) gösterildiği alan.
  Widget _buildWeatherDisplayContent(HavaDurumu weather) {
    return Column(
      children: [
        Text(
          weather.sehirAdi,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        // --- Favorilere Ekleme/Çıkarma İşlemi (FutureBuilder) ---
        FutureBuilder<List<String>>(
          future: _cityStorageService.getFavorites(),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data
                ?.map((e) => e.toLowerCase())
                .contains(weather.sehirAdi.toLowerCase()) ?? false;

            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 30,
              ),
              onPressed: () async {
                if (isFavorite) {
                  await _cityStorageService.removeFavorite(weather.sehirAdi);
                } else {
                  await _cityStorageService.addFavorite(weather.sehirAdi);
                }
                setState(() {}); // Favori ikonunu güncellemek için ekranı yeniler
              },
            );
          },
        ),
        const SizedBox(height: 10),
        // --- Dinamik Hava Durumu İkonu ---
        Icon(
          _getWeatherIcon(weather.ikonBilgisi),
          size: 100,
          color: _getWeatherColor(weather.ikonBilgisi),
        ),
        const SizedBox(height: 10),
        Text(
          '${weather.havaSicakligi.toStringAsFixed(1)}°C',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 10),
        Text(
          weather.aciklama.toUpperCase(),
          style: const TextStyle(fontSize: 22, color: Colors.grey),
        ),
      ],
    );
  }

  /// Uygulamanın sol tarafındaki navigasyon menüsü (Favoriler ve Geçmiş).
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.lightBlueAccent),
            child: Text('Menü', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _buildSectionHeader('⭐ Favori Şehirler'),
          _buildCityList(_cityStorageService.getFavorites(), Icons.favorite),
          const Divider(),
          _buildSectionHeader('⏱️ Son Aramalar'),
          _buildCityList(_cityStorageService.getRecents(), Icons.history),
        ],
      ),
    );
  }

  /// Menü içerisindeki bölümler için başlık tasarımı.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 5.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  /// Favoriler ve Son Aramalar listesini oluşturan yardımcı metot.
  Widget _buildCityList(Future<List<String>> cityFuture, IconData icon) {
    return FutureBuilder<List<String>>(
      future: cityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text('Liste boş.', style: TextStyle(color: Colors.grey)),
          );
        }
        return Column(
          children: snapshot.data!.map((city) {
            return ListTile(
              leading: Icon(icon, color: Colors.amber),
              title: Text(city.toUpperCase()),
              onTap: () {
                _cityController.text = city;
                _fetchWeather(city); // Şehre tıklandığında aramayı başlatır
                Navigator.pop(context); // Menüyü kapatır
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Tahmin ekranına (ForecastScreen) geçiş yapar.
  void _navigateToForecast() {
    if (_currentWeather == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForecastScreen(cityName: _currentWeather!.sehirAdi),
      ),
    );
  }

  /// API'den gelen ikon kodunu Flutter'ın Material ikonlarına eşleştirir.
  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny;
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Icons.cloud;
    }
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.umbrella;
    if (iconCode.startsWith('11')) return Icons.thunderstorm;
    if (iconCode.startsWith('13')) return Icons.ac_unit;
    if (iconCode.startsWith('50')) return Icons.blur_on;
    return Icons.wb_cloudy;
  }

  /// API'den gelen hava durumuna göre uygulamanın ikon renklerini dinamik olarak belirler.
  Color _getWeatherColor(String iconCode) {
    if (iconCode.startsWith('01')) return Colors.orange; // Güneşli
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Colors.blueGrey; // Bulutlu
    }
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Colors.blue; // Yağmurlu
    if (iconCode.startsWith('11')) return Colors.deepPurple; // Fırtınalı
    if (iconCode.startsWith('13')) return Colors.lightBlueAccent; // Karlı
    return Colors.grey;
  }
}