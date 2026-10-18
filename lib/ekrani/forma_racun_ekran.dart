import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kategorija.dart';
import '../models/racun.dart';
import '../providers/rezije_provider.dart';
import '../tema/app_tema.dart';
import '../util/format.dart';

/// Forma za dodavanje novog ili uređivanje postojećeg računa.
///
/// Ako je [postojeci] `null`, radi se o dodavanju novog računa.
class FormaRacunEkran extends StatefulWidget {
  final Racun? postojeci;

  const FormaRacunEkran({super.key, this.postojeci});

  @override
  State<FormaRacunEkran> createState() => _FormaRacunEkranState();
}

class _FormaRacunEkranState extends State<FormaRacunEkran> {
  final _formKljuc = GlobalKey<FormState>();
  late final TextEditingController _provajderKontroler;
  late final TextEditingController _iznosKontroler;
  late final TextEditingController _biljeskaKontroler;

  late Kategorija _kategorija;
  late DateTime _datumIzdavanja;
  late DateTime _datumDospijeca;
  late bool _placeno;

  bool get _uredjivanje => widget.postojeci != null;

  @override
  void initState() {
    super.initState();
    final p = widget.postojeci;
    _provajderKontroler = TextEditingController(text: p?.provajder ?? '');
    _iznosKontroler = TextEditingController(
      text: p != null ? p.iznos.toStringAsFixed(2) : '',
    );
    _biljeskaKontroler = TextEditingController(text: p?.biljeska ?? '');
    _kategorija = p?.kategorija ?? Kategorija.struja;
    _datumIzdavanja = p?.datumIzdavanja ?? DateTime.now();
    _datumDospijeca = p?.datumDospijeca ??
        DateTime.now().add(const Duration(days: 15));
    _placeno = p?.placeno ?? false;
  }

  @override
  void dispose() {
    _provajderKontroler.dispose();
    _iznosKontroler.dispose();
    _biljeskaKontroler.dispose();
    super.dispose();
  }

  Future<void> _izaberiDatum({required bool izdavanje}) async {
    final pocetni = izdavanje ? _datumIzdavanja : _datumDospijeca;
    final izabrano = await showDatePicker(
      context: context,
      initialDate: pocetni,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      helpText: izdavanje ? 'Datum izdavanja' : 'Datum dospijeća',
    );
    if (izabrano != null) {
      setState(() {
        if (izdavanje) {
          _datumIzdavanja = izabrano;
        } else {
          _datumDospijeca = izabrano;
        }
      });
    }
  }

  Future<void> _sacuvaj() async {
    if (!_formKljuc.currentState!.validate()) return;

    final iznos = double.parse(
      _iznosKontroler.text.replaceAll(',', '.'),
    );
    final provider = context.read<RezijeProvider>();

    if (_uredjivanje) {
      await provider.azurirajRacun(
        widget.postojeci!.copyWith(
          kategorija: _kategorija,
          provajder: _provajderKontroler.text.trim(),
          iznos: iznos,
          datumIzdavanja: _datumIzdavanja,
          datumDospijeca: _datumDospijeca,
          placeno: _placeno,
          biljeska: _biljeskaKontroler.text.trim(),
        ),
      );
    } else {
      await provider.dodajRacun(
        Racun(
          kategorija: _kategorija,
          provajder: _provajderKontroler.text.trim(),
          iznos: iznos,
          datumIzdavanja: _datumIzdavanja,
          datumDospijeca: _datumDospijeca,
          placeno: _placeno,
          biljeska: _biljeskaKontroler.text.trim(),
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_uredjivanje ? 'Uredi račun' : 'Novi račun'),
      ),
      body: Form(
        key: _formKljuc,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const _Oznaka('Kategorija'),
            const SizedBox(height: 8),
            _IzborKategorije(
              izabrana: _kategorija,
              naPromjeni: (k) => setState(() => _kategorija = k),
            ),
            const SizedBox(height: 20),

            const _Oznaka('Provajder / firma'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _provajderKontroler,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'npr. Elektroprivreda, BH Telecom',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Unesite provajder' : null,
            ),
            const SizedBox(height: 20),

            const _Oznaka('Iznos (KM)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _iznosKontroler,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(hintText: '0,00'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Unesite iznos';
                final broj = double.tryParse(v.replaceAll(',', '.'));
                if (broj == null || broj <= 0) {
                  return 'Unesite ispravan iznos';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _DatumPolje(
                    oznaka: 'Datum izdavanja',
                    datum: _datumIzdavanja,
                    naDodir: () => _izaberiDatum(izdavanje: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatumPolje(
                    oznaka: 'Rok plaćanja',
                    datum: _datumDospijeca,
                    naDodir: () => _izaberiDatum(izdavanje: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const _Oznaka('Bilješka (opcionalno)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _biljeskaKontroler,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Dodatna napomena...',
              ),
            ),
            const SizedBox(height: 20),

            // Prekidač: plaćeno
            Container(
              decoration: BoxDecoration(
                color: AppTema.povrsina,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                value: _placeno,
                onChanged: (v) => setState(() => _placeno = v),
                activeColor: AppTema.uspjeh,
                title: const Text('Račun je plaćen'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: _sacuvaj,
              icon: const Icon(Icons.check_rounded),
              label: Text(_uredjivanje ? 'Sačuvaj izmjene' : 'Dodaj račun'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Oznaka extends StatelessWidget {
  final String tekst;
  const _Oznaka(this.tekst);

  @override
  Widget build(BuildContext context) {
    return Text(
      tekst,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTema.tekstTamni,
      ),
    );
  }
}

class _IzborKategorije extends StatelessWidget {
  final Kategorija izabrana;
  final ValueChanged<Kategorija> naPromjeni;

  const _IzborKategorije({
    required this.izabrana,
    required this.naPromjeni,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in Kategorija.values)
          GestureDetector(
            onTap: () => naPromjeni(k),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: izabrana == k
                    ? k.boja
                    : AppTema.povrsina,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: izabrana == k
                      ? k.boja
                      : AppTema.tekstSivi.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    k.ikonica,
                    size: 18,
                    color: izabrana == k ? Colors.white : k.boja,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    k.naziv,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          izabrana == k ? Colors.white : AppTema.tekstTamni,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DatumPolje extends StatelessWidget {
  final String oznaka;
  final DateTime datum;
  final VoidCallback naDodir;

  const _DatumPolje({
    required this.oznaka,
    required this.datum,
    required this.naDodir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Oznaka(oznaka),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: naDodir,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: AppTema.pozadina,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTema.tekstSivi,
                ),
                const SizedBox(width: 8),
                Text(
                  Format.datum(datum),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
