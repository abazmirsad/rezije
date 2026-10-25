import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'rezultat_parsiranja.dart';
import 'sarajevogas_parser.dart';
import 'telemach_parser.dart';

/// Servis za čitanje i parsiranje PDF računa.
///
/// Koristi `syncfusion_flutter_pdf` (čisti Dart) za izvlačenje teksta,
/// pa dispečer bira odgovarajući parser prema sadržaju računa.
class PdfServis {
  /// Izvlači čitljiv tekst iz PDF bajtova.
  ///
  /// Radi potpuno lokalno na uređaju (ništa ne ide na internet).
  static String izvuciTekst(Uint8List bajtovi) {
    final dokument = PdfDocument(inputBytes: bajtovi);
    try {
      return PdfTextExtractor(dokument).extractText();
    } finally {
      dokument.dispose();
    }
  }

  /// Parsira PDF račun: izvuče tekst pa odabere pravi parser.
  ///
  /// Prepoznaje Telemach i Sarajevogas račune. Za nepoznate provajdere
  /// vraća neuspjeh s porukom (korisnik tada unosi ručno).
  static RezultatParsiranja parsirajRacun(Uint8List bajtovi) {
    final String tekst;
    try {
      tekst = izvuciTekst(bajtovi);
    } catch (e) {
      return RezultatParsiranja.neuspjeh('Ne mogu pročitati PDF: $e');
    }

    if (tekst.trim().isEmpty) {
      return RezultatParsiranja.neuspjeh(
        'PDF ne sadrži čitljiv tekst (možda je skeniran kao slika).',
      );
    }

    if (TelemachParser.prepoznaje(tekst)) {
      return TelemachParser.parsiraj(tekst);
    }
    if (SarajevogasParser.prepoznaje(tekst)) {
      return SarajevogasParser.parsiraj(tekst);
    }

    return RezultatParsiranja.neuspjeh(
      'Provajder nije prepoznat. Trenutno su podržani Telemach i Sarajevogas.',
    );
  }
}
