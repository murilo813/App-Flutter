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
      appBar: AppBar(title: Text("Admin - Usuários"), centerTitle: true),
      body: Column(
        children: [
          if (isSyncing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Sincronizando...",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar usuário',
                border: OutlineInputBorder(),
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

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("id")),
                      DataColumn(label: Text("emp")),
                      DataColumn(label: Text("usuario")),
                      DataColumn(label: Text("id vend.")),
                      DataColumn(label: Text("novo disp.")),
                      DataColumn(label: Text("tipo")),
                    ],
                    rows: data
                        .map((u) => DataRow(cells: [
                              DataCell(Text(u.id.toString())),
                              DataCell(Text(u.id_empresa.toString())),
                              DataCell(Text(u.usuario)),
                              DataCell(Text(u.id_vendedor.toString())),
                              DataCell(Text(u.registrar_novo_disp.toString())),
                              DataCell(Text(u.tipo_usuario)),
                            ]))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
