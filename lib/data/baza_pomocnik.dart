import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/racun.dart';

/// Pomoćnik za rad s lokalnom SQLite bazom podataka.
///
/// Svi podaci se čuvaju lokalno na uređaju - ništa ne ide na internet.
/// Koristi se "singleton" obrazac: postoji samo jedna instanca kroz
/// cijelu aplikaciju ([BazaPomocnik.instanca]).
class BazaPomocnik {
  BazaPomocnik._();

  /// Jedina instanca pomoćnika.
  static final BazaPomocnik instanca = BazaPomocnik._();

  static const String _nazivBaze = 'rezije.db';
  static const int _verzijaBaze = 1;
  static const String tabelaRacuni = 'racuni';

  Database? _baza;

  /// Vraća otvorenu bazu (otvara je ako već nije otvorena).
  Future<Database> get baza async {
    _baza ??= await _otvoriBazu();
    return _baza!;
  }

  Future<Database> _otvoriBazu() async {
    final putanjaBaze = await getDatabasesPath();
    final puce = join(putanjaBaze, _nazivBaze);

    return openDatabase(
      puce,
      version: _verzijaBaze,
      onCreate: _kreirajTabele,
    );
  }

  /// Kreira tabele pri prvom pokretanju aplikacije.
  Future<void> _kreirajTabele(Database db, int verzija) async {
    await db.execute('''
      CREATE TABLE $tabelaRacuni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kategorija TEXT NOT NULL,
        provajder TEXT NOT NULL,
        iznos REAL NOT NULL,
        datum_izdavanja INTEGER NOT NULL,
        datum_dospijeca INTEGER NOT NULL,
        placeno INTEGER NOT NULL DEFAULT 0,
        biljeska TEXT
      )
    ''');
  }

  // ----- CRUD operacije -----

  /// Dodaje novi račun i vraća njegov novi ID.
  Future<int> dodajRacun(Racun racun) async {
    final db = await baza;
    return db.insert(tabelaRacuni, racun.toMap()..remove('id'));
  }

  /// Ažurira postojeći račun. Vraća broj izmijenjenih redova.
  Future<int> azurirajRacun(Racun racun) async {
    final db = await baza;
    return db.update(
      tabelaRacuni,
      racun.toMap(),
      where: 'id = ?',
      whereArgs: [racun.id],
    );
  }

  /// Briše račun po ID-u. Vraća broj obrisanih redova.
  Future<int> obrisiRacun(int id) async {
    final db = await baza;
    return db.delete(
      tabelaRacuni,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Vraća sve račune, sortirane po datumu dospijeća (najnoviji prvo).
  Future<List<Racun>> dohvatiSveRacune() async {
    final db = await baza;
    final redovi = await db.query(
      tabelaRacuni,
      orderBy: 'datum_dospijeca DESC',
    );
    return redovi.map((red) => Racun.fromMap(red)).toList();
  }

  /// Zatvara bazu (korisno kod testiranja).
  Future<void> zatvori() async {
    await _baza?.close();
    _baza = null;
  }
}
