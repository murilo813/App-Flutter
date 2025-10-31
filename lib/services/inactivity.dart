import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../background/local_log.dart';

class InactivityService {
  static Future<void> checkAndNotify() async {
    try {
      print("Função inactivity chamada");
      final prefs = await SharedPreferences.getInstance();
      final hojeStr = DateTime.now().toIso8601String().substring(0, 10);
      final ultimoEnvio = prefs.getString('ultimo_inativo') ?? '';

      if (ultimoEnvio == hojeStr) {
        print("Notificações de inatividade já foram enviadas hoje.");
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/clientes.json');
      if (!(await file.exists())) return;

      final content = await file.readAsString();
      final jsonMap = json.decode(content);

      if (jsonMap['data'] is! List) return;

      final clientes = jsonMap['data']
          .map<Cliente>((e) => Cliente.fromJson(e))
          .toList();

      final hoje = DateTime.now();

      final inativos = clientes.where((c) =>
          c.ultima_compra != null &&
          hoje.difference(c.ultima_compra!).inDays >= 20
      ).toList();

      if (inativos.isEmpty) {
        print("Nenhum cliente inativo encontrado.");
        return;
      }

      for (var cliente in inativos) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'inactivity_channel',
            title: '🕒 ${cliente.nomeCliente} não está sendo atendido!',
            body: 'Já fazem ${hoje.difference(cliente.ultima_compra!).inDays} dias sem comprar.',
            notificationLayout: NotificationLayout.Default,
          ),
        );
      }

      await prefs.setString('ultimo_inativo', hojeStr);

    } catch (e, stack) {
      await LocalLogger.log("Erro em InactivityService.checkAndNotify: $e\n$stack");
    }
  }
}
