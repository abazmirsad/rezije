import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/kategorija.dart';
import '../tema/app_tema.dart';
import '../util/format.dart';

/// Kružni (pie) grafikon potrošnje po kategorijama za jedan mjesec.
class PieGrafKategorije extends StatefulWidget {
  final Map<Kategorija, double> podaci;

  const PieGrafKategorije({super.key, required this.podaci});

  @override
  State<PieGrafKategorije> createState() => _PieGrafKategorijeState();
}

class _PieGrafKategorijeState extends State<PieGrafKategorije> {
  int _dodirnutiIndeks = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.podaci.isEmpty) {
      return const _PraznoStanje(
        poruka: 'Nema podataka za ovaj mjesec.',
      );
    }

    final ukupno =
        widget.podaci.values.fold(0.0, (zbir, v) => zbir + v);
    final stavke = widget.podaci.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        // Grafikon
        SizedBox(
          height: 160,
          width: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, odgovor) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            odgovor == null ||
                            odgovor.touchedSection == null) {
                          _dodirnutiIndeks = -1;
                          return;
                        }
                        _dodirnutiIndeks = odgovor
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _sekcije(stavke, ukupno),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ukupno',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTema.tekstSivi,
                    ),
                  ),
                  Text(
                    Format.novac(ukupno),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Legenda
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final stavka in stavke)
                _LegendaRed(
                  kategorija: stavka.key,
                  iznos: stavka.value,
                  postotak: ukupno == 0 ? 0 : stavka.value / ukupno,
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _sekcije(
    List<MapEntry<Kategorija, double>> stavke,
    double ukupno,
  ) {
    return List.generate(stavke.length, (i) {
      final stavka = stavke[i];
      final dodirnuto = i == _dodirnutiIndeks;
      final postotak = ukupno == 0 ? 0.0 : (stavka.value / ukupno) * 100;

      return PieChartSectionData(
        value: stavka.value,
        color: stavka.key.boja,
        radius: dodirnuto ? 30 : 24,
        title: postotak >= 8 ? '${postotak.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    });
  }
}

class _LegendaRed extends StatelessWidget {
  final Kategorija kategorija;
  final double iznos;
  final double postotak;

  const _LegendaRed({
    required this.kategorija,
    required this.iznos,
    required this.postotak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: kategorija.boja,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kategorija.naziv,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Format.novac(iznos),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTema.tekstSivi,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(postotak * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTema.tekstSivi,
            ),
          ),
        ],
      ),
    );
  }
}

class _PraznoStanje extends StatelessWidget {
  final String poruka;

  const _PraznoStanje({required this.poruka});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 40,
              color: AppTema.tekstSivi.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              poruka,
              style: const TextStyle(color: AppTema.tekstSivi),
            ),
          ],
        ),
      ),
    );
  }
}
