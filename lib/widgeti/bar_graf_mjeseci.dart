import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/rezije_provider.dart';
import '../tema/app_tema.dart';

/// Stupčasti (bar) grafikon ukupne potrošnje po mjesecima.
class BarGrafMjeseci extends StatelessWidget {
  final List<MjesecnaPotrosnja> podaci;

  const BarGrafMjeseci({super.key, required this.podaci});

  @override
  Widget build(BuildContext context) {
    final maks = podaci.isEmpty
        ? 0.0
        : podaci.map((p) => p.iznos).reduce((a, b) => a > b ? a : b);
    // Gornja granica grafa s malo prostora iznad najvišeg stupca.
    final gornjaGranica = maks == 0 ? 100.0 : maks * 1.25;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: gornjaGranica,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTema.tekstTamni,
              getTooltipItem: (grupa, _, rod, __) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(0)} KM',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (vrijednost, meta) {
                  final indeks = vrijednost.toInt();
                  if (indeks < 0 || indeks >= podaci.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      podaci[indeks].kratkiNaziv,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTema.tekstSivi,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: gornjaGranica / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTema.tekstSivi.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _grupe(gornjaGranica),
        ),
      ),
    );
  }

  List<BarChartGroupData> _grupe(double gornjaGranica) {
    return List.generate(podaci.length, (i) {
      final p = podaci[i];
      final zadnji = i == podaci.length - 1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: p.iznos,
            width: 22,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            // Zadnji (trenutni) mjesec je istaknut primarnom bojom.
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: zadnji
                  ? [AppTema.primarna, AppTema.primarnaTamna]
                  : [
                      AppTema.primarna.withValues(alpha: 0.35),
                      AppTema.primarna.withValues(alpha: 0.25),
                    ],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: gornjaGranica,
              color: AppTema.pozadina,
            ),
          ),
        ],
      );
    });
  }
}
