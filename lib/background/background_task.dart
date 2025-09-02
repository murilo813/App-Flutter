import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../services/sync_service.dart';
import '../services/anniversary.dart'; 
import '../secrets.dart';
import '../local_log.dart';
import 'pendents.dart';

const tarefaSync = "sync_estoque";
const tarefaAniversario = "check_birthdays";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == tarefaSync) {
        final syncService = SyncService();
        await syncService.syncEstoqueGeral();
        await syncService.syncClientes();
        await OfflineQueue.trySendQueue(backendUrl);

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'sync_channel', 
            title: 'Dados Sincronizados',
            body: '',
            color: Color(0xFF00A300),
          ),
        );

      } else if (task == tarefaAniversario) {
        await AnniversaryService.checkAndNotify();
      }
      return Future.value(true);
    } catch (e, stack) {
      await LocalLogger.log('Erro na execução da task $task: $e\nStack: $stack');
      return Future.value(false);
    }
  });
}
