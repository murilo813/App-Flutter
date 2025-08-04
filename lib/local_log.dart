import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalLogger {
  static Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/app_log.txt');
  }

  static Future<void> log(String message) async {
    try {
        final file = await _getLogFile();
        final timestamp = DateTime.now().toIso8601String();
        await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (e) {
        // evita crash se falhar ao escrever o log
    }
  }
}