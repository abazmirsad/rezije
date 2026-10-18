import 'kategorija.dart';

/// Model jednog režijskog računa.
///
/// Predstavlja jedan trošak (npr. račun za struju za mjesec maj).
class Racun {
  /// Jedinstveni ID iz baze. `null` dok račun još nije spremljen.
  final int? id;

  /// Kategorija troška (struja, voda, internet...).
  final Kategorija kategorija;

  /// Naziv provajdera / firme (npr. "Elektroprivreda", "BH Telecom").
  final String provajder;

  /// Iznos računa u KM (konvertibilna marka).
  final double iznos;

  /// Datum izdavanja računa.
  final DateTime datumIzdavanja;

  /// Datum do kojeg račun treba platiti.
  final DateTime datumDospijeca;

  /// Da li je račun plaćen.
  final bool placeno;

  /// Opcionalna bilješka korisnika.
  final String biljeska;

  const Racun({
    this.id,
    required this.kategorija,
    required this.provajder,
    required this.iznos,
    required this.datumIzdavanja,
    required this.datumDospijeca,
    this.placeno = false,
    this.biljeska = '',
  });

  /// Da li je rok plaćanja prošao, a račun još nije plaćen.
  bool get kasni {
    if (placeno) return false;
    final danas = DateTime.now();
    final rok = DateTime(
      datumDospijeca.year,
      datumDospijeca.month,
      datumDospijeca.day,
    );
    final danasBezVremena = DateTime(danas.year, danas.month, danas.day);
    return rok.isBefore(danasBezVremena);
  }

  /// Broj dana do dospijeća (negativno ako je rok prošao).
  int get danaDoDospijeca {
    final danas = DateTime.now();
    final danasBezVremena = DateTime(danas.year, danas.month, danas.day);
    final rok = DateTime(
      datumDospijeca.year,
      datumDospijeca.month,
      datumDospijeca.day,
    );
    return rok.difference(danasBezVremena).inDays;
  }

  /// Kopija računa s izmijenjenim poljima.
  Racun copyWith({
    int? id,
    Kategorija? kategorija,
    String? provajder,
    double? iznos,
    DateTime? datumIzdavanja,
    DateTime? datumDospijeca,
    bool? placeno,
    String? biljeska,
  }) {
    return Racun(
      id: id ?? this.id,
      kategorija: kategorija ?? this.kategorija,
      provajder: provajder ?? this.provajder,
      iznos: iznos ?? this.iznos,
      datumIzdavanja: datumIzdavanja ?? this.datumIzdavanja,
      datumDospijeca: datumDospijeca ?? this.datumDospijeca,
      placeno: placeno ?? this.placeno,
      biljeska: biljeska ?? this.biljeska,
    );
  }

  /// Pretvara račun u mapu za spremanje u SQLite bazu.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kategorija': kategorija.kljuc,
      'provajder': provajder,
      'iznos': iznos,
      'datum_izdavanja': datumIzdavanja.millisecondsSinceEpoch,
      'datum_dospijeca': datumDospijeca.millisecondsSinceEpoch,
      'placeno': placeno ? 1 : 0,
      'biljeska': biljeska,
    };
  }

  /// Kreira račun iz mape pročitane iz baze.
  factory Racun.fromMap(Map<String, dynamic> map) {
    return Racun(
      id: map['id'] as int?,
      kategorija: KategorijaInfo.izKljuca(map['kategorija'] as String),
      provajder: map['provajder'] as String,
      iznos: (map['iznos'] as num).toDouble(),
      datumIzdavanja: DateTime.fromMillisecondsSinceEpoch(
        map['datum_izdavanja'] as int,
      ),
      datumDospijeca: DateTime.fromMillisecondsSinceEpoch(
        map['datum_dospijeca'] as int,
      ),
      placeno: (map['placeno'] as int) == 1,
      biljeska: (map['biljeska'] as String?) ?? '',
    );
  }
}
