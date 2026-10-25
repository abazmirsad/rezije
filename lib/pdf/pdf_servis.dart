import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'oki_parser.dart';
import 'rezultat_parsiranja.dart';
import 'sarajevogas_parser.dart';
import 'struja_parser.dart';
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
    final dokument = PdfDocument(inputBytes: _ocistiBajtove(bajtovi));
    try {
      return PdfTextExtractor(dokument).extractText();
    } finally {
      dokument.dispose();
    }
  }

  /// Uklanja eventualno smeće prije "%PDF" zaglavlja.
  ///
  /// Neki računi (npr. Elektroprivreda) imaju par bajtova (BOM i sl.)
  /// prije PDF zaglavlja, što neke biblioteke odbiju. Tražimo "%PDF"
  /// i vraćamo bajtove od te pozicije.
  static Uint8List _ocistiBajtove(Uint8List bajtovi) {
    // "%PDF" = 0x25 0x50 0x44 0x46
    const p = 0x25, d = 0x50, e = 0x44, f = 0x46;
    final granica = bajtovi.length - 4;
    for (int i = 0; i <= granica && i < 16; i++) {
      if (bajtovi[i] == p &&
          bajtovi[i + 1] == d &&
          bajtovi[i + 2] == e &&
          bajtovi[i + 3] == f) {
        return i == 0 ? bajtovi : Uint8List.sublistView(bajtovi, i);
      }
    }
    return bajtovi;
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
    if (OkiParser.prepoznaje(tekst)) {
      return OkiParser.parsiraj(tekst);
    }
    if (StrujaParser.prepoznaje(tekst)) {
      return StrujaParser.parsiraj(tekst);
    }

    return RezultatParsiranja.neuspjeh(
      'Provajder nije prepoznat. Trenutno su podržani Telemach, '
      'Sarajevogas, OKI (održavanje) i Elektroprivreda (struja).',
    );
  }
}
