import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';

import 'home_page.dart';
import 'services/api_service.dart';
import 'database/local_database.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final api = ApiService();

    // Lista das lojas que precisam ser sincronizadas
    List<String> stores = ['aurora', 'imbuia', 'vilanova', 'belavista'];

    // Sincroniza e salva os produtos de todas as lojas
    for (var store in stores) {
      final data = await api.fetchProducts(store);
      await LocalDatabase.insertProducts(data, store);
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Registro do trabalho para ser executado a cada 5 minutos
  await Workmanager().registerPeriodicTask(
    "syncTask",
    "fetchAndStoreProducts",
    frequency: const Duration(minutes: 5), // A cada 5 minutos
    inputData: {}, 
  );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroZecão',
      home: HomePage(),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
