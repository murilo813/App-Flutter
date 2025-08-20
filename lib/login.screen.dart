import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'home_page.dart';
import 'package:android_id/android_id.dart';
import 'secrets.dart';
import 'background/pendents.dart';

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
    String? username = prefs.getString('username');
    String? appVersion = prefs.getString('app_version');

    if (loggedIn && username != null && idVendedor != null) {
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
    String? username = prefs.getString('username');
    String? appVersion = prefs.getString('app_version') ?? 'desconhecida';

    if (username == null) return;

    final now = DateTime.now().toIso8601String();
    final payload = {
      'nome': username,
      'hora_acesso': now,
      'versao_app': appVersion,
    };

    try {
      await http.post(
        Uri.parse('$baseUrl/uso'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      await OfflineQueue.addToQueue({
        'url': '/uso',
        'method': 'POST',
        'body': payload,
      });
    }
  }

  Future<void> saveLogin(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
  }

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();
      String? androidId = await getAndroidId();

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nome': username,
            'senha': password,
          }),
        );
        print('Corpo enviado: ${jsonEncode({
          'nome': username,
          'senha': password,
        })}');

        if (response.statusCode == 200) {
          print('Resposta bruta: ${response.body}');
          final data = jsonDecode(response.body);
          print('id_vendedor: ${data['id_vendedor']} (${data['id_vendedor'].runtimeType})');
          int idVendedor = data['id_vendedor'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', username);
          await prefs.setInt('id_vendedor', idVendedor);

          if (androidId != null) {
            await http.post(
              Uri.parse('$baseUrl/registrar_dispositivo'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'nome': username,
                'android_id': androidId,
              }),
            );
          }

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
      } catch (e) {
        _showError('Erro de conexão: $e');
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<String?> getAndroidId() async {
    final androidIdPlugin = AndroidId();
    try {
      String? androidId = await androidIdPlugin.getId();
      return androidId;
    } catch (e) {
      print('Erro ao obter Android ID: $e');
      return null;
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