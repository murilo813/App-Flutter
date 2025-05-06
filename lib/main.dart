import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';

import 'services/sync_service.dart';
import 'background/background_task.dart'; 
import 'home_page.dart';

const tarefaSync = "sync_estoque";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher, 
    isInDebugMode: true,
  );

  await Workmanager().registerPeriodicTask(
    "1",
    tarefaSync,
    frequency: Duration(minutes: 15),
    initialDelay: Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  await syncEstoqueDeTodasLojas();

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
