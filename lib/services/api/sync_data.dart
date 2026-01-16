import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alembro/models/client.dart';
import 'package:alembro/models/product.dart';
import 'package:alembro/models/user.dart';
import 'package:alembro/models/observation.dart';
import 'package:alembro/secrets.dart';
import 'package:alembro/services/local/local_log.dart';
import 'http_client.dart';
import '../local/parsers.dart';

final httpClient = HttpClient();

class SyncService {
  final String baseUrl;
  final HttpClient httpClient;

  SyncService({this.baseUrl = backendUrl})
    : httpClient = HttpClient(baseUrl: backendUrl);

  // ESTOQUE
  Future<List<Product>> syncStock() async {
    try {
      final response = await httpClient.get('/estoque');

      if (response.statusCode != 200) {
        await LocalLogger.log('Erro /estoque: ${response.statusCode}');
        return [];
      }

      final data = await compute(parseApiList, response.body);
      final products = data.map(Product.fromJson).toList();

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/stock.json',
      );

      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return products;
    } catch (e, stack) {
      await LocalLogger.log(
        'syncStock falhou: $e\n$stack',
      );
      return [];
    }
  }

  Future<List<Product>> readStock() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/stock.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(Product.fromJson).toList();
  }

  // CLIENTES
  Future<List<Client>> syncClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getInt('id_vendedor');
      if (sellerId == null) {
        await LocalLogger.log('syncClients abortado: id_vendedor não definido');
        return [];
      }

      final response = await httpClient.get('/clientes?id_vendedor=$sellerId');

      if (response.statusCode != 200) {
        await LocalLogger.log(
          'syncClients falhou: statusCode ${response.statusCode}',
        );
        return [];
      }

      final data = await compute(parseApiList, response.body);

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/clients.json',
      );
      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return data.map(Client.fromJson).toList();
    } catch (e, stack) {
      await LocalLogger.log('syncClients erro: $e\n$stack');
      return [];
    }
  }

  Future<List<Client>> readClients() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/clients.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(Client.fromJson).toList();
  }

  // USERS
  Future<List<User>> syncUsers() async {
    try {
      final response = await httpClient.get('/usuarios');

      if (response.statusCode != 200) {
        await LocalLogger.log(
          'syncUsers falhou: statusCode ${response.statusCode}',
        );
        return [];
      }

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
    } catch (e, stack) {
      await LocalLogger.log('syncUsers erro: $e\n$stack');
      return [];
    }
  }

  Future<List<User>> readUsers() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/users.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(User.fromJson).toList();
  }

  // ObservationsERVAÇÕES
  Future<List<Observation>> syncObservations() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getInt('id_vendedor');
    if (sellerId == null) return [];

    final response = await httpClient.get('/observacoes?id_vendedor=$sellerId');

    if (response.statusCode == 200) {
      final data = await compute(parseApiList, response.body);

      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/observations.json',
      );
      await file.writeAsString(
        json.encode({
          'lastSynced': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      return data.map(Observation.fromJson).toList();
    }
    return [];
  }

  Future<List<Observation>> readObservations() async {
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/observations.json',
    );
    if (!await file.exists()) return [];

    final data = await compute(parseLocalList, await file.readAsString());
    return data.map(Observation.fromJson).toList();
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
    await sync.syncClients();

    yield SyncProgress('Sincronizando observações...', 0.4);
    await sync.syncObservations();

    yield SyncProgress('Sincronizando usuários...', 0.6);
    await sync.syncUsers();

    yield SyncProgress('Sincronizando estoque...', 0.8);
    await sync.syncStock();

    yield SyncProgress('Finalizando...', 1.0);
  }
}
