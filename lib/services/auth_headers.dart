import 'package:shared_preferences/shared_preferences.dart';

class AuthHeaders {
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('id_usuario') ?? 'unknown';
    final device = prefs.getString('dispositivo') ?? 'unknown';
    final signature = prefs.getString('assinatura') ?? 'unknown';

    return {
      'dispositivo': device,
      'assinatura': signature,
      'id_usuario': userId.toString(),
      'Content-Type': 'application/json',
    };
  }
}
