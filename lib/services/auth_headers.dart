import 'package:shared_preferences/shared_preferences.dart';

class AuthHeaders {
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    final idUsuario = prefs.getString('id_usuario') ?? 'unknown';
    final dispositivo = prefs.getString('dispositivo') ?? 'unknown';
    final appSig = prefs.getString('assinatura') ?? 'unknown';

    print("AuthHeaders -> dispositivo=$dispositivo, assinatura=$appSig, id_usuario=$idUsuario");

    return {
      'dispositivo': dispositivo,
      'assinatura': appSig,
      'id_usuario': idUsuario.toString(),
      'Content-Type': 'application/json',
    };
  }
}