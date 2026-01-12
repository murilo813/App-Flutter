import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'background/local_log.dart';
import 'services/http_client.dart';
import 'models/client.dart';
import 'widgets/gradientgreen.dart';
import 'widgets/loading.dart';
import 'login.screen.dart';
import 'store_page.dart';
import 'clients_page.dart';
import 'order_page.dart';
import 'admin_page.dart';
import 'debug_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _inicializado = false;
  int _titleTapCount = 0;
  int? _idEmpresa;
  String? _tipoUsuario;

  final Map<int, String> empresas = {
    1: 'Bela Vista',
    2: 'Imbuia',
    3: 'Vila Nova',
    4: 'Aurora',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    _tipoUsuario = prefs.getString('tipo_usuario');
    _idEmpresa = prefs.getInt('id_empresa');

    await anniversaryModal();
    await checkAppVersion();

    if (mounted) {
      setState(() {
        _inicializado = true;
      });
    }
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

  Future<void> anniversaryModal({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime.now().toIso8601String().substring(0, 10);

    final jaExibido = prefs.getBool('aniversario_ja_exibido') ?? false;
    if (jaExibido && !force) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/clientes.json');

      if (!await file.exists()) return;

      final content = await file.readAsString();
      final jsonMap = json.decode(content);

      if (jsonMap['data'] is! List) return;

      final clientes =
          jsonMap['data'].map<Cliente>((e) => Cliente.fromJson(e)).toList();

      final hoje = DateTime.now();
      final aniversariantes =
          clientes
              .where(
                (c) =>
                    c.data_nasc != null &&
                    c.data_nasc!.day == hoje.day &&
                    c.data_nasc!.month == hoje.month,
              )
              .toList();

      if (aniversariantes.isEmpty) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aniversariantes de hoje 🎉'),
                const SizedBox(height: 8),
                const Text(
                  'Por favor, verifique se é realmente o aniversário do cliente',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
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
      final httpClient = HttpClient();
      final response = await httpClient
          .get('/versao')
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Resposta da versão: $json');

        final latestVersion = json['versao'];
        final status = json['status'];

        final prefs = await SharedPreferences.getInstance();
        final currentVersion = prefs.getString('app_version');

        if (status == "INATIVO" && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => AlertDialog(
                  title: const Text('Acesso Negado'),
                  content: const Text(
                    'Seu usuário foi desativado. Você não tem mais acesso a este aplicativo.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await prefs.clear();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

        if (latestVersion != currentVersion && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => AlertDialog(
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
      await LocalLogger.log(
        'Erro na checagem de versão: $e\nStackTrace: $stack',
      );
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
    if (!_inicializado) {
      return const Loading(
        child: Image(
          image: AssetImage('assets/icons/iconWhite.png'),
          width: 80,
          height: 80,
        ),
      );
    }
    String empresaNome = _idEmpresa != null ? empresas[_idEmpresa!]! : '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // ÍCONE
              GestureDetector(
                onTap: _onLogoTapped,
                child: Container(
                  width: 100,
                  height: 100,
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
                    width: 75,
                    height: 75,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // TÍTULO
              ShaderMask(
                shaderCallback:
                    (bounds) => GradientGreen.accent.createShader(bounds),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'AgroZecão',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Agropecuária Zecão $empresaNome',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 40),

              // CARDS
              _homeCard(
                icon: Icons.inventory_2_outlined,
                title: 'Estoque',
                subtitle: 'Estoque, disponível, preço',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StorePage()),
                    ),
              ),

              _homeCard(
                icon: Icons.people_outline,
                title: 'Meus Clientes',
                subtitle: 'Limites, observações',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClientsPage()),
                    ),
              ),

              _homeCard(
                icon: Icons.shopping_cart_outlined,
                title: 'Pedidos',
                subtitle: 'Envie pedidos de produtos',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrdersPage()),
                    ),
              ),

              if (_tipoUsuario == 'admin')
                _homeCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin',
                  subtitle: 'Painel administrativo',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminPage()),
                      ),
                ),

              const Spacer(),

              // BOTÃO SAIR
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sair',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _onLogoTapped() {
    _titleTapCount++;

    if (_titleTapCount >= 6) {
      _titleTapCount = 0;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DebugPage()),
      );
    }
  }

  Widget _homeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: GradientGreen.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}