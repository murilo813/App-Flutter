import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:flutter/services.dart';

import 'background/pendents.dart';
import 'services/http_client.dart';
import 'widgets/loading.dart';
import 'widgets/gradientgreen.dart';
import 'home_page.dart';
import 'secrets.dart';

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
  String? loginError;
  String? networkError;

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
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final idVendedor = prefs.getInt('id_vendedor');
    final idUsuario = prefs.getString('id_usuario');

    if (!mounted) return;

    if (loggedIn && idUsuario != null && idVendedor != null) {
      await registrarUso();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() {
        _checkingLogin = false;
      });
    }
  }


  Future<void> registrarUso() async {
    final prefs = await SharedPreferences.getInstance();
    final String appVersion = prefs.getString('app_version') ?? 'desconhecida';

    final now = DateTime.now().toIso8601String();
    final payload = {
      'hora_acesso': now,
      'versao_app': appVersion,
    };


    try {
      final httpClient = HttpClient();
      await httpClient.post('/uso', payload);
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

    setState(() {
      isLoading = true;
      loginError = null;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final androidIdPlugin = const AndroidId();
      final dispositivo = await androidIdPlugin.getId() ?? 'unknown';

      const platform = MethodChannel('app_signature_channel');
      final assinatura = await platform.invokeMethod<String>('getassinatura') ?? 'unknown';

      final body = {
        'nome': username,
        'senha': password,
        'dispositivo': dispositivo,
        'assinatura': assinatura,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Tempo de conexão esgotado');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int idVendedor = data['id_vendedor'];
        final idUsuario = data['id_usuario'].toString();
        final tipoUsuario = data['tipo'];
        final idEmpresa = data['id_empresa'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('id_usuario', idUsuario);
        await prefs.setInt('id_vendedor', idVendedor);
        await prefs.setString('dispositivo', dispositivo);
        await prefs.setString('assinatura', assinatura);
        await prefs.setString('tipo_usuario', tipoUsuario);
        await prefs.setInt('id_empresa', idEmpresa);

        await registrarUso();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } 
      // senha ou usuário incorreto
      else if (response.statusCode == 401 || response.statusCode == 404) {
        setState(() {
          loginError = 'Usuário ou senha inválidos';
        });
      } 

      else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        final detail = data['detail'] ?? '';

        setState(() {
          if (detail.contains('Dispositivo')) {
            loginError =
              'Este dispositivo não está autorizado.\n'
              'Por favor, contate o administrador.';
          } else if (detail.contains('desativado')) {
            loginError =
              'Seu usuário foi desativado.\n'
              'Por favor, contate o administrador.';
          } else {
            loginError = 'Acesso não permitido.';
          }
        });
      }
      
      else if (response.statusCode == 409) {
        setState(() {
          loginError = 
            'Você não pode registrar mais dispositivos. \n' 
            'Por favor, contato o administrador.';
        });
      }
      else if (response.statusCode == 422) {
        setState(() {
          loginError = 
            'Aplicativo violado!';
        });
      }
      // outros status do servidor (500, 502, etc) → modal de conexão
      else {
        _showConnectionError('Não foi possível conectar ao servidor.');
      }
    } 
    // problemas de rede real
    on SocketException {
      _showConnectionError('Sem conexão com a internet.');
    } 
    on TimeoutException {
      _showConnectionError('Tempo de conexão esgotado.');
    } 
    catch (e) {
      _showConnectionError('Erro de conexão. Tente novamente.');
    } 
    finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _verificarAtualizacaoApp() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    final versaoAtual = packageInfo.version;
    final versaoSalva = prefs.getString('app_version');

    if (versaoSalva == null || versaoSalva != versaoAtual) {
      await prefs.setString('app_version', versaoAtual);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return const Loading(
        child: Image(
          image: AssetImage('assets/icons/iconWhite.png'),
          width: 80,
          height: 80,
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GradientGreen.primary,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ÍCONE
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: GradientGreen.accent,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Image(
                          image: AssetImage('assets/icons/iconWhite.png'),
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 16),

                      ShaderMask(
                        shaderCallback: (bounds) =>
                            GradientGreen.accent.createShader(bounds),
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 2), 
                          child: Text(
                            'AgroZecão',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Faça login para continuar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _inputLabel('Nome de usuário'),
                      _inputField(
                        controller: _usernameController,
                        hint: 'Digite seu usuário',
                        obscure: false,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Digite o usuário' : null,
                      ),

                      const SizedBox(height: 16),

                      _inputLabel('Senha'),
                      _inputField(
                        controller: _passwordController,
                        hint: 'Digite sua senha',
                        obscure: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Digite a senha' : null,
                      ),

                      if (loginError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            loginError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 6),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: GradientGreen.accent,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _inputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: GradientGreen.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(1.5), 
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none, 
          ),
        ),
      ),
    );
  }
  void _showConnectionError(String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Sem conexão',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}