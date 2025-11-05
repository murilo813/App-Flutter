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
      final idVendedor = prefs.getInt('id_vendedor');
      if (idVendedor == null || idVendedor == 0 || idVendedor == 1) {
        print("Admin ou id inválido, notificações não enviadas.");
        return;
      }

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

      // Filtra clientes inativos
      final inativos = clientes.where((c) =>
          c.ultima_compra != null &&
          hoje.difference(c.ultima_compra!).inDays >= 20
      ).toList();

      if (inativos.isEmpty) {
        print("Nenhum cliente inativo encontrado.");
        return;
      }

      // Agrupa por responsável
      final Map<String, List<Cliente>> porResponsavel = {};
      for (var c in inativos) {
        porResponsavel.putIfAbsent(c.responsavel, () => []).add(c);
      }

      // Cria apenas uma notificação por responsável
      for (var entry in porResponsavel.entries) {
        final responsavel = entry.key;
        final clientesDoResponsavel = entry.value;

        // Pega a quantidade de dias desde a última compra mais antiga
        final diasInativos = clientesDoResponsavel
            .map((c) => hoje.difference(c.ultima_compra!).inDays)
            .reduce((a, b) => a > b ? a : b);

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'inactivity_channel',
            title: '🕒 $responsavel não está sendo atendido!',
            body: 'Já fazem $diasInativos dias sem comprar.',
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