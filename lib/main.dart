import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'services/sync_service.dart';
import 'services/anniversary.dart'; 
import 'background/background_task.dart';
import 'background/pendents.dart';
import 'background/local_log.dart';
import 'home_page.dart';
import 'login.screen.dart';
import 'secrets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();


// quando o usuario toca na notificacao
@pragma("vm:entry-point")
Future<void> onActionReceivedMethod(ReceivedAction receivedNotification) async {
  if (receivedNotification.channelKey == 'birthday_channel') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => HomePage(key: homeKey)),
    ).then((_) {
      homeKey.currentState?.anniversaryModal(force: true);
    });
  }
}

// quando a notificacao e criada
@pragma("vm:entry-point")
Future<void> onNotificationCreatedMethod(ReceivedNotification notification) async {
  print("Notificação criada: ${notification.id}");
}

// quando a notificacao e exibida na barra
@pragma("vm:entry-point")
Future<void> onNotificationDisplayedMethod(ReceivedNotification notification) async {
  print("Notificação exibida: ${notification.id}");
}

// quando o usuario descarta a notificacao
@pragma("vm:entry-point")
Future<void> onDismissActionReceivedMethod(ReceivedAction action) async {
  print("Notificação descartada: ${action.id}");
}

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
        channelKey: 'inactivity_channel',
        channelName: 'Clientes Inativos',
        channelDescription: 'Avisos de clientes sem compras recentes',
        defaultColor: const Color(0xFFE67E22),
        importance: NotificationImportance.High,
      ),
    ],
  );

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
    onNotificationCreatedMethod: onNotificationCreatedMethod,
    onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: onDismissActionReceivedMethod,
  );

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // DESATIVAR PARA NAO MOSTRAR NOTIFICACAO DO WORKMANAGER
    );

    // sincronizacao de dados
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
      navigatorKey: navigatorKey,
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
