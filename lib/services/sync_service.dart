import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clientes.dart';
import '../models/product.dart';
import '../secrets.dart';
import '../local_log.dart';

class SyncService {
  final String baseUrl;

  SyncService({this.baseUrl = backendUrl});

// ESTOQUE
  Future<List<Product>> syncEstoqueGeral() async {
    final url = '$baseUrl/estoque/geral';
    print('Fazendo requisição para: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final produtos = data.map((json) => Product.fromJson(json)).toList();

        final now = DateTime.now().toIso8601String();
        final jsonData = {
          'lastSynced': now,
          'data': data,
        };

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
      print('Erro ao sincronizar estoque: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> lerEstoqueLocalGeral() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/estoque_geral.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no lerEstoqueLocalGeral: $e\nStackTrace: $stack');
      print('Erro ao ler estoque_geral.json: $e');
    }
    return null;
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

      final url = Uri.parse('$baseUrl/clientes?id_vendedor=$idVendedor');
      print('Fazendo requisição GET para: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

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
      print('Erro ao sincronizar clientes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> lerClientesLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/clientes.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro no lerClientesLocal: $e\nStackTrace: $stack');
      print('Erro ao ler clientes.json: $e');
    }
    return null;
  }
}