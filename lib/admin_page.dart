import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/sync_service.dart';
import 'models/user.dart';
import 'secrets.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<User>> usuarios;
  late List<User> allUsuarios;
  late List<User> filteredUsuarios;
  late TextEditingController searchController;
  bool isSyncing = false;
  final SyncService syncService = SyncService();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    usuarios = Future.value([]);
    allUsuarios = [];
    filteredUsuarios = [];
    checkConnectionAndLoadData();
  }

  Future<bool> hasInternetConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/ping'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkConnectionAndLoadData() async {
    final temInternet = await hasInternetConnection();

    Future<void> carregarDadosLocais() async {
      final localData = await syncService.lerUsersLocal();
      if (localData != null) {
        List<User> localUsuarios =
            (localData['data'] as List).map((j) => User.fromJson(j)).toList();
        setState(() {
          usuarios = Future.value(localUsuarios);
          allUsuarios = localUsuarios;
          filteredUsuarios = localUsuarios;
        });
      }
    }

    if (!temInternet) {
      await carregarDadosLocais();
    } else {
      setState(() => isSyncing = true);
      await syncService.syncUsers();
      await carregarDadosLocais();
      setState(() => isSyncing = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Administração"), centerTitle: true),
      body: Column(
        children: [
          if (isSyncing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Sincronizando...",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          // pesquisa
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar usuário',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          // cards
          Expanded(
            child: FutureBuilder<List<User>>(
              future: usuarios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(child: Text("Erro: ${snapshot.error}"));
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return Center(child: Text("Nenhum usuário disponível"));

                final data = filteredUsuarios.isNotEmpty
                    ? filteredUsuarios
                    : snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final u = data[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // tipo de usuario
                                CircleAvatar(
                                  backgroundColor: u.tipo_usuario.toLowerCase() == 'admin'
                                      ? Colors.green.shade100
                                      : Colors.blue.shade50,
                                  child: Image.asset(
                                    u.tipo_usuario.toLowerCase() == 'admin'
                                        ? 'assets/icons/adminicon.png'
                                        : 'assets/icons/usericon.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.person, color: Colors.grey),
                                  ),
                                ),
                                SizedBox(width: 12),
                                // infos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.nomeclatura,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text("${u.usuario} | ${'*' * 8}"),
                                      Text(
                                        "${_nomeEmpresa(u.id_empresa)} | Vendedor: ${u.id_vendedor}",
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // id
                          Positioned(
                            top: 4,
                            left: 8,
                            child: Text(
                              u.id.toString(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600]),
                            ),
                          ),
                          // editar
                          Positioned(
                            top: 4,
                            right: 8,
                            child: IconButton(
                              icon: Icon(Icons.edit, size: 18, color: Colors.grey[700]),
                              onPressed: () {
                                int registrarNovoDisp = u.registrar_novo_disp;
                                TextEditingController senhaController = TextEditingController();
                                TextEditingController vendedorController = TextEditingController(text: u.id_vendedor.toString());
                                TextEditingController novoDispController = TextEditingController(text: registrarNovoDisp.toString());
                                bool senhaVisivel = false;

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
                                                // Título
                                                Text(
                                                  "Editar Usuário",
                                                  style: TextStyle(
                                                      fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                                Divider(height: 20),

                                                // ID pequeno acima do nome com espaçamento menor
                                                Text(
                                                  u.id.toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[600]),
                                                ),
                                                SizedBox(height: 2), // espaçamento reduzido

                                                // Nome e ícone do tipo à direita, empresa abaixo do nome
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            u.nomeclatura,
                                                            style: TextStyle(
                                                                fontSize: 22,
                                                                fontWeight: FontWeight.bold),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            _nomeEmpresa(u.id_empresa),
                                                            style: TextStyle(
                                                                fontSize: 16, color: Colors.grey[700]),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    CircleAvatar(
                                                      backgroundColor: u.tipo_usuario.toLowerCase() == 'admin'
                                                          ? Colors.green.shade100
                                                          : Colors.blue.shade50,
                                                      child: Image.asset(
                                                        u.tipo_usuario.toLowerCase() == 'admin'
                                                            ? 'assets/icons/adminicon.png'
                                                            : 'assets/icons/usericon.png',
                                                        width: 24,
                                                        height: 24,
                                                        errorBuilder: (_, __, ___) =>
                                                            Icon(Icons.person, color: Colors.grey),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(height: 16),

                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // Nova senha com botão de olho
                                                        Text("Nova Senha",
                                                            style:
                                                                TextStyle(fontWeight: FontWeight.bold)),
                                                        SizedBox(height: 4),
                                                        TextField(
                                                          controller: senhaController,
                                                          obscureText: !senhaVisivel,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12)),
                                                            hintText: "Digite a nova senha",
                                                            suffixIcon: IconButton(
                                                              icon: Icon(
                                                                senhaVisivel
                                                                    ? Icons.visibility
                                                                    : Icons.visibility_off,
                                                                color: Colors.grey[700],
                                                              ),
                                                              onPressed: () {
                                                                setStateDialog(() {
                                                                  senhaVisivel = !senhaVisivel;
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(height: 16),

                                                        // Vendedor (abaixo da senha) como TextField editável
                                                        Text("Vendedor",
                                                            style:
                                                                TextStyle(fontWeight: FontWeight.bold)),
                                                        SizedBox(height: 4),
                                                        TextField(
                                                          controller: vendedorController,
                                                          keyboardType: TextInputType.number,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                        ),
                                                        SizedBox(height: 16),

                                                        // Novo dispositivo como TextField
                                                        Text("Novo Dispositivo",
                                                            style:
                                                                TextStyle(fontWeight: FontWeight.bold)),
                                                        SizedBox(height: 4),
                                                        TextField(
                                                          controller: novoDispController,
                                                          keyboardType: TextInputType.number,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12)),
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
                                                      onPressed: () {
                                                        print(
                                                            "Nova senha: ${senhaController.text}, Vendedor: ${vendedorController.text}, Novo dispositivo: ${novoDispController.text}");
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
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
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
}