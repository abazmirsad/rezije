import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'ekrani/glavni_ekran.dart';
import 'providers/rezije_provider.dart';
import 'tema/app_tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicijalizacija formatiranja datuma za bosanski jezik.
  await initializeDateFormatting('bs', null);

  runApp(const RezijeApp());
}

class RezijeApp extends StatelessWidget {
  const RezijeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Učitavamo račune odmah pri pokretanju.
      create: (_) => RezijeProvider()..ucitajRacune(),
      child: MaterialApp(
        title: 'Režije',
        debugShowCheckedModeBanner: false,
        theme: AppTema.svijetla,
        // Podrška za bosansku lokalizaciju (datumi, kalendar...).
        locale: const Locale('bs'),
        supportedLocales: const [
          Locale('bs'),
          Locale('hr'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const GlavniEkran(),
      ),
    );
  }
}
