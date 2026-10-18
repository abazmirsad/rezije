import 'package:flutter/material.dart';

/// Predefinisane kategorije režijskih troškova.
///
/// Svaka kategorija ima naziv (na bosanskom), ikonicu i boju koja se
/// koristi u grafovima i na karticama kroz cijelu aplikaciju.
enum Kategorija {
  struja,
  voda,
  plin,
  grijanje,
  internet,
  telefon,
  komunalije,
  tv,
  stanarina,
  ostalo,
}

/// Pomoćne informacije za svaku kategoriju (naziv, ikonica, boja).
extension KategorijaInfo on Kategorija {
  /* Naziv koji se prikazuje korisniku. */
  String get naziv {
    switch (this) {
      case Kategorija.struja:
        return 'Struja';
      case Kategorija.voda:
        return 'Voda';
      case Kategorija.plin:
        return 'Plin';
      case Kategorija.grijanje:
        return 'Grijanje';
      case Kategorija.internet:
        return 'Internet';
      case Kategorija.telefon:
        return 'Telefon';
      case Kategorija.komunalije:
        return 'Komunalije';
      case Kategorija.tv:
        return 'TV';
      case Kategorija.stanarina:
        return 'Stanarina';
      case Kategorija.ostalo:
        return 'Ostalo';
    }
  }

  /* Ikonica koja predstavlja kategoriju. */
  IconData get ikonica {
    switch (this) {
      case Kategorija.struja:
        return Icons.bolt_rounded;
      case Kategorija.voda:
        return Icons.water_drop_rounded;
      case Kategorija.plin:
        return Icons.local_fire_department_rounded;
      case Kategorija.grijanje:
        return Icons.thermostat_rounded;
      case Kategorija.internet:
        return Icons.wifi_rounded;
      case Kategorija.telefon:
        return Icons.phone_iphone_rounded;
      case Kategorija.komunalije:
        return Icons.delete_sweep_rounded;
      case Kategorija.tv:
        return Icons.tv_rounded;
      case Kategorija.stanarina:
        return Icons.home_rounded;
      case Kategorija.ostalo:
        return Icons.receipt_long_rounded;
    }
  }

  /* Boja kategorije - koristi se u grafovima i na karticama. */
  Color get boja {
    switch (this) {
      case Kategorija.struja:
        return const Color(0xFFF9A825); // žuta
      case Kategorija.voda:
        return const Color(0xFF29B6F6); // svijetlo plava
      case Kategorija.plin:
        return const Color(0xFFEF5350); // crvena
      case Kategorija.grijanje:
        return const Color(0xFFFF7043); // narandžasta
      case Kategorija.internet:
        return const Color(0xFF7E57C2); // ljubičasta
      case Kategorija.telefon:
        return const Color(0xFF26A69A); // tirkizna
      case Kategorija.komunalije:
        return const Color(0xFF8D6E63); // smeđa
      case Kategorija.tv:
        return const Color(0xFF5C6BC0); // indigo
      case Kategorija.stanarina:
        return const Color(0xFF66BB6A); // zelena
      case Kategorija.ostalo:
        return const Color(0xFF78909C); // sivo-plava
    }
  }

  /* Naziv za spremanje u bazu (stabilan ključ, ne mijenja se). */
  String get kljuc => name;

  /// Vraća kategoriju na osnovu ključa iz baze. Ako ključ nije poznat,
  /// vraća [Kategorija.ostalo].
  static Kategorija izKljuca(String kljuc) {
    return Kategorija.values.firstWhere(
      (k) => k.name == kljuc,
      orElse: () => Kategorija.ostalo,
    );
  }
}
