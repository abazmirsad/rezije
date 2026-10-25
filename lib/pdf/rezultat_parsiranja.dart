import '../models/racun.dart';

/// Rezultat parsiranja PDF računa.
///
/// Sadrži prepoznati [racun] i listu [upozorenja] za polja koja parser
/// nije uspio pouzdano pročitati (da korisnik može provjeriti/dopuniti).
class RezultatParsiranja {
  final Racun? racun;
  final List<String> upozorenja;
  final bool uspjeh;

  const RezultatParsiranja({
    this.racun,
    this.upozorenja = const [],
    this.uspjeh = false,
  });

  factory RezultatParsiranja.neuspjeh(String razlog) {
    return RezultatParsiranja(uspjeh: false, upozorenja: [razlog]);
  }
}
