import 'kategorija.dart';

/// Model jednog režijskog računa.
///
/// Predstavlja jedan trošak (npr. račun za struju za mjesec maj).
class Racun {
  /// Jedinstveni ID iz baze. `null` dok račun još nije spremljen.
  final int? id;

  /// Kategorija troška (struja, voda, internet...).
  final Kategorija kategorija;

  /// Naziv provajdera / firme (npr. "Telemach", "Elektroprivreda").
  final String provajder;

  /// Mjesečni iznos računa u KM (vrijednost usluga za taj mjesec).
  final double iznos;

  /// Datum izdavanja računa.
  final DateTime datumIzdavanja;

  /// Datum do kojeg račun treba platiti.
  final DateTime datumDospijeca;

  /// Da li je račun plaćen.
  final bool placeno;

  /// Opcionalna bilješka korisnika.
  final String biljeska;

  /// Poziv na broj (referenca za plaćanje). Opcionalno.
  final String pozivNaBroj;

  /// Početak perioda pružanja usluge. Opcionalno.
  final DateTime? periodOd;

  /// Kraj perioda pružanja usluge. Opcionalno.
  final DateTime? periodDo;

  /// Trenutno stanje / ukupno za uplatu (uključuje dug ili pretplatu).
  /// Ako je `null`, podrazumijeva se da je jednako mjesečnom [iznos].
  final double? iznosZaUplatu;

  const Racun({
    this.id,
    required this.kategorija,
    required this.provajder,
    required this.iznos,
    required this.datumIzdavanja,
    required this.datumDospijeca,
    this.placeno = false,
    this.biljeska = '',
    this.pozivNaBroj = '',
    this.periodOd,
    this.periodDo,
    this.iznosZaUplatu,
  });

  /// Stvarni iznos za uplatu: [iznosZaUplatu] ako postoji, inače mjesečni [iznos].
  double get zaUplatu => iznosZaUplatu ?? iznos;

  /// Da li se iznos za uplatu razlikuje od mjesečnog iznosa
  /// (npr. zbog duga ili pretplate).
  bool get imaRazlikuStanja =>
      iznosZaUplatu != null && (iznosZaUplatu! - iznos).abs() > 0.001;

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
  ///
  /// Napomena: `periodOd`, `periodDo` i `iznosZaUplatu` se ne mogu
  /// vratiti na `null` kroz copyWith (prosljeđivanje `null` zadržava
  /// staru vrijednost) - to je u redu za naše potrebe.
  Racun copyWith({
    int? id,
    Kategorija? kategorija,
    String? provajder,
    double? iznos,
    DateTime? datumIzdavanja,
    DateTime? datumDospijeca,
    bool? placeno,
    String? biljeska,
    String? pozivNaBroj,
    DateTime? periodOd,
    DateTime? periodDo,
    double? iznosZaUplatu,
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
      pozivNaBroj: pozivNaBroj ?? this.pozivNaBroj,
      periodOd: periodOd ?? this.periodOd,
      periodDo: periodDo ?? this.periodDo,
      iznosZaUplatu: iznosZaUplatu ?? this.iznosZaUplatu,
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
      'poziv_na_broj': pozivNaBroj,
      'period_od': periodOd?.millisecondsSinceEpoch,
      'period_do': periodDo?.millisecondsSinceEpoch,
      'iznos_za_uplatu': iznosZaUplatu,
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
      pozivNaBroj: (map['poziv_na_broj'] as String?) ?? '',
      periodOd: map['period_od'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['period_od'] as int),
      periodDo: map['period_do'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['period_do'] as int),
      iznosZaUplatu: map['iznos_za_uplatu'] == null
          ? null
          : (map['iznos_za_uplatu'] as num).toDouble(),
    );
  }
}
