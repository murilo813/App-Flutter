import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/obs.dart';
import '../secrets.dart';
import '../background/local_log.dart';
import 'http_client.dart';
import 'parsers.dart';

final client = HttpClient();

class SyncService {
  final String baseUrl;
  final HttpClient client;

  SyncService({this.baseUrl = backendUrl})
    : client = HttpClient(baseUrl: backendUrl);

  // ESTOQUE
  Future<List<Product>> syncEstoqueGeral() async {
    final response = await client.get('/estoque');

    if (response.statusCode == 200) {
      final data = await compute(parseApiList, response.body);

      final produtos = data.map(Product.fromJson).toList();

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/estoque_geral.json',
      );
      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return produtos;
    }
    return [];
  }

  Future<List<Product>> lerEstoqueLocalGeral() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/estoque_geral.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(Product.fromJson).toList();
  }

  // CLIENTES
  Future<List<Cliente>> syncClientes() async {
    final prefs = await SharedPreferences.getInstance();
    final idVendedor = prefs.getInt('id_vendedor');
    if (idVendedor == null) return [];

    final response = await client.get('/clientes?id_vendedor=$idVendedor');

    if (response.statusCode == 200) {
      final data = await compute(parseApiList, response.body);

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/clientes.json',
      );
      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return data.map(Cliente.fromJson).toList();
    }
    return [];
  }

  Future<List<Cliente>> lerClientesLocal() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/clientes.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(Cliente.fromJson).toList();
  }

  // USERS
  Future<List<User>> syncUsers() async {
    final response = await client.get('/usuarios');

    if (response.statusCode == 200) {
      final data = await compute(parseApiList, response.body);

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/users.json',
      );
      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return data.map(User.fromJson).toList();
    }
    return [];
  }

  Future<List<User>> lerUsersLocal() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/users.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(User.fromJson).toList();
  }

  // OBSERVAÇÕES
  Future<List<Obs>> syncObservacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final idVendedor = prefs.getInt('id_vendedor');
    if (idVendedor == null) return [];

    final response = await client.get('/observacoes?id_vendedor=$idVendedor');

    if (response.statusCode == 200) {
      final data = await compute(parseApiList, response.body);

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/observacoes.json',
      );
      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return data.map(Obs.fromJson).toList();
    }
    return [];
  }

  Future<List<Obs>> lerObservacoesLocal() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/observacoes.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(Obs.fromJson).toList();
  }
}

class SyncProgress {
  final String etapa;
  final double progresso;
  SyncProgress(this.etapa, this.progresso);
}

class SyncManager {
  final SyncService sync;

  SyncManager(this.sync);

  Stream<SyncProgress> start() async* {
    yield SyncProgress('Sincronizando clientes...', 0.2);
    await sync.syncClientes();

    yield SyncProgress('Sincronizando observações...', 0.4);
    await sync.syncObservacoes();

    yield SyncProgress('Sincronizando usuários...', 0.6);
    await sync.syncUsers();

    yield SyncProgress('Sincronizando estoque...', 0.8);
    await sync.syncEstoqueGeral();

    yield SyncProgress('Finalizando...', 1.0);
  }
}
