import 'package:workmanager/workmanager.dart';
import '../services/sync_service.dart';
import '../secrets.dart';
import '../local_log.dart';
import 'pendents.dart';

const tarefaSync = "sync_estoque";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == tarefaSync) {
        final syncService = SyncService();
        await syncService.syncEstoqueGeral();
        await syncService.syncClientes();
        await OfflineQueue.trySendQueue(backendUrl);
      }
      return Future.value(true);
    } catch (e, stack) {
      await LocalLogger.log('Erro na execução da task $task: $e\nStack: $stack');
      return Future.value(false);
    }
  });
}