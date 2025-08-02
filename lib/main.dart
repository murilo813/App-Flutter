import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/sync_service.dart';
import 'background/background_task.dart';
import 'background/pendents.dart';
import 'home_page.dart';
import 'login.screen.dart';
import 'local_log.dart';
import 'secrets.dart';

const tarefaSync = "sync_estoque";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
    );
    OfflineQueue.startSyncWhenOnline(backendUrl);
  } catch (e, stack) {
    await LocalLogger.log('Erro na inicialização do app: $e\nStackTrace: $stack');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroZecão',
      home: LoginScreen(),
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