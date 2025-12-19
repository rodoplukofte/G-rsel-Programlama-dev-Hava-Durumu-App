/// Bu sınıf, uygulama genelinde kullanılan hava durumu veri yapısını tanımlar.
/// API'den gelen ham verilerin bir şablona oturtulmasını sağlar.
class HavaDurumu {
  final String sehirAdi;      // Şehrin ismi (Örn: Edirne)
  final double havaSicakligi; // Celsius cinsinden sıcaklık değeri
  final String aciklama;      // Hava durumu özeti (Örn: "hafif yağmurlu")
  final String ikonBilgisi;   // API'den gelen ikon kodu (Örn: "01d")
  final DateTime? tarih;      // Tahmin verileri için zaman bilgisi

  // Kurucu Metot (Constructor): Nesne oluşturulurken verilerin atanmasını sağlar.
  HavaDurumu({
    required this.sehirAdi,
    required this.havaSicakligi,
    required this.aciklama,
    required this.ikonBilgisi,
    this.tarih, // Tahmin ekranı dışında null olabilir
  });

  /// Factory Constructor: API'den gelen Map (JSON) yapısını
  /// HavaDurumu nesnesine dönüştüren özel bir kurucu metottur.
  /// Bu sayede 'json['main']['temp']' gibi karmaşık erişimler servis katmanında değil,
  /// modelin kendi içinde çözümlenir (Encapsulation).
  factory HavaDurumu.fromJson(Map<String, dynamic> json) {
    return HavaDurumu(
      sehirAdi: json['name'], // JSON'daki 'name' alanını sehirAdi'na eşle
      // API bazen int bazen double döndürebildiği için .toDouble() ile güvenli hale getiriyoruz.
      havaSicakligi: json['main']['temp'].toDouble(),
      // weather listesinin ilk elemanındaki açıklama ve ikon bilgisini al
      aciklama: json['weather'][0]['description'],
      ikonBilgisi: json['weather'][0]['icon'],
    );
  }
}