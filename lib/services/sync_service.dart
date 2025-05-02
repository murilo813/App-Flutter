import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import 'api_service.dart';

Future<void> syncEstoqueDeTodasLojas() async {
  try {
    final lojas = ['aurora', 'imbuia', 'vilanova', 'belavista'];
    for (final loja in lojas) {
      final api = ApiService();
      final produtos = await api.fetchProducts(loja);

      final now = DateTime.now().toIso8601String();
      final jsonData = {
        'lastSynced': now,
        'data': produtos.map((p) => p.toJson()).toList(),
      };

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$loja.json');
      await file.writeAsString(json.encode(jsonData));

      print('$loja sincronizado localmente em $now');
    }
  } catch (e) {
    print('Erro ao sincronizar todas as lojas: $e');
  }
}

Future<Map<String, dynamic>?> lerEstoqueLocal(String loja) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$loja.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content);
    }
  } catch (e) {
    print('Erro ao ler arquivo local $loja.json: $e');
  }
  return null;
}
Future<void> salvarEstoqueLocal(String loja, List<Product> produtos, String dataHoraAgora) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$loja.json');

    final jsonData = {
      'lastSynced': dataHoraAgora,
      'data': produtos.map((p) => p.toJson()).toList(),
    };

    await file.writeAsString(json.encode(jsonData));
    print('$loja salvo localmente em $dataHoraAgora');
  } catch (e) {
    print('Erro ao salvar estoque local para $loja: $e');
  }
}
Future<void> syncAllStores() async {
  try {
    await syncEstoqueDeTodasLojas();
    print('Todas as lojas foram sincronizadas');
  } catch (e) {
    print('Erro ao sincronizar todas as lojas: $e');
  }
}



