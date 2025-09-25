import 'package:android_id/android_id.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHeaders {
  static final AndroidId _androidIdPlugin = AndroidId();

  static Future<String> getdispositivo() async {
    try {
      final dispositivo = await _androidIdPlugin.getId();
      return dispositivo ?? 'unknown';
    } catch (e) {
      print('Erro ao obter Device ID: $e');
      return 'unknown';
    }
  }

  static Future<String> getassinatura() async {
    try {
      const platform = MethodChannel('app_signature_channel');
      final sha256 = await platform.invokeMethod<String>('getassinatura');
      return sha256 ?? 'unknown';
    } catch (e) {
      print('Erro ao obter assinatura do app: $e');
      return 'unknown';
    }
  }

  /// Retorna headers para enviar em todas as requisições
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'unknown';
    final dispositivo = await getdispositivo();
    final appSig = await getassinatura();

    return {
      'dispositivo': dispositivo,
      'assinatura': appSig,
      'nome': username,  
      'Content-Type': 'application/json',
    };
  }
}
