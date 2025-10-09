import 'package:shared_preferences/shared_preferences.dart';

class AuthHeaders {
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    final username = prefs.getString('username') ?? 'unknown';
    final dispositivo = prefs.getString('dispositivo') ?? 'unknown';
    final appSig = prefs.getString('assinatura') ?? 'unknown';

    print("AuthHeaders -> dispositivo=$dispositivo, assinatura=$appSig, nome=$username");

    return {
      'dispositivo': dispositivo,
      'assinatura': appSig,
      'nome': username,
      'Content-Type': 'application/json',
    };
  }
}