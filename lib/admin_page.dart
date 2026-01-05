import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'services/sync_service.dart';
import 'services/http_client.dart';
import 'background/pendents.dart';
import 'background/local_log.dart';
import 'widgets/loading.dart';
import 'widgets/error.dart';
import 'models/user.dart';
import 'secrets.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool loading = true;
  bool erroCritico = false;
  String? mensagemErro;
  late List<User> allUsuarios;
  late List<User> filteredUsuarios;
  late TextEditingController searchController;

  final SyncService syncService = SyncService();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    allUsuarios = [];
    filteredUsuarios = [];
    checkConnectionAndLoadData();
  }

  Future<bool> hasInternetConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/ping'))
          .timeout(const Duration(seconds: 7));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> carregarDadosLocais() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');

      if (!await file.exists()) {
        await LocalLogger.log(
          'Offline e sem cache: users.json não encontrado',
        );

        setState(() {
          allUsuarios = [];
          filteredUsuarios = [];
        });
        return;
      }

      final content = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(content);

      final List<User> localUsuarios =
          (jsonData['data'] as List).map((j) => User.fromJson(j)).toList();

      setState(() {
        allUsuarios = localUsuarios;
        filteredUsuarios = localUsuarios;
      });
    } catch (e, stack) {
      await LocalLogger.log(
        'Erro ao carregar usuários locais\nErro: $e\nStack: $stack',
      );

      setState(() {
        allUsuarios = [];
        filteredUsuarios = [];
      });
    }
  }

  Future<void> checkConnectionAndLoadData() async {
    setState(() {
      loading = true;
      erroCritico = false;
    });

    try {
      final temInternet = await hasInternetConnection();

      if (temInternet) {
        try {
          await syncService.syncUsers();
        } catch (e, stack) {
          await LocalLogger.log(
            'Erro na sincronização de usuários\nErro: $e\nStack: $stack',
          );
        }

        await carregarDadosLocais();
      } else {
        await carregarDadosLocais();
      }

      if (allUsuarios.isEmpty) {
        setState(() {
          erroCritico = true;
        });
        return;
      }
    } catch (e, stack) {
      await LocalLogger.log(
        'Erro crítico em AdminPage\nErro: $e\nStack: $stack',
      );
      setState(() {
        erroCritico = true; 
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Loading(
          icon: Icons.admin_panel_settings,
          color: Colors.deepPurple,
        ),
      );
    }
    if (erroCritico) {
      return ErrorScreen(
        onRetry: checkConnectionAndLoadData, 
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Administração"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar usuário',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {
                setState(() {
                  filteredUsuarios = allUsuarios
                      .where((u) =>
                          u.usuario.toLowerCase().contains(q.toLowerCase()))
                      .toList();
                });
              },
            ),
          ),
          Expanded(
            child: filteredUsuarios.isEmpty
                ? Center(child: Text("Nenhum usuário disponível"))
                : SafeArea(
                    bottom: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredUsuarios.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filteredUsuarios.length) {
                          return GestureDetector(
                            onTap: () => _abrirDialogNovoUsuario(),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "Novo Usuário",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final u = filteredUsuarios[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: u.ativo == 'N' ? Colors.grey.shade800 : null, 
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          u.tipo_usuario.toLowerCase() == 'admin'
                                              ? Colors.green.shade100
                                              : Colors.blue.shade50,
                                      child: Image.asset(
                                        u.tipo_usuario.toLowerCase() == 'admin'
                                            ? 'assets/icons/adminicon.png'
                                            : 'assets/icons/usericon.png',
                                        width: 24,
                                        height: 24,
                                        errorBuilder: (_, __, ___) => Icon(Icons.person, color: Colors.grey),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.nomeclatura,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: u.ativo == 'N' ? Colors.white70 : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "${u.usuario} | ${'*' * 8}",
                                            style: TextStyle(
                                              color: u.ativo == 'N' ? Colors.white54 : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            "${_nomeEmpresa(u.id_empresa)} | Vendedor: ${u.id_vendedor}",
                                            style: TextStyle(
                                              color: u.ativo == 'N' ? Colors.white54 : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (u.ativo == 'N') 
                                Positioned.fill(
                                  child: Center(
                                    child: Icon(
                                      Icons.lock,
                                      color: Colors.grey.shade600,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                left: 8,
                                child: Text(
                                  u.id.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(Icons.edit,
                                      size: 18, color: Colors.grey[700]),
                                  onPressed: () => _abrirDialogEditarUsuario(u), 
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          )
        ],
      ),
    );
  }

  String _nomeEmpresa(int idEmpresa) {
    switch (idEmpresa) {
      case 1:
        return "Bela Vista";
      case 2:
        return "Imbuia";
      case 3:
        return "Vila Nova";
      case 4:
        return "Aurora";
      default:
        return "Desconhecida";
    }
  }

  void _mostrarAvisoIdVendedor(String mensagem) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _abrirDialogNovoUsuario() {
    TextEditingController idEmpresaController = TextEditingController();
    TextEditingController usuarioController = TextEditingController();
    TextEditingController senhaController = TextEditingController();
    TextEditingController nomeclaturaController = TextEditingController();
    TextEditingController idVendedorController = TextEditingController();
    TextEditingController creditoDispController = TextEditingController();
    String tipoUsuario = "user";
    bool senhaVisivel = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Novo Usuário",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Divider(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // id empresa
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: idEmpresaController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Id Empresa",
                                ),
                              ),
                            ),
                            // usuario
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: usuarioController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Usuário",
                                ),
                              ),
                            ),
                            // senha
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: senhaController,
                                obscureText: !senhaVisivel,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Senha",
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      senhaVisivel ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        senhaVisivel = !senhaVisivel;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            // nomeclatura
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: nomeclaturaController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Nomeclatura",
                                ),
                              ),
                            ),
                            // id vendedor
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: idVendedorController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Id Vendedor",
                                ),
                                onTap: () {
                                  _mostrarAvisoIdVendedor(
                                    "Id = 0 não puxa nenhum cliente, Id = 1 puxa todos os clientes."
                                  );
                                },
                              ),
                            ),
                            // credito
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: creditoDispController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  labelText: "Crédito para novos dispositivos",
                                ),
                              ),
                            ),
                            // tipo de usuario
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(() => tipoUsuario = "user"),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: tipoUsuario == "user"
                                              ? Colors.blue.shade100
                                              : Colors.transparent,
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person,
                                                color: tipoUsuario == "user"
                                                    ? Colors.blue
                                                    : Colors.grey),
                                            SizedBox(width: 8),
                                            Text("User",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: tipoUsuario == "user"
                                                        ? Colors.blue
                                                        : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(() => tipoUsuario = "admin"),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: tipoUsuario == "admin"
                                              ? Colors.green.shade100
                                              : Colors.transparent,
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.admin_panel_settings,
                                                color: tipoUsuario == "admin"
                                                    ? Colors.green
                                                    : Colors.grey),
                                            SizedBox(width: 8),
                                            Text("Admin",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: tipoUsuario == "admin"
                                                        ? Colors.green
                                                        : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancelar"),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final body = {
                              "id_empresa": int.parse(idEmpresaController.text),
                              "nome": usuarioController.text.trim(),
                              "senha": senhaController.text.trim(),
                              "nomeclatura": nomeclaturaController.text.trim(),
                              "id_vendedor": int.parse(idVendedorController.text),
                              "registrar_novo_disp": int.parse(creditoDispController.text),
                              "tipo_usuario": tipoUsuario,
                            };

                            // validação
                            if ((body["nome"] as String).isEmpty ||
                                (body["senha"] as String).isEmpty ||
                                (body["nomeclatura"] as String).isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Preencha todos os campos obrigatórios")),
                              );
                              return;
                            }

                            final httpClient = HttpClient();
                            final url = "/usuarios";
                            final nextId = allUsuarios.isNotEmpty
                              ? allUsuarios.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1
                              : 1;

                            // cria na memoria para UI
                            final newUser = User(
                              id: nextId,
                              id_empresa: body["id_empresa"] as int,
                              usuario: body["nome"] as String,
                              id_vendedor: body["id_vendedor"] as int,
                              registrar_novo_disp: body["registrar_novo_disp"] as int,
                              tipo_usuario: body["tipo_usuario"] as String,
                              nomeclatura: body["nomeclatura"] as String,
                            );

                            setState(() {
                              allUsuarios.add(newUser);
                              filteredUsuarios = List<User>.from(allUsuarios);
                            });

                            // atualiza banco local
                            final dir = await getApplicationDocumentsDirectory();
                            final file = File('${dir.path}/users.json');
                            if (await file.exists()) {
                              final content = await file.readAsString();
                              final Map<String, dynamic> jsonData = json.decode(content);
                              final usersList = jsonData['data'] as List;
                              usersList.add(body);
                              await file.writeAsString(json.encode(jsonData));
                            }

                            // envia pro back, se não tem conexão salva no pendent
                            try {
                              final response = await httpClient.post(url, body);
                              if (response.statusCode == 200) {
                                print("Usuário criado com sucesso!");
                              } else {
                                print("Erro do servidor: ${response.body}");
                              }
                            } catch (e) {
                              await OfflineQueue.addToQueue({'url': url, 'body': body});
                              print("Sem conexão, criação salva no pendente.");
                            }

                            Navigator.pop(context);
                          },
                          child: Text("Salvar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _abrirDialogEditarUsuario(User u) {
    int registrarNovoDisp = u.registrar_novo_disp;
    TextEditingController senhaController = TextEditingController();
    TextEditingController vendedorController =
        TextEditingController(text: u.id_vendedor.toString());
    TextEditingController novoDispController =
        TextEditingController(text: registrarNovoDisp.toString());
    bool senhaVisivel = false;

    String tipoUsuario = (u.tipo_usuario.toLowerCase() == "admin") ? "admin" : "user";

    String ativoLocal = (u.ativo?.trim().toUpperCase() == 'S') ? 'S' : 'N';
    
    print('Usuário ${u.id} ativo: "${u.ativo}", ativoLocal inicial: $ativoLocal');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Editar Usuário",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Divider(height: 20),
                    Text(u.id.toString(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600])),
                    SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.nomeclatura,
                                  style: TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text(_nomeEmpresa(u.id_empresa),
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Senha
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: senhaController,
                                obscureText: !senhaVisivel,
                                decoration: InputDecoration(
                                  labelText: "Nova Senha",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(senhaVisivel
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setStateDialog(() {
                                        senhaVisivel = !senhaVisivel;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            // Vendedor
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: vendedorController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Vendedor",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onTap: () {
                                  _mostrarAvisoIdVendedor(
                                    "Id = 0 não puxa nenhum cliente, Id = 1 puxa todos os clientes."
                                  );
                                },
                              ),
                            ),
                            // Novo dispositivo
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: novoDispController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Novo Dispositivo",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            // Tipo de usuário
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(
                                          () => tipoUsuario = "user"),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: tipoUsuario == "user"
                                              ? Colors.blue.shade100
                                              : Colors.transparent,
                                          border: Border.all(
                                              color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person,
                                                color: tipoUsuario == "user"
                                                    ? Colors.blue
                                                    : Colors.grey),
                                            SizedBox(width: 8),
                                            Text("User",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: tipoUsuario == "user"
                                                        ? Colors.blue
                                                        : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(
                                          () => tipoUsuario = "admin"),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: tipoUsuario == "admin"
                                              ? Colors.green.shade100
                                              : Colors.transparent,
                                          border: Border.all(
                                              color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.admin_panel_settings,
                                                color: tipoUsuario == "admin"
                                                    ? Colors.green
                                                    : Colors.grey),
                                            SizedBox(width: 8),
                                            Text("Admin",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: tipoUsuario == "admin"
                                                        ? Colors.green
                                                        : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(() => ativoLocal = 'S'), 
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: ativoLocal == 'S' ? Colors.green.shade200 : Colors.transparent,
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "ATIVO",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: ativoLocal == 'S' ? Colors.green.shade800 : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(() => ativoLocal = 'N'), 
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: ativoLocal == 'N' ? Colors.red.shade200 : Colors.transparent,
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "INATIVO",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: ativoLocal == 'N' ? Colors.red.shade800 : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancelar"),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            Map<String, dynamic> body = {};
                            if (senhaController.text.isNotEmpty) {
                              body['senha'] = senhaController.text;
                            }
                            if (vendedorController.text != u.id_vendedor.toString()) {
                              body['id_vendedor'] =
                                  int.tryParse(vendedorController.text);
                            }
                            if (novoDispController.text !=
                                u.registrar_novo_disp.toString()) {
                              body['registrar_novo_disp'] =
                                  int.tryParse(novoDispController.text);
                            }

                            body['tipo_usuario'] = tipoUsuario; 

                            body['ativo'] = ativoLocal;

                            if (body.isEmpty) {
                              Navigator.pop(context);
                              return;
                            }

                            final httpClient = HttpClient();
                            final url = "/usuarios/${u.id}";

                            // Atualiza memória
                            final index =
                                allUsuarios.indexWhere((usr) => usr.id == u.id);
                            if (index != -1) {
                              final oldUser = allUsuarios[index];
                              final updatedUser = User(
                                id: oldUser.id,
                                id_empresa: oldUser.id_empresa,
                                usuario: oldUser.usuario,
                                id_vendedor:
                                    body['id_vendedor'] ?? oldUser.id_vendedor,
                                registrar_novo_disp:
                                    body['registrar_novo_disp'] ??
                                        oldUser.registrar_novo_disp,
                                tipo_usuario: tipoUsuario,
                                nomeclatura: oldUser.nomeclatura,
                                ativo: body['ativo'] ?? oldUser.ativo,
                              );

                              setState(() {
                                allUsuarios[index] = updatedUser;
                                final fIndex =
                                    filteredUsuarios.indexWhere((usr) => usr.id == u.id);
                                if (fIndex != -1)
                                  filteredUsuarios[fIndex] = updatedUser;
                              });
                            }

                            // Atualiza local
                            final dir = await getApplicationDocumentsDirectory();
                            final file = File('${dir.path}/users.json');
                            if (await file.exists()) {
                              final content = await file.readAsString();
                              final Map<String, dynamic> jsonData = json.decode(content);
                              final usersList = jsonData['data'];
                              final jsonIndex =
                                  usersList.indexWhere((item) => item['id'] == u.id);
                              if (jsonIndex != -1) {
                                body.forEach((key, value) {
                                  usersList[jsonIndex][key] = value;
                                });
                                await file.writeAsString(json.encode(jsonData));
                              }
                            }

                            // Atualiza backend
                            try {
                              final response = await httpClient.patch(url, body);
                              if (response.statusCode == 200) {
                                print("Alterações salvas com sucesso!");
                              } else {
                                print("Erro do servidor: ${response.body}");
                              }
                            } catch (e) {
                              await OfflineQueue.addToQueue({'url': url, 'body': body});
                              print("Sem conexão, alteração salva no pendente.");
                            }

                            Navigator.pop(context);
                          },
                          child: Text("Salvar"),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}