import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za Sarajevogas račune (prirodni gas / grijanje).
///
/// Prilagođen syncfusion formatu: labela i vrijednost su u odvojenim
/// redovima. Decimalni separator je TAČKA (18.55).
class SarajevogasParser {
  /// Da li tekst izgleda kao Sarajevogas račun.
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    return t.contains('sarajevogas') || t.contains('prirodni gas');
  }

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

    /// Vrijednost u redu poslije labele (ili na istom redu poslije ":").
    String? vrijednostPoslije(String labelaRegex) {
      final re = RegExp(labelaRegex, caseSensitive: false);
      for (int i = 0; i < linije.length; i++) {
        if (re.hasMatch(linije[i])) {
          final idx = linije[i].indexOf(':');
          if (idx >= 0 && idx < linije[i].length - 1) {
            final naIstom = linije[i].substring(idx + 1).trim();
            if (naIstom.isNotEmpty) return naIstom;
          }
          if (i + 1 < linije.length) return linije[i + 1].trim();
        }
      }
      return null;
    }

    // --- Referenca / poziv na broj: "03-508055/26" ---
    String pozivNaBroj = '';
    final mRef = RegExp(r'\b(\d{2}-\d{4,}/\d{2})\b').firstMatch(tekst);
    if (mRef != null) pozivNaBroj = mRef.group(1)!;

    // --- Obračunski period: 30.06.2026 - 31.07.2026 ---
    DateTime? periodOd;
    DateTime? periodDo;
    final per = vrijednostPoslije(r'obra[cč]unski\s*period');
    if (per != null) {
      final m = RegExp(
        r'(\d{1,2}\.\d{1,2}\.\d{4})\s*[-–]\s*(\d{1,2}\.\d{1,2}\.\d{4})',
      ).firstMatch(per);
      if (m != null) {
        periodOd = _datum(m.group(1)!);
        periodDo = _datum(m.group(2)!);
      }
    }
    if (periodOd == null) upozorenja.add('Nije pronađen obračunski period.');

    // --- Datum izdavanja računa: 31.07.2026 ---
    DateTime? datumIzdavanja;
    final izd = vrijednostPoslije(r'datum\s*izdavanja');
    if (izd != null) datumIzdavanja = _datum(izd);

    // --- Mjesečni iznos: red "Ukupan iznos računa (8 + 9+ 10)" pa iznos ---
    double? mjesecniIznos;
    for (int i = 0; i < linije.length; i++) {
      if (RegExp(r'ukupan\s*iznos\s*ra[cč]una', caseSensitive: false)
          .hasMatch(linije[i])) {
        // Iznos je na istom redu ili u sljedećem.
        mjesecniIznos = _brojUTacki(linije[i]);
        if (mjesecniIznos == null && i + 1 < linije.length) {
          mjesecniIznos = _brojUTacki(linije[i + 1]);
        }
        if (mjesecniIznos != null) break;
      }
    }
    if (mjesecniIznos == null) {
      upozorenja.add('Nije pronađen mjesečni iznos - unesite ručno.');
    }

    // --- Saldo: "Novi saldo" -> "Ukupna preplata/dugovanje" -> iznos ---
    double? iznosZaUplatu;
    for (int i = 0; i < linije.length; i++) {
      if (RegExp(r'novi\s*saldo', caseSensitive: false)
          .hasMatch(linije[i])) {
        // Potraži "preplata"/"dugovanje" i iznos u narednih par redova.
        bool preplata = false;
        bool dugovanje = false;
        double? saldo;
        for (int j = i; j < linije.length && j <= i + 4; j++) {
          final lj = linije[j].toLowerCase();
          if (lj.contains('preplata')) preplata = true;
          if (lj.contains('dugovanje')) dugovanje = true;
          final b = _brojUTacki(linije[j]);
          if (b != null && saldo == null && j > i) saldo = b;
        }
        if (mjesecniIznos != null) {
          if (preplata) {
            iznosZaUplatu = 0.0; // pokriveno pretplatom
          } else if (dugovanje && saldo != null) {
            iznosZaUplatu = mjesecniIznos + saldo;
          }
        }
        break;
      }
    }

    if (mjesecniIznos == null && datumIzdavanja == null) {
      return RezultatParsiranja.neuspjeh(
        'Ovo ne izgleda kao prepoznatljiv Sarajevogas račun.',
      );
    }

    datumIzdavanja ??= periodDo ?? DateTime.now();
    final datumDospijeca = datumIzdavanja.add(const Duration(days: 15));

    final racun = Racun(
      kategorija: Kategorija.grijanje,
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

  /// Vraća broj SAMO ako je cijeli red čist iznos s tačkom (npr. "18.55").
  static double? _brojUTacki(String red) {
    final t = red.trim();
    final m = RegExp(r'^(\d+\.\d{2})$').firstMatch(t);
    if (m != null) return double.tryParse(m.group(1)!);
    return null;
  }
}
