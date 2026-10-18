import 'package:intl/intl.dart';

/// Pomoćne funkcije za formatiranje novca i datuma na bosanskom.
class Format {
  Format._();

  /// Formatira iznos kao "123,45 KM".
  static String novac(double iznos) {
    // Simbol valute stavljamo iza iznosa (uobičajeno za KM).
    final broj = NumberFormat('#,##0.00', 'bs').format(iznos);
    return '$broj KM';
  }

  /// Formatira datum kao "15.05.2026.".
  static String datum(DateTime d) {
    return DateFormat('dd.MM.yyyy.', 'bs').format(d);
  }

  /// Formatira datum kao "15. maj 2026.".
  static String datumDugi(DateTime d) {
    const mjeseci = [
      'januar',
      'februar',
      'mart',
      'april',
      'maj',
      'juni',
      'juli',
      'avgust',
      'septembar',
      'oktobar',
      'novembar',
      'decembar',
    ];
    return '${d.day}. ${mjeseci[d.month - 1]} ${d.year}.';
  }

  /// Naziv mjeseca i godine, npr. "Maj 2026".
  static String mjesecGodina(int godina, int mjesec) {
    const mjeseci = [
      'Januar',
      'Februar',
      'Mart',
      'April',
      'Maj',
      'Juni',
      'Juli',
      'Avgust',
      'Septembar',
      'Oktobar',
      'Novembar',
      'Decembar',
    ];
    return '${mjeseci[mjesec - 1]} $godina';
  }
}
