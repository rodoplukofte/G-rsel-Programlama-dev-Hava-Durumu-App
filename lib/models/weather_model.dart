

class HavaDurumu {
  final String sehirAdi;
  final double havaSicakligi;
  final String aciklama;
  final String ikonBilgisi;
  final DateTime? tarih;

  HavaDurumu({
    required this.sehirAdi,
    required this.havaSicakligi,
    required this.aciklama,
    required this.ikonBilgisi,
    this.tarih,
  });


  factory HavaDurumu.fromJson(Map<String, dynamic> json) {
    return HavaDurumu(
      sehirAdi: json['name'],
      havaSicakligi: json['main']['temp'].toDouble(),
      aciklama: json['weather'][0]['description'],
      ikonBilgisi: json['weather'][0]['icon'],
    );
  }
}