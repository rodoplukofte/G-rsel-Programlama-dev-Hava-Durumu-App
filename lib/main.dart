import 'package:flutter/material.dart';
import 'services/weather_service.dart';
import 'models/weather_model.dart';
import 'screens/forecast_screen.dart'; // Tahmin ekranı importu
import 'services/city_storage_service.dart'; // CityStorageService importu

void main() {
  // Varsayılan şehir adını burada set etme kaldırıldı, initState'te yapılacak
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hava Durumu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final HavaDurumuService _weatherService = HavaDurumuService();
  final TextEditingController _cityController = TextEditingController();
  final CityStorageService _cityStorageService = CityStorageService(); // Storage servisi

  // State Değişkenleri
  HavaDurumu? _currentWeather;
  bool _isLoading = false;
  String? _errorMessage;

  // Varsayılan bir şehirle başla
  @override
  void initState() {
    super.initState();
    _cityController.text = 'Edirne'; // Varsayılan şehir adını set et
    _fetchWeather(_cityController.text);
  }

  // API Çağrısını Yöneten Metot
  void _fetchWeather(String city) async {
    // Şehir adı boşsa veya sadece boşluklardan oluşuyorsa işlemi durdur
    if (city
        .trim()
        .isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir şehir adı giriniz.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentWeather = null;
    });

    try {
      final weather = await _weatherService.fetchWeather(city);

      // Başarılı aramayı son aramalara kaydet
      await _cityStorageService.addRecent(city);

      setState(() {
        _currentWeather = weather;
        _isLoading = false;
      });
    } catch (e) {
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
        title: const Text('Hava Durumu Uygulaması'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: _buildDrawer(context), // <<< ÇEKMECE MENÜ BURADA BAŞLAR
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Şehir Adı Giriniz',
                  hintText: 'Şehir Adı Giriniz',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _fetchWeather(_cityController.text),
                  ),
                ),
                onSubmitted: _fetchWeather,
              ),

              const SizedBox(height: 30),


              if (_isLoading)
                const CircularProgressIndicator(color: Colors.blueAccent)
              else
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  )
                else
                  if (_currentWeather != null)
                    _buildWeatherDisplayContent(
                        _currentWeather!) // <<< İÇERİK İÇİN YENİ METOT KULLANILDI
                  else
                    const Text('Hava durumu verisi bekleniyor...',
                        style: TextStyle(fontSize: 16)),

              // YENİ BUTON KISMI
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
            ],
          ),
        ),
      ),
    );
  }

  // Hava Durumu Verisini GÖSTEREN Yardımcı Widget (Eski _buildWeatherDisplay)
  Widget _buildWeatherDisplayContent(HavaDurumu weather) {
    return Column(
      children: [
        Text(
          weather.sehirAdi,
          style: const TextStyle(fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
        ),

        // FAVORİ BUTONU
        FutureBuilder<List<String>>(
          future: _cityStorageService.getFavorites(),
          builder: (context, snapshot) {
            // Şehrin favori listesinde olup olmadığını kontrol et
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
                // Favori listesini güncellemek için setState ile Drawer'ı ve bu butonu yenile
                setState(() {});
              },
            );
          },
        ),

        const SizedBox(height: 10),
        Icon(
          _getWeatherIcon(weather.ikonBilgisi),
          size: 100,
          color: Colors.amber,
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

  // ----------------------------------------------------------------------------------
  // ÇEKMECE MENÜ (DRAWER) YAPISI
  // ----------------------------------------------------------------------------------

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
            ),
            child: Text(
              'Menü',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          _buildSectionHeader('⭐ Favori Şehirler'),
          _buildCityList(
            _cityStorageService.getFavorites(),
            Icons.favorite,
          ),

          const Divider(),

          _buildSectionHeader('⏱️ Son Aramalar'),
          _buildCityList(
            _cityStorageService.getRecents(),
            Icons.history,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 5.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

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
                // Tıklanan şehirle arama yap
                _cityController.text = city;
                _fetchWeather(city);
                Navigator.pop(context); // Drawer'ı kapat
              },
            );
          }).toList(),
        );
      },
    );
  }

  // ----------------------------------------------------------------------------------
  // DİĞER METOTLAR
  // ----------------------------------------------------------------------------------

  void _navigateToForecast() async {
    if (_currentWeather == null) return;

    // 5 günlük tahmin ekranına yönlendiriyoruz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ForecastScreen(
              cityName: _currentWeather!.sehirAdi,
            ),
      ),
    );
  }


  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d': // Açık Hava (Gündüz)
      case '01n': // Açık Hava (Gece)
        return Icons.wb_sunny;
      case '09d': // Hafif Yağmur
      case '09n':
      case '10d': // Yağmur
      case '10n':
        return Icons.cloudy_snowing;
      case '13d': // Kar
      case '13n':
        return Icons.ac_unit;
      case '50d': // Sis
      case '50n':
        return Icons.blur_on;
      default:
        return Icons.cloud;
    }
  }
}
