import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za Elektroprivreda BiH račune (struja).
///
/// VAŽNO: cijena računa je "Iznos računa sa PDV" (npr. 39.36), a NE
/// "UKUPNO" (npr. 46.86) jer UKUPNO uključuje "Taksa iz Zakona o JS"
/// (7.50) koja se ne mora platiti.
///
/// Prilagođen syncfusion formatu. Decimalni separator je TAČKA.
class StrujaParser {
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    return t.contains('elektroprivreda') ||
        t.contains('elektri') && t.contains('energij') ||
        t.contains('epbih');
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

    // --- Referenca / poziv na broj: "40406-047504-29076" ---
    String pozivNaBroj = '';
    final mRef = RegExp(r'\b(\d{5}-\d{6}-\d{4,5})\b').firstMatch(tekst);
    if (mRef != null) pozivNaBroj = mRef.group(1)!;

    // --- Datumi (format "dd.mm.yyyy." s tačkom na kraju) ---
    DateTime? periodOd;
    DateTime? periodDo;
    DateTime? datumIzdavanja;
    DateTime? datumDospijeca;

    for (int i = 0; i < linije.length; i++) {
      final l = linije[i];
      final lower = l.toLowerCase();

      if (periodOd == null && lower.contains('obra') && lower.contains('period')) {
        final m = RegExp(
          r'(\d{1,2}\.\d{1,2}\.\d{4})\.?\s*[-–]\s*(\d{1,2}\.\d{1,2}\.\d{4})',
        ).firstMatch('$l ${i + 1 < linije.length ? linije[i + 1] : ""}');
        if (m != null) {
          periodOd = _datum(m.group(1)!);
          periodDo = _datum(m.group(2)!);
        }
      }
      if (datumIzdavanja == null && lower.contains('datum izdavanja')) {
        datumIzdavanja = _datumURedu(l) ??
            (i + 1 < linije.length ? _datumURedu(linije[i + 1]) : null);
      }
      if (datumDospijeca == null &&
          lower.contains('rok') &&
          lower.contains('pla')) {
        datumDospijeca = _datumURedu(l) ??
            (i + 1 < linije.length ? _datumURedu(linije[i + 1]) : null);
      }
    }

    // --- Iznos: red "Iznos računa sa PDV" -> iznos (NE "UKUPNO") ---
    double? iznos;
    for (int i = 0; i < linije.length; i++) {
      final lower = linije[i].toLowerCase();
      // "sa pdv" (tolerantno; syncfusion zna prelomiti "PD\nV")
      if (lower.contains('iznos ra') &&
          (lower.contains('sa pdv') || lower.contains('sa pd'))) {
        iznos = _brojUTacki(linije[i]);
        // Iznos može biti na istom redu (na kraju) ili sljedećem.
        iznos ??= _zadnjiBrojUTacki(linije[i]);
        if (iznos == null && i + 1 < linije.length) {
          iznos = _brojUTacki(linije[i + 1]) ?? _zadnjiBrojUTacki(linije[i + 1]);
        }
        if (iznos != null) break;
      }
    }
    if (iznos == null) {
      upozorenja.add('Nije pronađen "Iznos računa sa PDV" - unesite ručno.');
    }

    if (iznos == null && datumIzdavanja == null && pozivNaBroj.isEmpty) {
      return RezultatParsiranja.neuspjeh(
        'Ovo ne izgleda kao prepoznatljiv račun za struju.',
      );
    }

    datumIzdavanja ??= periodDo ?? DateTime.now();
    datumDospijeca ??= datumIzdavanja.add(const Duration(days: 15));

    final racun = Racun(
      kategorija: Kategorija.struja,
      provajder: 'Elektroprivreda',
      iznos: iznos ?? 0,
      datumIzdavanja: datumIzdavanja,
      datumDospijeca: datumDospijeca,
      pozivNaBroj: pozivNaBroj,
      periodOd: periodOd,
      periodDo: periodDo,
      // iznosZaUplatu ostaje null -> za uplatu = iznos (sa PDV, bez takse).
      biljeska: 'Uvezeno iz PDF-a (Elektroprivreda, bez takse)',
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

  /// Nalazi prvi datum "dd.mm.yyyy" bilo gdje u redu.
  static DateTime? _datumURedu(String red) {
    final m = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4})').firstMatch(red);
    return m == null ? null : _datum(m.group(1)!);
  }

  /// Vraća broj ako je cijeli red čist iznos s tačkom (npr. "39.36").
  static double? _brojUTacki(String red) {
    final t = red.trim();
    final m = RegExp(r'^(\d+\.\d{2})$').firstMatch(t);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  /// Vraća ZADNJI iznos s tačkom u redu (za slučaj "Iznos ... sa PDV 39.36").
  static double? _zadnjiBrojUTacki(String red) {
    final svi = RegExp(r'(\d+\.\d{2})').allMatches(red).toList();
    if (svi.isEmpty) return null;
    return double.tryParse(svi.last.group(1)!);
  }
}
