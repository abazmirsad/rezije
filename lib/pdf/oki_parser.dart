import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za OKI Upravitelj račune (održavanje zgrade / etažni vlasnik).
///
/// Specifičnost: JEDAN PDF sadrži VIŠE mjesečnih uplatnica (npr. 3
/// mjeseca odjednom). Svaka uplatnica ima:
///   - oznaku mjeseca/godine "MM/YY" (npr. "10/26")
///   - poziv na broj oblika "XXXXXXXX-MMYY-NNNNNN" (npr. 12125324-1026-217862)
///   - iznos "15,00" (Naknada + Porez + Održavanje)
///
/// Parser vraća po jedan [Racun] za svaki mjesec.
class OkiParser {
  /// Da li tekst izgleda kao OKI uplatnica.
  ///
  /// U PDF-u nema riječi "OKI", pa prepoznajemo po kombinaciji
  /// "Održavanje" + "Naknada" + poziv na broj oblika 8cifara-4cifre-6cifara.
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    final imaPoziv = RegExp(r'\d{8}-\d{4}-\d{6}').hasMatch(tekst);
    return imaPoziv &&
        t.contains('odr') && // "Održavanje" (tolerantno na dekodiranje slova)
        t.contains('naknada');
  }

  /// Parsira sve mjesečne uplatnice iz OKI PDF-a.
  static RezultatParsiranja parsiraj(String tekst) {
    if (tekst.trim().isEmpty) {
      return RezultatParsiranja.neuspjeh('PDF ne sadrži čitljiv tekst.');
    }

    // Svaki blok je obilježen jedinstvenim pozivom na broj
    // oblika XXXXXXXX-MMYY-NNNNNN. Iz njega izvlačimo mjesec i godinu.
    final pozivi = RegExp(r'(\d{8})-(\d{2})(\d{2})-(\d{6})').allMatches(tekst);

    final racuni = <Racun>[];
    final vidjeni = <String>{}; // da izbjegnemo duplikate (poziv se ponavlja)

    for (final m in pozivi) {
      final pozivNaBroj = m.group(0)!;
      if (vidjeni.contains(pozivNaBroj)) continue;
      vidjeni.add(pozivNaBroj);

      final mjesec = int.parse(m.group(2)!);
      final godina2 = int.parse(m.group(3)!);
      final godina = 2000 + godina2;

      // Iznos: tražimo "15,00" u blizini ovog poziva. Pošto su svi iznosi
      // jednaki i stoje uz blok, uzimamo prvi novčani iznos poslije poziva.
      final iznos = _iznosUzBlok(tekst, m.end);

      // Datumi: period je cijeli taj mjesec; rok = kraj mjeseca.
      final periodOd = DateTime(godina, mjesec, 1);
      final periodDo = DateTime(godina, mjesec + 1, 0); // zadnji dan mjeseca
      final datumIzdavanja = periodOd;
      final datumDospijeca = periodDo;

      racuni.add(Racun(
        kategorija: Kategorija.komunalije, // održavanje zgrade
        provajder: 'OKI Upravitelj',
        iznos: iznos ?? 0,
        datumIzdavanja: datumIzdavanja,
        datumDospijeca: datumDospijeca,
        pozivNaBroj: pozivNaBroj,
        periodOd: periodOd,
        periodDo: periodDo,
        biljeska: 'Uvezeno iz PDF-a (OKI, održavanje)',
      ));
    }

    if (racuni.isEmpty) {
      return RezultatParsiranja.neuspjeh(
        'Nije pronađena nijedna OKI uplatnica u PDF-u.',
      );
    }

    final upozorenja = <String>[];
    if (racuni.any((r) => r.iznos == 0)) {
      upozorenja.add('Za neke mjesece iznos nije pročitan - provjerite.');
    }

    return RezultatParsiranja.vise(racuni, upozorenja: upozorenja);
  }

  /// Nalazi prvi novčani iznos (npr. "15,00") poslije date pozicije.
  static double? _iznosUzBlok(String tekst, int odPozicije) {
    final dio = tekst.substring(odPozicije);
    final m = RegExp(r'(\d{1,3}(?:\.\d{3})*,\d{2})').firstMatch(dio);
    if (m == null) return null;
    return _broj(m.group(1)!);
  }

  static double? _broj(String s) {
    final ocisceno = s.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(ocisceno);
  }
}
