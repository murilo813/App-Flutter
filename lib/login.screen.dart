import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:flutter/services.dart';

import 'home_page.dart';
import 'secrets.dart';
import 'background/pendents.dart';
import 'services/http_client.dart';
import 'services/auth_headers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final String baseUrl = backendUrl;
  bool _checkingLogin = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _verificarAtualizacaoApp();
    await checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    int? idVendedor = prefs.getInt('id_vendedor');
    String? idUsuario = prefs.getString('id_usuario');
    String? appVersion = prefs.getString('app_version');

    if (loggedIn && idUsuario != null && idVendedor != null) {
      await registrarUso();
      Navigator.pushReplacement(
        context,
       MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      setState(() {
        _checkingLogin = false;
      });
    }
  }

  Future<void> registrarUso() async {
    final prefs = await SharedPreferences.getInstance();
    String? appVersion = prefs.getString('app_version') ?? 'desconhecida';

    final now = DateTime.now().toIso8601String();
    final payload = {
      'hora_acesso': now,
      'versao_app': appVersion,
    };


    try {
      final httpClient = HttpClient();
      final response = await httpClient.post('/uso', payload);
    } catch (e) {
      await OfflineQueue.addToQueue({
        'url': '/uso',
        'method': 'POST',
        'body': payload,
      });
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    try {
      final androidIdPlugin = AndroidId();
      final dispositivo = await androidIdPlugin.getId() ?? 'unknown';

      const platform = MethodChannel('app_signature_channel');
      final assinatura = await platform.invokeMethod<String>('getassinatura') ?? 'unknown';

      final body = {
        'nome': username,
        'senha': password,
        'dispositivo': dispositivo,
        'assinatura': assinatura,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int idVendedor = data['id_vendedor'];
        final idUsuario = data['id_usuario'].toString();
        final tipoUsuario = data['tipo'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('id_usuario', idUsuario);
        await prefs.setInt('id_vendedor', idVendedor);
        await prefs.setString('dispositivo', dispositivo);
        await prefs.setString('assinatura', assinatura);
        await prefs.setString('tipo_usuario', tipoUsuario);

        await registrarUso();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (response.statusCode == 401) {
        _showError('Usuário ou senha inválidos');
      } else if (response.statusCode == 429) {
        _showError('Muitas tentativas de login. Tente novamente em 5 minutos.');
      } else {
        _showError('Erro no servidor: ${response.body}');
      }
    } on SocketException {
      _showError('Sem conexão com a internet.');
    } catch (e, stack) {
      print('Exceção capturada no login: $e\nStackTrace: $stack');
      _showError('Erro de conexão: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _verificarAtualizacaoApp() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    final versaoAtual = packageInfo.version;
    final versaoSalva = prefs.getString('app_version');
    print(versaoAtual);
    print(versaoSalva);

    if (versaoSalva == null || versaoSalva != versaoAtual) {
      print('App atualizado: limpando SharedPreferences...');
      
      await prefs.clear(); 
      
      await prefs.setString('app_version', versaoAtual);
    } else {
      print('App não foi atualizado. SharedPreferences mantido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return Scaffold(
        backgroundColor: Color(0xFF2E2E2E),
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent[700]),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFF2E2E2E),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AGROZECÃO',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.greenAccent[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Login',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Nome de usuário',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Digite o nome de usuário' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Digite a senha' : null,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'ENTRAR',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}