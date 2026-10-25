import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za Sarajevogas račune (prirodni gas / grijanje).
///
/// Radi nad tekstom izvučenim iz PDF-a. Prepoznatljive oznake:
/// "RAČUN ZA PRIRODNI GAS", "Obračunski period", red
/// "Ukupan iznos računa (8 + 9+ 10) <iznos>", i saldo red
/// "Novi saldo Ukupna preplata/dugovanje <iznos>".
///
/// Napomena: Sarajevogas koristi TAČKU kao decimalni separator (18.55),
/// za razliku od Telemacha koji koristi zarez (80,45).
class SarajevogasParser {
  /// Da li tekst izgleda kao Sarajevogas račun.
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    return t.contains('sarajevogas') ||
        t.contains('prirodni gas') ||
        t.contains('sarajevogas.ba');
  }

  /// Parsira tekst Sarajevogas računa u [Racun].
  static RezultatParsiranja parsiraj(String tekst) {
    if (tekst.trim().isEmpty) {
      return RezultatParsiranja.neuspjeh('PDF ne sadrži čitljiv tekst.');
    }

    final upozorenja = <String>[];
    final linije = tekst
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final spojeno = linije.join('\n');

    // --- Referenca / poziv na broj: "Račun broj: 03-508055/26" ---
    String pozivNaBroj = '';
    final mRef = RegExp(
      r'ra[cč]un\s*broj\s*:?\s*([0-9]{2}-[0-9]{4,}/[0-9]{2})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mRef != null) {
      pozivNaBroj = mRef.group(1)!.trim();
    } else {
      // Rezervno: red "REFERENCA" blizu broja oblika 03-xxxxxx/26.
      final mAlt = RegExp(r'([0-9]{2}-[0-9]{4,}/[0-9]{2})').firstMatch(spojeno);
      if (mAlt != null) pozivNaBroj = mAlt.group(1)!.trim();
    }

    // --- Obračunski period: 30.06.2026 - 31.07.2026 ---
    DateTime? periodOd;
    DateTime? periodDo;
    final mPeriod = RegExp(
      r'obra[cč]unski\s*period\s*:?\s*(\d{1,2}\.\d{1,2}\.\d{4})\.?\s*[-–]\s*(\d{1,2}\.\d{1,2}\.\d{4})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mPeriod != null) {
      periodOd = _datum(mPeriod.group(1)!);
      periodDo = _datum(mPeriod.group(2)!);
    } else {
      upozorenja.add('Nije pronađen obračunski period.');
    }

    // --- Datum izdavanja računa: 31.07.2026 ---
    DateTime? datumIzdavanja;
    final mIzd = RegExp(
      r'datum\s*izdavanja[^\n]*?(\d{1,2}\.\d{1,2}\.\d{4})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mIzd != null) {
      datumIzdavanja = _datum(mIzd.group(1)!);
    }

    // --- Mjesečni iznos: red "Ukupan iznos računa (8 + 9+ 10) 18.55" ---
    double? mjesecniIznos;
    for (final l in linije) {
      if (RegExp(r'ukupan\s*iznos\s*ra[cč]una', caseSensitive: false)
          .hasMatch(l)) {
        final brojevi = _sviBrojevi(l);
        if (brojevi.isNotEmpty) {
          mjesecniIznos = brojevi.last; // zadnji broj u redu = ukupan iznos
          break;
        }
      }
    }
    if (mjesecniIznos == null) {
      upozorenja.add('Nije pronađen mjesečni iznos - unesite ručno.');
    }

    // --- Saldo (preplata ili dugovanje): "Novi saldo Ukupna preplata 54.96" ---
    // iznosZaUplatu računamo tako da:
    //   - preplata >= mjesečni  -> za uplatu 0 (pokriveno pretplatom)
    //   - inače za uplatu = mjesečni - preplata (ili + dugovanje)
    double? iznosZaUplatu;
    final mSaldo = RegExp(
      r'novi\s*saldo[^\n]*?(preplata|dugovanje)[^\n]*?(\d+[.,]\d{2})',
      caseSensitive: false,
    ).firstMatch(spojeno);
    if (mSaldo != null && mjesecniIznos != null) {
      final vrsta = mSaldo.group(1)!.toLowerCase();
      final saldo = _broj(mSaldo.group(2)!) ?? 0;
      if (vrsta.contains('preplata')) {
        // Novi saldo je preplata NAKON ovog računa -> za uplatu 0.
        iznosZaUplatu = 0.0;
      } else {
        // Dugovanje -> za uplatu = mjesečni + dug.
        iznosZaUplatu = mjesecniIznos + saldo;
      }
    }

    if (mjesecniIznos == null && datumIzdavanja == null) {
      return RezultatParsiranja.neuspjeh(
        'Ovo ne izgleda kao prepoznatljiv Sarajevogas račun. '
        'Provjerite PDF ili unesite podatke ručno.',
      );
    }

    datumIzdavanja ??= periodDo ?? DateTime.now();
    // Rok plaćanja: 15 dana od datuma izdavanja.
    final datumDospijeca = datumIzdavanja.add(const Duration(days: 15));

    final racun = Racun(
      kategorija: Kategorija.grijanje, // prirodni gas = grijanje
      provajder: 'Sarajevogas',
      iznos: mjesecniIznos ?? 0,
      datumIzdavanja: datumIzdavanja,
      datumDospijeca: datumDospijeca,
      pozivNaBroj: pozivNaBroj,
      periodOd: periodOd,
      periodDo: periodDo,
      iznosZaUplatu: iznosZaUplatu,
      biljeska: 'Uvezeno iz PDF-a (Sarajevogas)',
    );

    return RezultatParsiranja.jedan(racun, upozorenja: upozorenja);
  }

  // ----- Pomoćne funkcije -----

  static DateTime? _datum(String s) {
    final m = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(s);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
    );
  }

  /// Pretvara string u double. Sarajevogas koristi tačku (18.55),
  /// ali tolerišemo i zarez za svaki slučaj.
  static double? _broj(String s) {
    var o = s.trim();
    // Ako ima i tačku i zarez, zarez je hiljade -> ukloni ga.
    if (o.contains('.') && o.contains(',')) {
      o = o.replaceAll(',', '');
    } else {
      o = o.replaceAll(',', '.');
    }
    return double.tryParse(o);
  }

  /// Nalazi sve brojeve s 2 decimale (npr. "18.55", "3.40").
  static List<double> _sviBrojevi(String s) {
    final rezultat = <double>[];
    for (final m in RegExp(r'\d+[.,]\d{2}').allMatches(s)) {
      final b = _broj(m.group(0)!);
      if (b != null) rezultat.add(b);
    }
    return rezultat;
  }
}
