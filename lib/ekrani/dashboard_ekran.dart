import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kategorija.dart';
import '../models/racun.dart';
import '../providers/rezije_provider.dart';
import '../tema/app_tema.dart';
import '../util/format.dart';
import '../widgeti/bar_graf_mjeseci.dart';
import '../widgeti/pie_graf_kategorije.dart';

/// Glavni ekran - pregled stanja s grafičkim prikazima.
class DashboardEkran extends StatelessWidget {
  const DashboardEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RezijeProvider>();

    if (provider.ucitavanje) {
      return const Center(child: CircularProgressIndicator());
    }

    final sada = DateTime.now();
    final potrosnjaKategorije =
        provider.potrosnjaPoKategoriji(sada.year, sada.month);
    final potrosnjaMjeseci = provider.potrosnjaPoMjesecima(brojMjeseci: 6);
    final nadolazeci = provider.nadolazeci.take(3).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.ucitajRacune,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _Zaglavlje(mjesec: Format.mjesecGodina(sada.year, sada.month)),
            const SizedBox(height: 16),

            // TEST dugme za čitanje PDF uzoraka (privremeno).
            _TestPdfDugme(),
            const SizedBox(height: 16),

            // Kartice sažetka
            _KarticeSazetka(
              ukupnoMjesec: provider.ukupnoZaMjesec(sada.year, sada.month),
              ukupnoNeplaceno: provider.ukupnoNeplaceno,
              brojNeplacenih: provider.brojNeplacenih,
              brojKasni: provider.racuniKojiKasne.length,
            ),
            const SizedBox(height: 24),

            // Graf potrošnje po mjesecima
            _Sekcija(
              naslov: 'Potrošnja po mjesecima',
              podnaslov: 'Zadnjih 6 mjeseci',
              dijete: BarGrafMjeseci(podaci: potrosnjaMjeseci),
            ),
            const SizedBox(height: 16),

            // Graf po kategorijama
            _Sekcija(
              naslov: 'Po kategorijama',
              podnaslov: Format.mjesecGodina(sada.year, sada.month),
              dijete: PieGrafKategorije(podaci: potrosnjaKategorije),
            ),
            const SizedBox(height: 16),

            // Nadolazeća plaćanja
            if (nadolazeci.isNotEmpty)
              _NadolazecaPlacanja(racuni: nadolazeci),
          ],
        ),
      ),
    );
  }
}

/// Privremeno dugme: učita ugrađene PDF uzorke i parsira ih, da se
/// na telefonu provjeri da čitanje PDF-a radi. Uklanja se kad Gmail proradi.
class _TestPdfDugme extends StatefulWidget {
  @override
  State<_TestPdfDugme> createState() => _TestPdfDugmeState();
}

class _TestPdfDugmeState extends State<_TestPdfDugme> {
  bool _uToku = false;

  Future<void> _pokreni() async {
    setState(() => _uToku = true);
    final provider = context.read<RezijeProvider>();
    String izvjestaj;
    try {
      izvjestaj = await provider.testirajPdfUzorke();
    } catch (e) {
      izvjestaj = 'Greška: $e';
    }
    if (!mounted) return;
    setState(() => _uToku = false);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test čitanja PDF-a'),
        content: SingleChildScrollView(child: Text(izvjestaj)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _uToku ? null : _pokreni,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTema.primarna,
          side: const BorderSide(color: AppTema.primarna, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _uToku
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.science_rounded),
        label: Text(_uToku ? 'Čitam PDF uzorke...' : 'Testiraj čitanje PDF-a'),
      ),
    );
  }
}

class _Zaglavlje extends StatelessWidget {
  final String mjesec;

  const _Zaglavlje({required this.mjesec});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dobro došli 👋',
          style: TextStyle(fontSize: 14, color: AppTema.tekstSivi),
        ),
        const SizedBox(height: 2),
        Text(
          'Pregled za $mjesec',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _KarticeSazetka extends StatelessWidget {
  final double ukupnoMjesec;
  final double ukupnoNeplaceno;
  final int brojNeplacenih;
  final int brojKasni;

  const _KarticeSazetka({
    required this.ukupnoMjesec,
    required this.ukupnoNeplaceno,
    required this.brojNeplacenih,
    required this.brojKasni,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Velika kartica - ukupno ovaj mjesec
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTema.primarna, AppTema.primarnaTamna],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTema.primarna.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ukupno ovaj mjesec',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                Format.novac(ukupnoMjesec),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Dvije manje kartice
        Row(
          children: [
            Expanded(
              child: _MalaKartica(
                ikonica: Icons.pending_actions_rounded,
                boja: AppTema.upozorenje,
                naslov: 'Neplaćeno',
                vrijednost: Format.novac(ukupnoNeplaceno),
                podnaslov: '$brojNeplacenih računa',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MalaKartica(
                ikonica: Icons.warning_amber_rounded,
                boja: brojKasni > 0 ? AppTema.greska : AppTema.uspjeh,
                naslov: 'Kasni',
                vrijednost: '$brojKasni',
                podnaslov: brojKasni == 0 ? 'Sve na vrijeme' : 'računa kasni',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MalaKartica extends StatelessWidget {
  final IconData ikonica;
  final Color boja;
  final String naslov;
  final String vrijednost;
  final String podnaslov;

  const _MalaKartica({
    required this.ikonica,
    required this.boja,
    required this.naslov,
    required this.vrijednost,
    required this.podnaslov,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTema.povrsina,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: boja.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikonica, color: boja, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            naslov,
            style: const TextStyle(
              fontSize: 13,
              color: AppTema.tekstSivi,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            vrijednost,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            podnaslov,
            style: const TextStyle(
              fontSize: 11,
              color: AppTema.tekstSivi,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sekcija extends StatelessWidget {
  final String naslov;
  final String podnaslov;
  final Widget dijete;

  const _Sekcija({
    required this.naslov,
    required this.podnaslov,
    required this.dijete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTema.povrsina,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                naslov,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                podnaslov,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTema.tekstSivi,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          dijete,
        ],
      ),
    );
  }
}

class _NadolazecaPlacanja extends StatelessWidget {
  final List<Racun> racuni;

  const _NadolazecaPlacanja({required this.racuni});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTema.povrsina,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nadolazeća plaćanja',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final r in racuni) _RedPlacanja(racun: r),
        ],
      ),
    );
  }
}

class _RedPlacanja extends StatelessWidget {
  final Racun racun;

  const _RedPlacanja({required this.racun});

  @override
  Widget build(BuildContext context) {
    final dana = racun.danaDoDospijeca;
    final String rokTekst;
    final Color rokBoja;
    if (dana < 0) {
      rokTekst = 'Kasni ${-dana} dana';
      rokBoja = AppTema.greska;
    } else if (dana == 0) {
      rokTekst = 'Danas';
      rokBoja = AppTema.upozorenje;
    } else {
      rokTekst = 'Za $dana dana';
      rokBoja = AppTema.tekstSivi;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: racun.kategorija.boja.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              racun.kategorija.ikonica,
              color: racun.kategorija.boja,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  racun.kategorija.naziv,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  rokTekst,
                  style: TextStyle(fontSize: 12, color: rokBoja),
                ),
              ],
            ),
          ),
          Text(
            Format.novac(racun.iznos),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
