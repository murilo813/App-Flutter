import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/obs.dart';
import '../background/local_log.dart';

class InactivityService {
  static const int _diasInatividade = 30;

  static Future<void> checkAndNotify() async {
    try {
      _logInicio();

      if (await _naoDeveEnviarHoje()) return;

      final clientes = await _carregarClientes();
      if (clientes.isEmpty) return;

      final ultimaObsPorCliente = await _carregarUltimaObsPorCliente();
      final hoje = DateTime.now();

      final inativos = _filtrarClientesInativos(
        clientes,
        ultimaObsPorCliente,
        hoje,
      );

      if (inativos.isEmpty) {
        print("Nenhum cliente inativo encontrado.");
        return;
      }

      final clientesPorResponsavel = _agruparPorResponsavel(inativos);

      await _enviarNotificacoes(
        clientesPorResponsavel,
        ultimaObsPorCliente,
        hoje,
      );

      await _marcarEnvioHoje();
    } catch (e, stack) {
      await LocalLogger.log(
        "Erro em InactivityService.checkAndNotify: $e\n$stack",
      );
    }
  }

  // ================= CONTROLE =================

  static Future<bool> _naoDeveEnviarHoje() async {
    final prefs = await SharedPreferences.getInstance();
    final idVendedor = prefs.getInt('id_vendedor');

    if (idVendedor == null || idVendedor == 0 || idVendedor == 1) {
      print("Admin ou id inválido, notificações não enviadas.");
      return true;
    }

    final hojeStr = _hojeStr();
    final ultimoEnvio = prefs.getString('ultimo_inativo');

    if (ultimoEnvio == hojeStr) {
      print("Notificações de inatividade já foram enviadas hoje.");
      return true;
    }

    return false;
  }

  static Future<void> _marcarEnvioHoje() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_inativo', _hojeStr());
  }

  static String _hojeStr() => DateTime.now().toIso8601String().substring(0, 10);

  static void _logInicio() {
    print("Função inactivity chamada");
  }

  // ================= DADOS =================

  static Future<List<Cliente>> _carregarClientes() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/clientes.json');

    if (!await file.exists()) return [];

    final jsonMap = json.decode(await file.readAsString());
    if (jsonMap['data'] is! List) return [];

    return jsonMap['data'].map<Cliente>((e) => Cliente.fromJson(e)).toList();
  }

  static Future<Map<int, DateTime>> _carregarUltimaObsPorCliente() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/obs.json');

    if (!await file.exists()) return {};

    final jsonMap = json.decode(await file.readAsString());
    if (jsonMap['data'] is! List) return {};

    final Map<int, DateTime> ultimaObs = {};

    for (final obs in jsonMap['data'].map<Obs>(Obs.fromJson)) {
      final atual = ultimaObs[obs.idCliente];
      if (atual == null || obs.data.isAfter(atual)) {
        ultimaObs[obs.idCliente] = obs.data;
      }
    }

    return ultimaObs;
  }

  // ================= REGRA =================

  static List<Cliente> _filtrarClientesInativos(
    List<Cliente> clientes,
    Map<int, DateTime> ultimaObsPorCliente,
    DateTime hoje,
  ) {
    return clientes.where((c) {
      final ultimaAtividade = _ultimaAtividade(c, ultimaObsPorCliente);
      return ultimaAtividade != null &&
          hoje.difference(ultimaAtividade).inDays >= _diasInatividade;
    }).toList();
  }

  static DateTime? _ultimaAtividade(
    Cliente c,
    Map<int, DateTime> ultimaObsPorCliente,
  ) {
    DateTime? ultima = c.ultima_compra;
    final obs = ultimaObsPorCliente[c.id];

    if (obs != null && (ultima == null || obs.isAfter(ultima))) {
      ultima = obs;
    }

    return ultima;
  }

  static Map<String, List<Cliente>> _agruparPorResponsavel(
    List<Cliente> clientes,
  ) {
    final Map<String, List<Cliente>> mapa = {};

    for (final c in clientes) {
      mapa.putIfAbsent(c.responsavel, () => []).add(c);
    }

    return mapa;
  }

  // ================= NOTIFICAÇÃO =================

  static Future<void> _enviarNotificacoes(
    Map<String, List<Cliente>> clientesPorResponsavel,
    Map<int, DateTime> ultimaObsPorCliente,
    DateTime hoje,
  ) async {
    for (final entry in clientesPorResponsavel.entries) {
      final diasInativos = entry.value
          .map(
            (c) =>
                hoje
                    .difference(_ultimaAtividade(c, ultimaObsPorCliente)!)
                    .inDays,
          )
          .reduce((a, b) => a > b ? a : b);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'inactivity_channel',
          title: '🕒 ${entry.key} não está sendo atendido!',
          body: 'Já fazem $diasInativos dias sem comprar.',
        ),
      );
    }
  }
}
