import '../models/racun.dart';

/// Rezultat parsiranja PDF računa.
///
/// Jedan PDF može sadržavati više računa (npr. OKI šalje 3 mjeseca u
/// jednom PDF-u), zato rezultat nosi listu [racuni]. [upozorenja] su
/// napomene za polja koja parser nije uspio pouzdano pročitati.
class RezultatParsiranja {
  final List<Racun> racuni;
  final List<String> upozorenja;
  final bool uspjeh;

  const RezultatParsiranja({
    this.racuni = const [],
    this.upozorenja = const [],
    this.uspjeh = false,
  });

  /// Prvi račun (ili `null` ako nema). Pogodno za parsere koji vraćaju
  /// tačno jedan račun.
  Racun? get racun => racuni.isEmpty ? null : racuni.first;

  /// Konstruktor za jedan račun (zgodnije za parsere s jednim računom).
  factory RezultatParsiranja.jedan(
    Racun racun, {
    List<String> upozorenja = const [],
  }) {
    return RezultatParsiranja(
      racuni: [racun],
      upozorenja: upozorenja,
      uspjeh: true,
    );
  }

  /// Konstruktor za više računa.
  factory RezultatParsiranja.vise(
    List<Racun> racuni, {
    List<String> upozorenja = const [],
  }) {
    return RezultatParsiranja(
      racuni: racuni,
      upozorenja: upozorenja,
      uspjeh: racuni.isNotEmpty,
    );
  }

  factory RezultatParsiranja.neuspjeh(String razlog) {
    return RezultatParsiranja(uspjeh: false, upozorenja: [razlog]);
  }
}
