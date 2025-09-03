import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'services/sync_service.dart';
import 'services/anniversary.dart'; 
import 'background/background_task.dart';
import 'background/pendents.dart';
import 'home_page.dart';
import 'login.screen.dart';
import 'local_log.dart';
import 'secrets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(
    'resource://drawable/ic_notification',
    [
      NotificationChannel(
        channelKey: 'birthday_channel',
        channelName: 'Aniversários',
        channelDescription: 'Lembretes de aniversário dos clientes',
        defaultColor: const Color(0xFF00A300),
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'sync_channel',
        channelName: 'Sincronização',
        channelDescription: 'Notificações de sincronização de dados',
        defaultColor: const Color(0xFF00A300),
        importance: NotificationImportance.Low,
      ),
    ],
  );

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // DESATIVAR PARA NAO MOSTRAR NOTIFICACAO DO WORKMANAGER
    );

    // sincroniza estoques
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

    // verifica aniversários
    await Workmanager().registerPeriodicTask(
      "2",
      tarefaAniversario,
      frequency: Duration(days: 1),
      initialDelay: Duration(seconds: 10),
      constraints: Constraints(
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
    );

    OfflineQueue.startSyncWhenOnline(backendUrl);
  } catch (e, stack) {
    await LocalLogger.log(
      'Erro na inicialização do app: $e\nStackTrace: $stack',
    );
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