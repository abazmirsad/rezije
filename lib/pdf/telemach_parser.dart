import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za Telemach BH račune (internet + TV).
///
/// Radi nad tekstom izvučenim iz PDF-a. Telemach račun ima prepoznatljive
/// oznake ("Poziv na broj", "Period izvršenja usluga", "Rok za plaćanje",
/// red "Račun za <MJESEC>" s iznosom). Parser je napisan tolerantno jer
/// različite PDF biblioteke mogu malo drugačije dekodirati slova i razmake.
class TelemachParser {
  /// Da li tekst izgleda kao Telemach račun.
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    return t.contains('telemach') ||
        t.contains('billbymail.telemach') ||
        (t.contains('poziv na broj') && t.contains('eon'));
  }

  /// Parsira tekst Telemach računa u [Racun].
  static RezultatParsiranja parsiraj(String tekst) {
    if (tekst.trim().isEmpty) {
      return RezultatParsiranja.neuspjeh('PDF ne sadrži čitljiv tekst.');
    }

    final upozorenja = <String>[];

    // Normalizuj: jedinstveni razmaci, ali zadrži nove redove.
    final linije = tekst
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final spojeno = linije.join('\n');

    // --- Poziv na broj (15 cifara, npr. 650564246202609) ---
    String pozivNaBroj = '';
    final mPoziv = RegExp(
      r'poziv\s*na\s*broj\s*:?\s*([0-9]{6,})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mPoziv != null) {
      pozivNaBroj = mPoziv.group(1)!.trim();
    } else {
      upozorenja.add('Nije pronađen "Poziv na broj".');
    }

    // --- Period izvršenja usluga: 01.09.2026 - 30.09.2026 ---
    DateTime? periodOd;
    DateTime? periodDo;
    final mPeriod = RegExp(
      r'period[^\n:]*:?\s*(\d{1,2}\.\d{1,2}\.\d{4})\.?\s*[-–]\s*(\d{1,2}\.\d{1,2}\.\d{4})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mPeriod != null) {
      periodOd = _datum(mPeriod.group(1)!);
      periodDo = _datum(mPeriod.group(2)!);
    } else {
      upozorenja.add('Nije pronađen "Period izvršenja usluga".');
    }

    // --- Rok za plaćanje računa: 25.10.2026 ---
    DateTime? datumDospijeca;
    final mRok = RegExp(
      r'rok\s*za\s*pla[cć]anje[^\n]*?(\d{1,2}\.\d{1,2}\.\d{4})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mRok != null) {
      datumDospijeca = _datum(mRok.group(1)!);
    }

    // --- Datum izdavanja računa: 30.09.2026 ---
    DateTime? datumIzdavanja;
    final mIzdavanje = RegExp(
      r'datum\s*izdavanja[^\n]*?(\d{1,2}\.\d{1,2}\.\d{4})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mIzdavanje != null) {
      datumIzdavanja = _datum(mIzdavanje.group(1)!);
    }

    // --- Mjesečni iznos: red "Račun za <MJESEC> ... <iznos>" ---
    // Format reda: "Račun za SEPTEMBAR 68,76 11,69 80,45"
    // Uzimamo zadnji broj U TOM REDU (ukupno s PDV-om).
    double? mjesecniIznos;
    int indeksRacunZa = -1;
    for (int i = 0; i < linije.length; i++) {
      if (RegExp(r'ra[cč]un\s*za\s+[a-zžčćđš]', caseSensitive: false)
          .hasMatch(linije[i])) {
        indeksRacunZa = i;
        final brojevi = _sviBrojevi(linije[i]);
        if (brojevi.isNotEmpty) {
          mjesecniIznos = brojevi.last; // zadnji broj u redu = ukupno s PDV-om
        }
        break;
      }
    }
    if (mjesecniIznos == null) {
      upozorenja.add('Nije pronađen mjesečni iznos - unesite ručno.');
    }

    // --- Ukupno za uplatu (trenutno stanje: dug ili pretplata) ---
    // Na Telemach računu iznos za uplatu NEMA labelu - to je "goli" novčani
    // iznos koji stoji sam u svom redu, prvi POSLIJE reda "Račun za ...".
    // Red "Prethodno dugovanje ..." se preskače (to je dug, ne ukupno).
    // Primjeri: septembar -> "0,00"; juli -> "241,35" (80,45 + 160,90 duga).
    double? iznosZaUplatu;
    if (indeksRacunZa >= 0) {
      for (int i = indeksRacunZa + 1;
          i < linije.length && i <= indeksRacunZa + 4;
          i++) {
        final l = linije[i];
        if (l.toLowerCase().contains('dugovanje')) continue;
        if (RegExp(r'^\d{1,3}(?:\.\d{3})*,\d{2}$').hasMatch(l)) {
          iznosZaUplatu = _broj(l);
          break;
        }
      }
    }

    // Ako nemamo ni mjesečni iznos ni datume, parsiranje nije uspjelo.
    if (mjesecniIznos == null && datumIzdavanja == null) {
      return RezultatParsiranja.neuspjeh(
        'Ovo ne izgleda kao prepoznatljiv Telemach račun. '
        'Provjerite PDF ili unesite podatke ručno.',
      );
    }

    // Razumne zamjene za datume koji nedostaju.
    datumIzdavanja ??= periodDo ?? DateTime.now();
    datumDospijeca ??= datumIzdavanja.add(const Duration(days: 25));

    final racun = Racun(
      kategorija: Kategorija.internet, // Telemach = internet + TV
      provajder: 'Telemach',
      iznos: mjesecniIznos ?? 0,
      datumIzdavanja: datumIzdavanja,
      datumDospijeca: datumDospijeca,
      pozivNaBroj: pozivNaBroj,
      periodOd: periodOd,
      periodDo: periodDo,
      iznosZaUplatu: iznosZaUplatu,
      biljeska: 'Uvezeno iz PDF-a (Telemach)',
    );

    return RezultatParsiranja(
      racun: racun,
      upozorenja: upozorenja,
      uspjeh: true,
    );
  }

  // ----- Pomoćne funkcije -----

  /// Parsira datum formata "dd.mm.yyyy".
  static DateTime? _datum(String s) {
    final m = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(s);
    if (m == null) return null;
    final dan = int.parse(m.group(1)!);
    final mjesec = int.parse(m.group(2)!);
    final godina = int.parse(m.group(3)!);
    return DateTime(godina, mjesec, dan);
  }

  /// Pretvara string s bosanskim decimalnim zarezom ("80,45") u double.
  static double? _broj(String s) {
    final ocisceno = s.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(ocisceno);
  }

  /// Nalazi sve novčane brojeve (npr. "68,76", "11,69", "80,45") u tekstu.
  static List<double> _sviBrojevi(String s) {
    final rezultat = <double>[];
    for (final m in RegExp(r'\d{1,3}(?:\.\d{3})*,\d{2}').allMatches(s)) {
      final b = _broj(m.group(0)!);
      if (b != null) rezultat.add(b);
    }
    return rezultat;
  }
}
