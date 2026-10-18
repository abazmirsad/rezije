import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/racun.dart';
import '../providers/rezije_provider.dart';
import '../tema/app_tema.dart';
import '../util/format.dart';
import 'forma_racun_ekran.dart';

/// Filter prikaza računa.
enum _Filter { svi, neplaceni, placeni }

/// Ekran s listom svih računa i mogućnošću filtriranja.
class ListaRacunaEkran extends StatefulWidget {
  const ListaRacunaEkran({super.key});

  @override
  State<ListaRacunaEkran> createState() => _ListaRacunaEkranState();
}

class _ListaRacunaEkranState extends State<ListaRacunaEkran> {
  _Filter _filter = _Filter.svi;

  List<Racun> _filtrirani(List<Racun> svi) {
    switch (_filter) {
      case _Filter.svi:
        return svi;
      case _Filter.neplaceni:
        return svi.where((r) => !r.placeno).toList();
      case _Filter.placeni:
        return svi.where((r) => r.placeno).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RezijeProvider>();
    final racuni = _filtrirani(provider.racuni);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Računi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${racuni.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTema.tekstSivi,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FilterTrake(
            izabrani: _filter,
            naPromjeni: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: racuni.isEmpty
                ? const _PraznaLista()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: racuni.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _RacunKartica(racun: racuni[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterTrake extends StatelessWidget {
  final _Filter izabrani;
  final ValueChanged<_Filter> naPromjeni;

  const _FilterTrake({required this.izabrani, required this.naPromjeni});

  @override
  Widget build(BuildContext context) {
    final opcije = {
      _Filter.svi: 'Svi',
      _Filter.neplaceni: 'Neplaćeni',
      _Filter.placeni: 'Plaćeni',
    };

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final unos in opcije.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(unos.value),
                selected: izabrani == unos.key,
                onSelected: (_) => naPromjeni(unos.key),
                selectedColor: AppTema.primarna,
                backgroundColor: AppTema.povrsina,
                labelStyle: TextStyle(
                  color: izabrani == unos.key
                      ? Colors.white
                      : AppTema.tekstTamni,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _RacunKartica extends StatelessWidget {
  final Racun racun;

  const _RacunKartica({required this.racun});

  Future<void> _otvoriUredjivanje(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormaRacunEkran(postojeci: racun),
      ),
    );
  }

  Future<void> _potvrdiBrisanje(BuildContext context) async {
    final provider = context.read<RezijeProvider>();
    final potvrda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obrisati račun?'),
        content: const Text('Ova radnja se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Obriši',
              style: TextStyle(color: AppTema.greska),
            ),
          ),
        ],
      ),
    );

    if (potvrda == true && racun.id != null) {
      await provider.obrisiRacun(racun.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RezijeProvider>();

    return Dismissible(
      key: ValueKey(racun.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTema.greska,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _potvrdiBrisanje(context);
        return false; // brisanje radimo ručno kroz provider
      },
      child: GestureDetector(
        onTap: () => _otvoriUredjivanje(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTema.povrsina,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: racun.kategorija.boja.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  racun.kategorija.ikonica,
                  color: racun.kategorija.boja,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      racun.kategorija.naziv,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      racun.provajder,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTema.tekstSivi,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StatusOznaka(racun: racun),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Format.novac(racun.iznos),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => provider.promijeniStatusPlacanja(racun),
                    child: Icon(
                      racun.placeno
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: racun.placeno
                          ? AppTema.uspjeh
                          : AppTema.tekstSivi,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusOznaka extends StatelessWidget {
  final Racun racun;

  const _StatusOznaka({required this.racun});

  @override
  Widget build(BuildContext context) {
    final String tekst;
    final Color boja;

    if (racun.placeno) {
      tekst = 'Plaćeno';
      boja = AppTema.uspjeh;
    } else if (racun.kasni) {
      tekst = 'Kasni';
      boja = AppTema.greska;
    } else {
      tekst = 'Rok: ${Format.datum(racun.datumDospijeca)}';
      boja = AppTema.upozorenje;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: boja.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tekst,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: boja,
        ),
      ),
    );
  }
}

class _PraznaLista extends StatelessWidget {
  const _PraznaLista();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: AppTema.tekstSivi.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Još nema računa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dodajte prvi račun dugmetom +',
            style: TextStyle(color: AppTema.tekstSivi),
          ),
        ],
      ),
    );
  }
}
