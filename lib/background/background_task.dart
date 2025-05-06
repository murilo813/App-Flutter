import 'package:workmanager/workmanager.dart';
import '../services/sync_service.dart';

const tarefaSync = "sync_estoque";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == tarefaSync) {
      print("Executando sincronização em segundo plano");
      await syncEstoqueDeTodasLojas();
    }
    return Future.value(true);
  });
}