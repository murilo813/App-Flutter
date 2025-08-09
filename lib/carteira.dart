import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/sync_service.dart';
import '../models/clientes.dart';
import 'local_log.dart';

class CarteiraPage extends StatefulWidget {
  @override
  _CarteiraPageState createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  late Future<List<Cliente>> clientes;
  late List<Cliente> filteredClientes;
  late List<Cliente> allClientes = [];
  late TextEditingController searchController;
  String? ultimaAtualizacao;
  bool isSyncing = false;
  final SyncService syncService = SyncService();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredClientes = [];
    clientes = Future.value([]);
    checkConnectionAndLoadData();
    _verificarAvisoInicial();
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void checkConnectionAndLoadData() async {
    final temInternet = await hasInternetConnection();

    Future<void> carregarDadosLocais() async {
      try {
        final localData = await syncService.lerClientesLocal();
        if (localData != null) {
          List<Cliente> localClientes = (localData['data'] as List)
              .map((json) => Cliente.fromJson(json))
              .toList();
          setState(() {
            clientes = Future.value(localClientes);
            ultimaAtualizacao = localData['lastSynced'];
          });
        } else {
          await LocalLogger.log('Erro crítico: dados locais vazios');
          setState(() {
            clientes = Future.error('Sem dados locais disponíveis');
          });
        }
      } catch (e, stack) {
        await LocalLogger.log('Erro crítico ao carregar dados locais\nErro: $e\nStack: $stack');
        setState(() {
          clientes = Future.error('Erro ao carregar dados locais');
        });
      }
    }

    if (!temInternet) {
      print('Sem conexão — carregando clientes do local');
      await carregarDadosLocais();
    } else {
      print('Com conexão — sincronizando com a API');
      setState(() {
        isSyncing = true;
      });

      try {
        await syncService.syncClientes();
      } catch (e, stack) {
        print('Erro ao sincronizar clientes: $e');
        await LocalLogger.log('Erro na sincronização (rota com internet)\nErro: $e\nStack: $stack');
      }

      await carregarDadosLocais();

      setState(() {
        isSyncing = false;
      });
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
      appBar: AppBar(
        title: Text('Meus Clientes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (ultimaAtualizacao != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'Última atualização: ${_formatarData(ultimaAtualizacao!)}',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          if (isSyncing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Sincronizando...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterClientes,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Cliente>>(
              future: clientes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhum cliente disponível'));
                } else {
                  allClientes = snapshot.data!;
                  filteredClientes = _getFilteredClientes();

                  if (filteredClientes.isEmpty) {
                    return Center(child: Text('Nenhum cliente encontrado'));
                  }

                  return ListView.separated(
                    itemCount: filteredClientes.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final cliente = filteredClientes[index];
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente.nomeCliente,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (cliente.responsavel.isNotEmpty)
                              Text(
                                'Responsável: ${cliente.responsavel}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildLimitesTable(cliente),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitesTable(Cliente cliente) {
    return Row(
      children: [
        _buildColunaLimiteComLinhaInterna("Limite BM", cliente.limiteFormatado, cliente.limite, true),
        _buildColunaLimiteComLinhaInterna("Saldo BM", cliente.saldoFormatado, cliente.saldo_limite, true),
        _buildColunaLimiteComLinhaInterna("Limite C", cliente.limiteCFormatado, cliente.limite_calculado, true),
        _buildColunaLimiteComLinhaInterna("Saldo C", cliente.saldoCFormatado, cliente.saldo_limite_calculado, false),
      ],
    );
  }

  Widget _buildColunaLimiteComLinhaInterna(String titulo, String valorFormatado, double valorOriginal, bool temLinhaDireita) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: temLinhaDireita
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                valorFormatado,
                style: TextStyle(
                  fontSize: 14,
                  color: valorOriginal < 0 ? Colors.red : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Cliente> _getFilteredClientes() {
    final query = searchController.text.toLowerCase();
    return allClientes.where((c) => 
      c.nomeCliente.toLowerCase().contains(query) ||
      c.responsavel.toLowerCase().contains(query)
    ).toList();
  }

  void _filterClientes(String query) {
    setState(() {
      filteredClientes = _getFilteredClientes();
    });
  }

  void _mostrarAvisoInicial() {
    Future.delayed(Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Aviso importante'),
          content: Text(
            'Lembrando:\n\n'
            '• Limite e Saldo BM são os limites cadastrados no sistema.\n'
            '• Limite e Saldo C são calculados com base no último ano de compras do cliente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendi'),
            ),
          ],
        ),
      );
    });
  }

  void _verificarAvisoInicial() async {
    final prefs = await SharedPreferences.getInstance();
    final jaMostrou = prefs.getBool('aviso_mostrado') ?? false;

    if (!jaMostrou) {
      _mostrarAvisoInicial();

      await prefs.setBool('aviso_mostrado', true);
    }
  }

  String _formatarData(String dataIso) {
    final dt = DateTime.parse(dataIso).toLocal();
    return '${_doisDigitos(dt.day)}/${_doisDigitos(dt.month)}/${dt.year} às ${_doisDigitos(dt.hour)}:${_doisDigitos(dt.minute)}';
  }

  String _doisDigitos(int n) => n.toString().padLeft(2, '0');
}
