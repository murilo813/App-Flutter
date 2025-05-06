import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import 'api_service.dart';

Future<void> syncEstoqueGeral() async {
  try {
    final api = ApiService();
    final produtos = await api.fetchProducts();

    final now = DateTime.now().toIso8601String();
    final jsonData = {
      'lastSynced': now,
      'data': produtos.map((p) => p.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/estoque_geral.json');
    await file.writeAsString(json.encode(jsonData));

    print('Estoque geral sincronizado localmente em $now');
  } catch (e) {
    print('Erro ao sincronizar estoque geral: $e');
  }
}

Future<void> salvarEstoqueLocal(List<Product> produtos, String dataHora) async {
  try {
    final jsonData = {
      'lastSynced': dataHora,
      'data': produtos.map((p) => p.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/estoque_geral.json');
    await file.writeAsString(json.encode(jsonData));

    print('Estoque salvo localmente em $dataHora');
  } catch (e) {
    print('Erro ao salvar estoque localmente: $e');
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
  } catch (e) {
    print('Erro ao ler estoque_geral.json: $e');
  }
  return null;
}
Future<void> syncAllStores() async {
  try {
    await syncEstoqueGeral();
    print('Todas as lojas foram sincronizadas');
  } catch (e) {
    print('Erro ao sincronizar todas as lojas: $e');
  }
}



