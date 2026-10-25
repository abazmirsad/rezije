import '../models/kategorija.dart';
import '../models/racun.dart';
import 'rezultat_parsiranja.dart';

/// Parser za OKI Upravitelj račune (održavanje zgrade / etažni vlasnik).
///
/// JEDAN PDF sadrži VIŠE mjesečnih uplatnica (npr. 3 mjeseca).
/// Svaka uplatnica ima:
///   - poziv na broj oblika "XXXXXXXX-MMYY-NNNNNN" (12125324-1026-217862)
///   - ukupan iznos "15,00" (format s TAČNO 2 decimale)
/// Stavke "Naknada 1,8000", "Porez 0,3060", "Održavanje 12,8940" imaju
/// 4 decimale i NE smiju se uzeti kao iznos.
class OkiParser {
  static bool prepoznaje(String tekst) {
    final t = tekst.toLowerCase();
    final imaPoziv = RegExp(r'\d{8}-\d{4}-\d{6}').hasMatch(tekst);
    return imaPoziv && (t.contains('odr') && t.contains('naknada'));
  }

  static RezultatParsiranja parsiraj(String tekst) {
    if (tekst.trim().isEmpty) {
      return RezultatParsiranja.neuspjeh('PDF ne sadrži čitljiv tekst.');
    }

    // Jedinstveni pozivi na broj (svaki se ponavlja, uzimamo jednom).
    final pozivi = RegExp(r'(\d{8})-(\d{2})(\d{2})-(\d{6})').allMatches(tekst);

    final racuni = <Racun>[];
    final vidjeni = <String>{};

    for (final m in pozivi) {
      final pozivNaBroj = m.group(0)!;
      if (vidjeni.contains(pozivNaBroj)) continue;
      vidjeni.add(pozivNaBroj);

      final mjesec = int.parse(m.group(2)!);
      final godina = 2000 + int.parse(m.group(3)!);

      final periodOd = DateTime(godina, mjesec, 1);
      final periodDo = DateTime(godina, mjesec + 1, 0); // zadnji dan mjeseca

      racuni.add(Racun(
        kategorija: Kategorija.komunalije,
        provajder: 'OKI Upravitelj',
        iznos: 0, // popunjava se ispod jedinstvenim iznosom
        datumIzdavanja: periodOd,
        datumDospijeca: periodDo,
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

    // Iznos: tražimo vrijednost s TAČNO 2 decimale (npr. "15,00"), koja
    // je ukupan iznos uplatnice. Stavke imaju 4 decimale (1,8000) pa ih
    // ignorišemo. Svi mjeseci imaju isti iznos, pa uzimamo najčešći.
    final iznos = _ukupanIznos(tekst);
    final iznosFinal = iznos ?? 0;
    for (var i = 0; i < racuni.length; i++) {
      racuni[i] = racuni[i].copyWith(iznos: iznosFinal);
    }

    final upozorenja = <String>[];
    if (iznos == null) {
      upozorenja.add('Iznos nije pročitan - provjerite ručno.');
    }

    return RezultatParsiranja.vise(racuni, upozorenja: upozorenja);
  }

  /// Nalazi ukupan iznos uplatnice: vrijednost s tačno 2 decimale
  /// (npr. "15,00"), ne 4-decimalne stavke (1,8000).
  static double? _ukupanIznos(String tekst) {
    // Brojevi oblika X,XX ali NE X,XXXX (negativni lookahead na 3. decimalu).
    final re = RegExp(r'(?<!\d)(\d{1,4},\d{2})(?!\d)');
    final brojac = <double, int>{};
    for (final m in re.allMatches(tekst)) {
      final b = _broj(m.group(1)!);
      if (b != null && b > 0) {
        brojac[b] = (brojac[b] ?? 0) + 1;
      }
    }
    if (brojac.isEmpty) return null;
    // Najčešći iznos (svi mjeseci imaju isti, npr. 15,00 se javlja više puta).
    double najcesci = brojac.keys.first;
    int maks = 0;
    brojac.forEach((iznos, broj) {
      if (broj > maks) {
        maks = broj;
        najcesci = iznos;
      }
    });
    return najcesci;
  }

  static double? _broj(String s) {
    final o = s.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(o);
  }
}
