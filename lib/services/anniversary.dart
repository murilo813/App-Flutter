import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'sync_service.dart';
import '../local_log.dart';

class AnniversaryService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa o plugin e o timezone
  static Future<void> initNotifications() async {
    // timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // configura plugin
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notificationsPlugin.initialize(settings);
  }

  /// Agendar notificação para as 8h da manhã
  static Future<void> agendarNotificacaoDiaria8AM(String mensagem) async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Aniversário',
      mensagem,
      _nextInstanceOf8AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel_id',
          'Notificações Diárias',
          channelDescription: 'Notificações de aniversários todos os dias às 8h',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
    );
  }

  /// Calcula próxima ocorrência das 8h
  static tz.TZDateTime _nextInstanceOf8AM() {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Verifica aniversariantes do dia e dispara notificação
  static Future<void> verificarAniversariantes() async {
    try {
      final dataHoje = DateTime.now();
      final clientesJson = await SyncService().lerClientesLocal();
      if (clientesJson == null) return;

      final aniversariantes = (clientesJson['data'] as List)
          .where((c) =>
              c['data_nasc'] != null &&
              DateTime.parse(c['data_nasc']).day == dataHoje.day &&
              DateTime.parse(c['data_nasc']).month == dataHoje.month)
          .toList();

      if (aniversariantes.isEmpty) return;

      String mensagem;
      if (aniversariantes.length == 1) {
        mensagem = '${aniversariantes.first['nomeCliente']} está de aniversário hoje!';
      } else {
        mensagem =
            'Você tem ${aniversariantes.length} clientes aniversariantes hoje!';
      }

      await agendarNotificacaoDiaria8AM(mensagem);
    } catch (e, stack) {
      await LocalLogger.log(
          'Erro ao verificar aniversariantes: $e\nStackTrace: $stack');
    }
  }
}
