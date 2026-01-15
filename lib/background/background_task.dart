import 'package:workmanager/workmanager.dart';

import 'package:alembro/services/sync_service.dart';
import 'package:alembro/services/anniversary.dart';
import 'package:alembro/services/inactivity.dart';
import 'package:alembro/secrets.dart';

import 'local_log.dart';
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
        await syncService.syncObservacoes();
        await OfflineQueue.trySendQueue(backendUrl);
        await AnniversaryService.checkAndNotify();
        await InactivityService.checkAndNotify();

        final agora = DateTime.now().toIso8601String();
        await LocalLogger.log("Dados sincronizados $agora");
      }
      return true;
    } catch (e, stack) {
      await LocalLogger.log(
        'Erro na execução da task $task: $e\nStack: $stack',
      );
      return false;
    }
  });
}
