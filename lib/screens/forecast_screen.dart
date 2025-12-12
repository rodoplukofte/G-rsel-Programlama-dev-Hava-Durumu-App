import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // fl_chart importu
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class ForecastScreen extends StatefulWidget {
  final String cityName;

  const ForecastScreen({
    super.key,
    required this.cityName,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  List<HavaDurumu>? _forecasts;
  bool _isLoading = true;
  String? _error;
  final HavaDurumuService _weatherService = HavaDurumuService();

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  void _fetchForecast() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forecasts = await _weatherService.fetch5DayForecast(
        widget.cityName,
      );
      print("Tahmin listesi boyutu: ${forecasts.length}");
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName} - 7 Günlük Tahmin'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_forecasts == null || _forecasts!.isEmpty) {
      return const Center(child: Text('Tahmin verisi bulunamadı.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sıcaklık Grafiği (°C)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            height: 250,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5),
              ],
            ),
            child: LineChart(_buildLineChartData()), // Grafik burada!
          ),
          const SizedBox(height: 30),
          const Text(
            'Günlük Detaylar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _buildDetailList(), // Detay listesi
        ],
      ),
    );
  }

  // GRAFİK VERİSİNİ HAZIRLAMA METODU
  LineChartData _buildLineChartData() {
    // Grafiğin minimum ve maksimum sıcaklıklarını bul
    double minY = _forecasts!.map((f) => f.havaSicakligi).reduce((a, b) => a < b ? a : b) - 2;
    double maxY = _forecasts!.map((f) => f.havaSicakligi).reduce((a, b) => a > b ? a : b) + 2;

    List<FlSpot> spots = _forecasts!.asMap().entries.map((entry) {
      // x: Gün indeksi (0'dan 6'ya)
      // y: Sıcaklık
      return FlSpot(
          entry.key.toDouble(),
          entry.value.havaSicakligi
      );
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              // X ekseninde gün isimlerini göster
              final dayIndex = value.toInt();
              if (dayIndex >= 0 && dayIndex < _forecasts!.length) {
                final day = _forecasts![dayIndex].tarih!;
                String dayName = dayIndex == 0 ? 'Bugün' : ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][day.weekday - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(dayName, style: const TextStyle(fontSize: 10)),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}°'),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: 6,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.redAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.red,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.redAccent.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  // GÜNLÜK DETAY LİSTESİ
  Widget _buildDetailList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Kaydırmayı engelle
      itemCount: _forecasts!.length,
      itemBuilder: (context, index) {
        final day = _forecasts![index];
        final dayName = index == 0 ? 'Bugün' : ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'][day.tarih!.weekday - 1];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(
              _getWeatherIcon(day.ikonBilgisi),
              color: Colors.amber,
              size: 30,
            ),
            title: Text(
              '$dayName - ${day.tarih!.day}/${day.tarih!.month}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(day.aciklama),
            trailing: Text(
              '${day.havaSicakligi.toStringAsFixed(1)}°C',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey),
            ),
          ),
        );
      },
    );
  }

  // İkon Eşleştirme (Ana ekrandan kopyalayabilirsiniz)
  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d': return Icons.wb_sunny;
      case '01n': return Icons.nights_stay;
      case '09d': case '09n': case '10d': case '10n': return Icons.cloudy_snowing;
      case '13d': case '13n': return Icons.ac_unit;
      case '50d': case '50n': return Icons.blur_on;
      case '02d': case '02n': case '03d': case '03n': return Icons.wb_cloudy;
      case '04d': case '04n': return Icons.cloud;
      default: return Icons.cloud;
    }
  }
}