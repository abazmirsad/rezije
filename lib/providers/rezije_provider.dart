import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/baza_pomocnik.dart';
import '../models/kategorija.dart';
import '../models/racun.dart';
import '../pdf/pdf_servis.dart';
import '../pdf/rezultat_parsiranja.dart';

/// Centralno mjesto za upravljanje stanjem aplikacije.
///
/// Učitava račune iz baze, pamti ih u memoriji i obavještava UI kad
/// se nešto promijeni. Takođe računa statistike za dashboard i grafove.
class RezijeProvider extends ChangeNotifier {
  final BazaPomocnik _baza = BazaPomocnik.instanca;

  List<Racun> _racuni = [];
  bool _ucitavanje = true;

  /// Svi računi (nepromjenjiva lista).
  List<Racun> get racuni => List.unmodifiable(_racuni);

  /// Da li se podaci trenutno učitavaju.
  bool get ucitavanje => _ucitavanje;

  /// Učitava sve račune iz baze. Poziva se pri pokretanju aplikacije.
  ///
  /// Pri prvom pokretanju (prazna baza) ubacuje nekoliko primjera računa
  /// kako bi grafovi i pregled odmah imali šta prikazati. Primjeri se
  /// mogu slobodno obrisati iz aplikacije.
  Future<void> ucitajRacune() async {
    _ucitavanje = true;
    notifyListeners();

    _racuni = await _baza.dohvatiSveRacune();

    if (_racuni.isEmpty) {
      await _ubaciPrimjere();
      _racuni = await _baza.dohvatiSveRacune();
    }

    _ucitavanje = false;
    notifyListeners();
  }

  /// TEST: učita ugrađene PDF uzorke iz assets, parsira ih i doda račune.
  ///
  /// Služi da se na telefonu provjeri da čitanje PDF-a radi, prije nego
  /// Gmail integracija proradi. Vraća tekstualni izvještaj o rezultatu.
  Future<String> testirajPdfUzorke() async {
    const uzorci = [
      'assets/uzorci/telemach_09.pdf',
      'assets/uzorci/telemach_07.pdf',
      'assets/uzorci/gas_508055.pdf',
      'assets/uzorci/gas_656644.pdf',
      'assets/uzorci/oki_10_12.pdf', // 1 PDF = 3 računa
    ];

    final izvjestaj = StringBuffer();
    int dodato = 0;

    for (final putanja in uzorci) {
      try {
        final podaci = await rootBundle.load(putanja);
        final bajtovi = podaci.buffer.asUint8List();
        final RezultatParsiranja rez = PdfServis.parsirajRacun(bajtovi);

        if (rez.uspjeh && rez.racuni.isNotEmpty) {
          // Jedan PDF može imati više računa (OKI: 3 mjeseca).
          for (final r in rez.racuni) {
            await dodajRacun(r);
            dodato++;
            izvjestaj.writeln(
              '✓ ${r.provajder}: ${r.iznos.toStringAsFixed(2)} KM, '
              'poziv ${r.pozivNaBroj}',
            );
          }
        } else {
          // DIJAGNOSTIKA: prikaži sirovi tekst koji syncfusion izvuče,
          // da vidimo zašto parser ne prepoznaje račun.
          final siroviTekst = PdfServis.izvuciTekst(bajtovi);
          final isjecak = siroviTekst.length > 400
              ? siroviTekst.substring(0, 400)
              : siroviTekst;
          izvjestaj.writeln(
            '✗ ${putanja.split("/").last} '
            '(izvučeno ${siroviTekst.length} znakova):',
          );
          izvjestaj.writeln('--- TEKST ---');
          izvjestaj.writeln(isjecak.isEmpty ? '(PRAZNO)' : isjecak);
          izvjestaj.writeln('--- kraj ---');
        }
      } catch (e) {
        izvjestaj.writeln('✗ ${putanja.split("/").last}: greška ($e)');
      }
    }

    return 'Dodato $dodato računa (iz ${uzorci.length} PDF-a).\n\n$izvjestaj';
  }

  /// Ubacuje demo račune za zadnja tri mjeseca.
  Future<void> _ubaciPrimjere() async {
    final sada = DateTime.now();

    // Pomoćna funkcija za kreiranje datuma u određenom mjesecu unazad.
    DateTime uMjesecu(int unazad, int dan) {
      return DateTime(sada.year, sada.month - unazad, dan);
    }

    final primjeri = <Racun>[
      // Trenutni mjesec
      Racun(
        kategorija: Kategorija.struja,
        provajder: 'Elektroprivreda',
        iznos: 78.40,
        datumIzdavanja: uMjesecu(0, 3),
        datumDospijeca: uMjesecu(0, 20),
      ),
      Racun(
        kategorija: Kategorija.voda,
        provajder: 'Vodovod',
        iznos: 32.10,
        datumIzdavanja: uMjesecu(0, 5),
        datumDospijeca: uMjesecu(0, 22),
      ),
      Racun(
        kategorija: Kategorija.internet,
        provajder: 'BH Telecom',
        iznos: 45.00,
        datumIzdavanja: uMjesecu(0, 1),
        datumDospijeca: uMjesecu(0, 15),
        placeno: true,
      ),
      // Prošli mjesec
      Racun(
        kategorija: Kategorija.struja,
        provajder: 'Elektroprivreda',
        iznos: 92.70,
        datumIzdavanja: uMjesecu(1, 3),
        datumDospijeca: uMjesecu(1, 20),
        placeno: true,
      ),
      Racun(
        kategorija: Kategorija.plin,
        provajder: 'Sarajevogas',
        iznos: 120.00,
        datumIzdavanja: uMjesecu(1, 4),
        datumDospijeca: uMjesecu(1, 21),
        placeno: true,
      ),
      Racun(
        kategorija: Kategorija.komunalije,
        provajder: 'Rad',
        iznos: 18.50,
        datumIzdavanja: uMjesecu(1, 6),
        datumDospijeca: uMjesecu(1, 23),
        placeno: true,
      ),
      // Pretprošli mjesec
      Racun(
        kategorija: Kategorija.struja,
        provajder: 'Elektroprivreda',
        iznos: 85.30,
        datumIzdavanja: uMjesecu(2, 3),
        datumDospijeca: uMjesecu(2, 20),
        placeno: true,
      ),
      Racun(
        kategorija: Kategorija.internet,
        provajder: 'BH Telecom',
        iznos: 45.00,
        datumIzdavanja: uMjesecu(2, 1),
        datumDospijeca: uMjesecu(2, 15),
        placeno: true,
      ),
    ];

    for (final r in primjeri) {
      await _baza.dodajRacun(r);
    }
  }

