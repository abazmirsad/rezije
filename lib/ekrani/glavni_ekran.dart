import 'package:flutter/material.dart';

import '../tema/app_tema.dart';
import 'dashboard_ekran.dart';
import 'forma_racun_ekran.dart';
import 'lista_racuna_ekran.dart';

/// Glavni okvir aplikacije s donjom navigacijom.
///
/// Prebacuje između Pregleda (dashboard) i liste Računa, te sadrži
/// plutajuće dugme za dodavanje novog računa.
class GlavniEkran extends StatefulWidget {
  const GlavniEkran({super.key});

  @override
  State<GlavniEkran> createState() => _GlavniEkranState();
}

class _GlavniEkranState extends State<GlavniEkran> {
  int _indeks = 0;

  static const _ekrani = [
    DashboardEkran(),
    ListaRacunaEkran(),
  ];

  Future<void> _dodajRacun() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FormaRacunEkran()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indeks,
        children: _ekrani,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _dodajRacun,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeks,
        onDestinationSelected: (i) => setState(() => _indeks = i),
        backgroundColor: AppTema.povrsina,
        indicatorColor: AppTema.primarna.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppTema.primarna),
            label: 'Pregled',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long_rounded, color: AppTema.primarna),
            label: 'Računi',
          ),
        ],
      ),
    );
  }
}
