import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'login.screen.dart';
import 'store_page.dart';
import 'carteira.dart';
import 'secrets.dart';
import 'local_log.dart';
import 'log_page.dart';
import 'services/anniversary.dart';
import 'models/clientes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _titleTapCount = 0;
  
  @override
  void initState() {
    super.initState();

    (() async {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

      if (!isAllowed) {
        isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      if (isAllowed) {
        await AnniversaryService.checkAndNotify();
      }

      await anniversaryModal();
    })();
  }

  Future<void> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    int? idVendedor = prefs.getInt('id_vendedor');

    if (!loggedIn || idVendedor == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      await checkAppVersion();
    }
  }

  Future<void> anniversaryModal() async {
    final prefs = await SharedPreferences.getInstance();
    final hojeStr = DateTime.now().toIso8601String().substring(0, 10);

    final jaExibido = prefs.getBool('aniversario_ja_exibido') ?? false;
    if (jaExibido) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/clientes.json');

      if (!await file.exists()) return;

      final content = await file.readAsString();
      final jsonMap = json.decode(content);

      if (jsonMap['data'] is! List) return;

      final clientes = jsonMap['data']
          .map<Cliente>((e) => Cliente.fromJson(e))
          .toList();

      final hoje = DateTime.now();
      final aniversariantes = clientes.where((c) =>
        c.data_nasc != null &&
        c.data_nasc!.day == hoje.day &&
        c.data_nasc!.month == hoje.month
      ).toList();

      if (aniversariantes.isEmpty) return; 

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Aniversariantes de hoje 🎉'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: aniversariantes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.cake, color: Colors.pink),
                    title: Text(aniversariantes[index].nomeCliente),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );

      await prefs.setBool('aniversario_ja_exibido', true);
    } catch (e, stack) {
      print('Erro ao exibir aniversariantes: $e\n$stack');
    }
  }

  Future<void> checkAppVersion() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    try {
      final response = await http
        .get(Uri.parse('${backendUrl}versao-atual'))
        .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Resposta da versão: $json');
        final latestVersion = json['version'];

        final prefs = await SharedPreferences.getInstance();
        final currentVersion = prefs.getString('app_version');

        if (latestVersion != currentVersion && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Atualização disponível'),
              content: Text(
                'Uma nova versão do app está disponível.\n\n'
                'Versão atual: $currentVersion\n'
                'Nova versão: $latestVersion\n\n'
                'Clique no botão abaixo para ser redirecionado ao link de atualização.',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await openURL();
                    Navigator.of(context).pop(); 
                  },
                  child: const Text('Atualizar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro na checagem de versão: $e\nStackTrace: $stack');
      print('Erro ao verificar versão: $e');
    }
  }

  Future<void> openURL() async {
    const url = 'https://murilo813.github.io/AtualizadorAPP/';
    await openInChrome(url);
  }

  Future<void> openInChrome(String url) async {
    const platform = MethodChannel('abrir_chrome');

    try {
      await platform.invokeMethod('abrirNoChrome', {'url': url});
    } on PlatformException catch (e) {
      print('Erro ao abrir no Chrome: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _titleTapCount++;
                      if (_titleTapCount >= 6) {
                        _titleTapCount = 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LogViewerPage()),
                        );
                      }
                    });
                  },
                  child: const Text(
                    'AgroZecão',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                _buildHomeButton(
                  context: context,
                  label: 'Estoque',
                  page: StorePage(storeName: 'Estoques'),
                ),
                _buildHomeButton(
                  context: context,
                  label: 'Meus Clientes',
                  page: CarteiraPage(),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear(); // apaga o shared preferences
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton({
    required BuildContext context,
    required String label,
    required Widget page,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 250,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: color ?? Colors.green[700],
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}