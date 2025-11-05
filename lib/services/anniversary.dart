import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../background/local_log.dart';

class AnniversaryService {
  static Future<void> checkAndNotify() async {
    try {
      print("Função anniversary chamada");
      final prefs = await SharedPreferences.getInstance();
      final idVendedor = prefs.getInt('id_vendedor');
      if (idVendedor == 1 || idVendedor == 0) {
        return; // para o admin nao receber essas notificacoes
      }
      final hojeStr = DateTime.now().toIso8601String().substring(0, 10); 
      final ultimoEnvio = prefs.getString('ultimo_aniversario') ?? '';

      if (ultimoEnvio == hojeStr) {
        print("Notificações do dia já foram enviadas, nada a fazer.");
        return;
      }

      print("Notificações de aniversário do dia foram enviadas");
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
      final aniversariantes = clientes.where((c) =>
        c.data_nasc != null &&
        c.data_nasc!.day == hoje.day &&
        c.data_nasc!.month == hoje.month
      ).toList();

      if (aniversariantes.isEmpty) return;

      for (var cliente in aniversariantes) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'birthday_channel',
            title: '🎉 Hoje é aniversário de ${cliente.nomeCliente}!',
            body: 'Não esqueça de mandar os parabéns 🎂',
            notificationLayout: NotificationLayout.Default,
          ),
        );
      }

      await prefs.setString('ultimo_aniversario', hojeStr);

    } catch (e, stack) {
      await LocalLogger.log("Erro em AnniversaryService.checkAndNotify: $e\n$stack");
    }
  }
}