  /// Dodaje novi račun i osvježava listu.
  Future<void> dodajRacun(Racun racun) async {
    final id = await _baza.dodajRacun(racun);
    _racuni = [..._racuni, racun.copyWith(id: id)];
    _sortiraj();
    notifyListeners();
  }

  /// Ažurira postojeći račun.
  Future<void> azurirajRacun(Racun racun) async {
    await _baza.azurirajRacun(racun);
    final indeks = _racuni.indexWhere((r) => r.id == racun.id);
    if (indeks != -1) {
      _racuni[indeks] = racun;
      _sortiraj();
      notifyListeners();
    }
  }

  /// Briše račun po ID-u.
  Future<void> obrisiRacun(int id) async {
    await _baza.obrisiRacun(id);
    _racuni = _racuni.where((r) => r.id != id).toList();
    notifyListeners();
  }

  /// Mijenja status plaćanja računa (plaćeno / nije plaćeno).
  Future<void> promijeniStatusPlacanja(Racun racun) async {
    await azurirajRacun(racun.copyWith(placeno: !racun.placeno));
  }

  void _sortiraj() {
    _racuni.sort((a, b) => b.datumDospijeca.compareTo(a.datumDospijeca));
  }

  // ----- Statistike za dashboard i grafove -----

  /// Računi koji pripadaju datom mjesecu i godini.
  List<Racun> racuniZaMjesec(int godina, int mjesec) {
    return _racuni
        .where((r) =>
            r.datumIzdavanja.year == godina &&
            r.datumIzdavanja.month == mjesec)
        .toList();
  }

  /// Ukupan iznos svih računa za dati mjesec.
  double ukupnoZaMjesec(int godina, int mjesec) {
    return racuniZaMjesec(godina, mjesec)
        .fold(0.0, (zbir, r) => zbir + r.iznos);
  }

  /// Ukupan iznos svih neplaćenih računa.
  double get ukupnoNeplaceno {
    return _racuni
        .where((r) => !r.placeno)
        .fold(0.0, (zbir, r) => zbir + r.iznos);
  }

  /// Broj neplaćenih računa.
  int get brojNeplacenih => _racuni.where((r) => !r.placeno).length;

  /// Računi koji kasne (rok prošao, nisu plaćeni).
  List<Racun> get racuniKojiKasne =>
      _racuni.where((r) => r.kasni).toList();

  /// Nadolazeći neplaćeni računi, sortirani po roku (najbliži prvo).
  List<Racun> get nadolazeci {
    final lista = _racuni.where((r) => !r.placeno).toList();
    lista.sort((a, b) => a.datumDospijeca.compareTo(b.datumDospijeca));
    return lista;
  }

  /// Zbir iznosa po kategoriji za dati mjesec (za pie chart).
  Map<Kategorija, double> potrosnjaPoKategoriji(int godina, int mjesec) {
    final mapa = <Kategorija, double>{};
    for (final r in racuniZaMjesec(godina, mjesec)) {
      mapa[r.kategorija] = (mapa[r.kategorija] ?? 0) + r.iznos;
    }
    return mapa;
  }

  /// Ukupna potrošnja po mjesecima za zadnjih [brojMjeseci] mjeseci.
  ///
  /// Vraća listu parova (oznaka mjeseca, ukupan iznos), od najstarijeg
  /// prema najnovijem - spremno za bar/line chart.
  List<MjesecnaPotrosnja> potrosnjaPoMjesecima({int brojMjeseci = 6}) {
    final sada = DateTime.now();
    final rezultat = <MjesecnaPotrosnja>[];

    for (int i = brojMjeseci - 1; i >= 0; i--) {
      final datum = DateTime(sada.year, sada.month - i, 1);
      final iznos = ukupnoZaMjesec(datum.year, datum.month);
      rezultat.add(MjesecnaPotrosnja(
        godina: datum.year,
        mjesec: datum.month,
        iznos: iznos,
      ));
    }
    return rezultat;
  }
}

/// Potrošnja za jedan mjesec - koristi se u grafovima.
class MjesecnaPotrosnja {
  final int godina;
  final int mjesec;
  final double iznos;

  const MjesecnaPotrosnja({
    required this.godina,
    required this.mjesec,
    required this.iznos,
  });

  /// Kratka oznaka mjeseca na bosanskom (npr. "Maj").
  String get kratkiNaziv {
    const nazivi = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Maj',
      'Jun',
      'Jul',
      'Avg',
      'Sep',
      'Okt',
      'Nov',
      'Dec',
    ];
    return nazivi[mjesec - 1];
  }
}
