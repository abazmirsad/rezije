import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za Telemach BH račune (internet + TV).
///
/// Prilagođen tekstu koji izvlači `syncfusion_flutter_pdf`: labela i
/// vrijednost su u odvojenim redovima, npr:
///   "Poziv na broj:"  (red)
///   "650564246202609" (sljedeći red)
/// a stavke računa su svaka u svom redu (zadnji broj = ukupno s PDV-om).
class TelemachParser {
  /// Da li tekst izgleda kao Telemach račun.
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    return t.contains('telemach') || t.contains('eon full');
  }

  /// Parsira tekst Telemach računa u [Racun].
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

    // Vrijednost koja slijedi poslije labele. U syncfusion formatu je
    // labela u svom redu (završava s ":"), a vrijednost u sljedećem.
    String? vrijednostPoslije(String labelaRegex) {
      final re = RegExp(labelaRegex, caseSensitive: false);
      for (int i = 0; i < linije.length; i++) {
        if (re.hasMatch(linije[i])) {
          // Ako iza dvotačke na ISTOM redu ima pravog sadržaja, uzmi to.
          final idx = linije[i].indexOf(':');
          if (idx >= 0 && idx < linije[i].length - 1) {
            final naIstom = linije[i].substring(idx + 1).trim();
            if (naIstom.isNotEmpty) return naIstom;
          }
          // Inače vrijednost je u sljedećem ne-praznom redu.
          if (i + 1 < linije.length) return linije[i + 1].trim();
        }
      }
      return null;
    }

    // --- Poziv na broj (npr. 650564246202609) ---
    String pozivNaBroj = '';
    final poz = vrijednostPoslije(r'^poziv\s*na\s*broj\s*:?$');
    if (poz != null) {
      final m = RegExp(r'\d{10,}').firstMatch(poz);
      if (m != null) pozivNaBroj = m.group(0)!;
    }
    // Rezervno: nađi prvi 15-cifreni broj u tekstu.
    if (pozivNaBroj.isEmpty) {
      final m = RegExp(r'\b\d{15}\b').firstMatch(tekst);
      if (m != null) pozivNaBroj = m.group(0)!;
    }
    if (pozivNaBroj.isEmpty) upozorenja.add('Nije pronađen poziv na broj.');

    // --- Period izvršenja usluga: 01.09.2026 - 30.09.2026 ---
    DateTime? periodOd;
    DateTime? periodDo;
    final per = vrijednostPoslije(r'period\s*izvr');
    if (per != null) {
      final m = RegExp(
        r'(\d{1,2}\.\d{1,2}\.\d{4})\s*[-–]\s*(\d{1,2}\.\d{1,2}\.\d{4})',
      ).firstMatch(per);
      if (m != null) {
        periodOd = _datum(m.group(1)!);
        periodDo = _datum(m.group(2)!);
      }
    }

    // --- Rok za plaćanje računa: 25.10.2026 ---
    DateTime? datumDospijeca;
    final rok = vrijednostPoslije(r'rok\s*za\s*pla');
    if (rok != null) datumDospijeca = _datum(rok);

    // --- Datum izdavanja računa: 30.09.2026 ---
    DateTime? datumIzdavanja;
    final izd = vrijednostPoslije(r'datum\s*izdavanja');
    if (izd != null) datumIzdavanja = _datum(izd);

    // --- Mjesečni iznos: red "Račun za <MJESEC>" pa 3 reda s brojevima.
    //     Treći broj poslije labele je ukupno s PDV-om (npr. 80,45). ---
    double? mjesecniIznos;
    for (int i = 0; i < linije.length; i++) {
      if (RegExp(r'ra[cč]un\s*za\s+[a-zžčćđš]', caseSensitive: false)
          .hasMatch(linije[i])) {
        // Skupi iduće redove koji su čisti novčani iznosi.
        final iznosi = <double>[];
        for (int j = i + 1; j < linije.length && iznosi.length < 3; j++) {
          final b = _novac(linije[j]);
          if (b != null) {
            iznosi.add(b);
          } else {
            break; // prekini na prvom ne-novčanom redu
          }
        }
        if (iznosi.isNotEmpty) mjesecniIznos = iznosi.last;
        break;
      }
    }
    if (mjesecniIznos == null) {
      upozorenja.add('Nije pronađen mjesečni iznos - unesite ručno.');
    }

    // --- Ukupno za uplatu (dug ili pretplata) ---
    // Ako postoji "Prethodno dugovanje", za uplatu = mjesečni + dug.
    // Inače ostaje null (koristi se mjesečni iznos).
    double? iznosZaUplatu;
    for (int i = 0; i < linije.length; i++) {
      if (RegExp(r'prethodno\s*dugovanje', caseSensitive: false)
          .hasMatch(linije[i])) {
        // Iznos duga je u ovom ili sljedećem redu.
        double? dug = _novac(linije[i]);
        if (dug == null && i + 1 < linije.length) {
          dug = _novac(linije[i + 1]);
        }
        if (dug != null && mjesecniIznos != null) {
          iznosZaUplatu = mjesecniIznos + dug;
        }
        break;
      }
    }

    if (mjesecniIznos == null && datumIzdavanja == null) {
      return RezultatParsiranja.neuspjeh(
        'Ovo ne izgleda kao prepoznatljiv Telemach račun.',
      );
    }

    datumIzdavanja ??= periodDo ?? DateTime.now();
    datumDospijeca ??= datumIzdavanja.add(const Duration(days: 25));

    final racun = Racun(
      kategorija: Kategorija.internet,
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

  /// Pretvara string u double (bosanski zarez: "80,45").
  static double? _broj(String s) {
    final o = s.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(o);
  }

  /// Vraća iznos SAMO ako je cijeli red čist novčani iznos (npr. "80,45").
  static double? _novac(String red) {
    final t = red.trim();
    if (RegExp(r'^\d{1,3}(?:\.\d{3})*,\d{2}$').hasMatch(t)) {
      return _broj(t);
    }
    return null;
  }
}
