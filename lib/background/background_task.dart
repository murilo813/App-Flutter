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
        await AnniversaryService.checkAndNotify();

        final agora = DateTime.now().toIso8601String();
        await LocalLogger.log("Dados sincronizados $agora");
      }
      return Future.value(true);
    } catch (e, stack) {
      await LocalLogger.log('Erro na execução da task $task: $e\nStack: $stack');
      return Future.value(false);
    }
  });
}