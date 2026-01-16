import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BaseStorage {
  // Lê o JSON bruto do disco, não importa qual seja o arquivo
  static Future<Map<String, dynamic>?> getRawData(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (!await file.exists()) return null;
      return json.decode(await file.readAsString());
    } catch (e) {
      return null;
    }
  }
}
