import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Gelişmiş grafik çizimi için kullanılan kütüphane
import '../models/weather_model.dart';
import '../services/weather_service.dart';

/// Gelecek günlerin hava tahminlerini görselleştiren ekran.
class ForecastScreen extends StatefulWidget {
  final String cityName; // Tahmini istenen şehrin adı ana ekrandan parametre olarak gelir.

  const ForecastScreen({
    super.key,
    required this.cityName,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  // --- State Değişkenleri ---
  List<HavaDurumu>? _forecasts; // API'den gelen 5 günlük tahmin listesi
  bool _isLoading = true; // Veri yüklenirken gösterilecek durum
  String? _error; // Hata durumunda tutulacak mesaj
  final HavaDurumuService _weatherService = HavaDurumuService();

  @override
  void initState() {
    super.initState();
    _fetchForecast(); // Ekran ilk açıldığında API isteğini başlatır.
  }

  /// 5 günlük tahmin verisini asenkron olarak çeken fonksiyon.
  void _fetchForecast() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forecasts = await _weatherService.fetch5DayForecast(widget.cityName);
      setState(() {
        _forecasts = forecasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Tahmin alınırken hata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uygulamanın temasını bugünün hava durumuna göre dinamik olarak değiştirir.
    final Color themeColor = _forecasts != null
        ? _getWeatherColor(_forecasts![0].ikonBilgisi)
        : Colors.lightBlueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName} - 5 Günlük Tahmin'),
        backgroundColor: themeColor, // AppBar rengi hava durumuna göre değişir.
      ),
      body: _buildBody(),
    );
  }

  /// Ana içerik yapısını (Yükleme, Hata veya Veri) yöneten metot.
  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_forecasts == null || _forecasts!.isEmpty) return const Center(child: Text('Veri yok.'));

    // Grafik ve kartlar için temel renk temasını belirler
    final Color dynamicColor = _getWeatherColor(_forecasts![0].ikonBilgisi);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sıcaklık Grafiği (°C)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // --- SICAKLIK GRAFİĞİ ALANI ---
          Container(
            height: 250,
            padding: const EdgeInsets.only(top: 25, right: 25, left: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: dynamicColor.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5
                )
              ],
            ),
            child: LineChart(_buildLineChartData(dynamicColor)),
          ),
          const SizedBox(height: 30),
          const Text('Günlük Detaylar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // --- GÜNLÜK LİSTE ALANI ---
          _buildDetailList(),
        ],
      ),
    );
  }

  /// fl_chart kütüphanesi için grafik verilerini ve stilini hazırlar.
  LineChartData _buildLineChartData(Color themeColor) {
    // Grafik ölçeklendirmesi için min ve max değerleri hesaplar
    double minY = _forecasts!.map((f) => f.havaSicakligi).reduce((a, b) => a < b ? a : b) - 2;
    double maxY = _forecasts!.map((f) => f.havaSicakligi).reduce((a, b) => a > b ? a : b) + 2;

    return LineChartData(
      gridData: const FlGridData(show: false), // Izgara çizgilerini gizler
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < _forecasts!.length) {
                final date = _forecasts![index].tarih!;
                // X eksenine gün isimlerini (Pzt, Sal vb.) yazdırır.
                return Text(['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][date.weekday - 1],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          // API verilerini grafik üzerindeki koordinat noktalarına (X, Y) dönüştürür.
          spots: _forecasts!.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.havaSicakligi)).toList(),
          isCurved: true, // Çizgiyi keskin değil, kavisli yapar.
          color: themeColor,
          barWidth: 5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, p, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: _getWeatherColor(_forecasts![index].ikonBilgisi),
                strokeColor: Colors.white,
                strokeWidth: 2
            ),
          ),
          belowBarData: BarAreaData(
              show: true,
              color: themeColor.withOpacity(0.2) // Çizginin altındaki alanı boyar.
          ),
        ),
      ],
    );
  }

  /// Tahminleri alt alta listeleyen metot.
  Widget _buildDetailList() {
    return ListView.builder(
      shrinkWrap: true, // Listenin boyutunu içeriğe göre ayarlar.
      physics: const NeverScrollableScrollPhysics(), // SingleChildScrollView içinde olduğu için kaydırmayı devre dışı bırakır.
      itemCount: _forecasts!.length,
      itemBuilder: (context, index) {
        final day = _forecasts![index];
        final color = _getWeatherColor(day.ikonBilgisi);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: color.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12)
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(_getWeatherIcon(day.ikonBilgisi), color: color, size: 32),
            title: Text('${day.tarih!.day}/${day.tarih!.month} - Tahmin', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(day.aciklama),
            trailing: Text(
                '${day.havaSicakligi.toStringAsFixed(1)}°',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)
            ),
          ),
        );
      },
    );
  }

  // --- YARDIMCI METOTLAR (İkon ve Renk Mantığı) ---

  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny;
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) return Icons.cloud;
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.umbrella;
    if (iconCode.startsWith('11')) return Icons.thunderstorm;
    if (iconCode.startsWith('13')) return Icons.ac_unit;
    return Icons.blur_on;
  }

  Color _getWeatherColor(String iconCode) {
    if (iconCode.startsWith('01')) return Colors.orange;
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) return Colors.blueGrey;
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Colors.blue;
    if (iconCode.startsWith('11')) return Colors.deepPurple;
    if (iconCode.startsWith('13')) return Colors.lightBlueAccent;
    return Colors.grey;
  }
}