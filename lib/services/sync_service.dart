import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../secrets.dart';
import '../background/local_log.dart';
import '../services/http_client.dart';

final client = HttpClient();

class SyncService {
  final String baseUrl;
  final HttpClient client;

  SyncService({this.baseUrl = backendUrl}) : client = HttpClient(baseUrl: backendUrl);

  // ESTOQUE
  Future<List<Product>> syncEstoqueGeral() async {
    print('Fazendo requisição para: $baseUrl/estoque');

    try {
      final response = await client.get('/estoque');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];

        final produtos = data.map((json) => Product.fromJson(json)).toList();

        final now = DateTime.now().toIso8601String();
        final jsonData = {'lastSynced': now, 'data': data};

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/estoque_geral.json');
        await file.writeAsString(json.encode(jsonData));
        print('Estoque geral sincronizado localmente em $now');

        return produtos;
      } else {
        print('Erro ao carregar produtos (status ${response.statusCode})');
        return [];
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no syncEstoqueGeral: $e\nStackTrace: $stack');
      print('Erro ao sincronizar estoque (sync): $e');
      return [];
    }
  }

  Future<List<Product>> lerEstoqueLocalGeral() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/estoque_geral.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);
        final List<dynamic> data = jsonData['data'] ?? [];
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no lerEstoqueLocalGeral: $e\nStackTrace: $stack');
      print('Erro ao ler estoque_geral.json: $e');
    }
    return [];
  }

  // CLIENTES
  Future<List<Cliente>> syncClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? idVendedor = prefs.getInt('id_vendedor');

      if (idVendedor == null) {
        final msg = 'id_vendedor não encontrado no SharedPreferences';
        await LocalLogger.log('Erro no syncClientes: $msg');
        return [];
      }

      final response = await client.get('/clientes?id_vendedor=$idVendedor');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];

        final now = DateTime.now().toIso8601String();
        final jsonData = {
          'lastSynced': now,
          'data': data, 
        };

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/clientes.json');
        await file.writeAsString(json.encode(jsonData));
        print('Clientes sincronizados localmente em $now');

        return data.map<Cliente>((json) => Cliente.fromJson(json)).toList();
      } else {
        final msg = 'Erro ao carregar clientes (status ${response.statusCode})';
        await LocalLogger.log('Erro no syncClientes: $msg');
        return [];
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no syncClientes: $e\nStackTrace: $stack');
      print('Erro ao sincronizar clientes (sync): $e');
      return [];
    }
  }

  Future<List<Cliente>> lerClientesLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/clientes.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);
        final List<dynamic> data = jsonData['data'] ?? [];
        return data.map((json) => Cliente.fromJson(json)).toList();
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no lerClientesLocal: $e\nStackTrace: $stack');
      print('Erro ao ler clientes.json: $e');
    }
    return [];
  }

  // USERS
  Future<List<User>> syncUsers() async {
    try {
      final response = await client.get('/usuarios');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];

        final now = DateTime.now().toIso8601String();
        final jsonData = {
          'lastSynced': now,
          'data': data,
        };

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/users.json');
        await file.writeAsString(json.encode(jsonData));
        print('Usuários sincronizados localmente em $now');

        return data.map<User>((json) => User.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        print('Acesso negado pelo servidor. Nenhum dado foi sincronizado.');
        return [];
      } else {
        final msg = 'Erro ao carregar usuários (status ${response.statusCode})';
        await LocalLogger.log('Erro no syncUsers: $msg');
        return [];
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no syncUsers: $e\nStackTrace: $stack');
      print('Erro ao sincronizar usuários (sync): $e');
      return [];
    }
  }

  Future<List<User>> lerUsersLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);
        final List<dynamic> data = jsonData['data'] ?? [];
        return data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no lerUsersLocal: $e\nStackTrace: $stack');
      print('Erro ao ler users.json: $e');
    }
    return [];
  }
}