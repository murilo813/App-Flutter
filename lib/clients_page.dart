import 'dart:io';
import 'dart:convert'; 

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '/services/sync_service.dart';
import '/services/http_client.dart';
import 'background/local_log.dart';
import 'background/pendents.dart';
import 'models/client.dart'; 
import 'models/obs.dart';
import 'secrets.dart';

class ClientsPage extends StatefulWidget {
  final bool modoSelecao;

  ClientsPage({this.modoSelecao = false});

  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late Future<List<Cliente>> clientes;
  late List<Cliente> filteredClientes;
  late List<Cliente> allClientes = [];
  late List<Map<String, dynamic>> allObs = [];
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
      final response = await http
          .get(Uri.parse('$backendUrl/ping'))
          .timeout(const Duration(seconds: 7));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkConnectionAndLoadData() async {
    final temInternet = await hasInternetConnection();

    Future<void> carregarDadosLocais() async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/clientes.json');

        if (await file.exists()) {
          final content = await file.readAsString();
          final Map<String, dynamic> jsonData = json.decode(content);

          List<Cliente> localClientes = (jsonData['data'] as List)
              .map((json) => Cliente.fromJson(json))
              .toList();

          String ultimaAtualizacao = jsonData['lastSynced'] ?? '';

          setState(() {
            clientes = Future.value(localClientes);
            allClientes = localClientes;
            filteredClientes = localClientes;
            this.ultimaAtualizacao = ultimaAtualizacao;
          });

          try {
            final obsFile = File('${dir.path}/observacoes.json');
            if (await obsFile.exists()) {
              final obsContent = await obsFile.readAsString();
              final Map<String, dynamic> obsData = json.decode(obsContent);
              setState(() {
                allObs = List<Map<String, dynamic>>.from(obsData['data'] ?? []);
              });
              print('Observações locais carregadas (${allObs.length})');
            } else {
              print('Arquivo de observações não encontrado localmente.');
            }
          } catch (e) {
            print('Erro ao carregar observações locais: $e');
          }

        } else {
          await LocalLogger.log('Erro crítico: arquivo clientes.json não existe');
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
        await syncService.syncObservacoes();

        await carregarDadosLocais();
      } catch (e, stack) {
        print('Erro ao sincronizar dados: $e');
        await LocalLogger.log('Erro na sincronização (rota com internet)\nErro: $e\nStack: $stack');
        await carregarDadosLocais();
      }

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
      body: Stack(
        children: [
          Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    const Text('0–10 dias'),
                    const SizedBox(width: 16),
                    Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 4),
                    const Text('11–25 dias'),
                    const SizedBox(width: 16),
                    Icon(Icons.info_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 4),
                    const Text('+25 dias'),
                  ],
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

                      filteredClientes.sort((a, b) {
                        DateTime? refA;
                        DateTime? refB;

                        final obsA = allObs
                            .where((o) => o['responsavel'] == a.responsavel)
                            .toList();
                        if (obsA.isNotEmpty) {
                          obsA.sort((x, y) => DateTime.parse(y['data']).compareTo(DateTime.parse(x['data'])));
                          refA = DateTime.parse(obsA.first['data']);
                        }

                        final obsB = allObs
                            .where((o) => o['responsavel'] == b.responsavel)
                            .toList();
                        if (obsB.isNotEmpty) {
                          obsB.sort((x, y) => DateTime.parse(y['data']).compareTo(DateTime.parse(x['data'])));
                          refB = DateTime.parse(obsB.first['data']);
                        }

                        final dataFinalA = _maisRecenteEntre(refA, a.ultima_compra);
                        final dataFinalB = _maisRecenteEntre(refB, b.ultima_compra);

                        if (dataFinalA == null && dataFinalB == null) return 0;
                        if (dataFinalA == null) return -1;
                        if (dataFinalB == null) return 1;
                        return dataFinalA.compareTo(dataFinalB);
                      });

                      if (filteredClientes.isEmpty) {
                        return Center(child: Text('Nenhum cliente encontrado'));
                      }

                      final hoje = DateTime.now();

                      return ListView.separated(
                        padding: EdgeInsets.only(bottom: 160), 
                        itemCount: filteredClientes.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final cliente = filteredClientes[index];
                          final isAniversariante = cliente.data_nasc != null &&
                            cliente.data_nasc!.day == hoje.day &&
                            cliente.data_nasc!.month == hoje.month;

                          final obsDoResponsavel = allObs
                              .where((o) => o['responsavel'] == cliente.responsavel)
                              .toList();

                          DateTime? ultimaObs;
                          if (obsDoResponsavel.isNotEmpty) {
                            obsDoResponsavel.sort((a, b) =>
                                DateTime.parse(b['data']).compareTo(DateTime.parse(a['data'])));
                            ultimaObs = DateTime.parse(obsDoResponsavel.first['data']);
                          }

                          Color corIcone;
                          if (ultimaObs != null) {
                            final dias = DateTime.now().difference(ultimaObs).inDays;
                            if (dias <= 10) {
                              corIcone = Colors.green;
                            } else if (dias <= 25) {
                              corIcone = Colors.orangeAccent;
                            } else {
                              corIcone = Colors.red;
                            }
                          } else if (cliente.ultima_compra != null) {
                            final diasSemCompra = DateTime.now().difference(cliente.ultima_compra!).inDays;
                            if (diasSemCompra <= 10) {
                              corIcone = Colors.green;
                            } else if (diasSemCompra <= 25) {
                              corIcone = Colors.orangeAccent;
                            } else {
                              corIcone = Colors.red;
                            }
                          } else {
                            corIcone = Colors.grey;
                          }

                          return ListTile(
                            onTap: widget.modoSelecao
                                ? () => Navigator.pop(context, cliente)
                                : null,

                            title: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cliente.nomeCliente,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),

                                          if (isAniversariante)
                                            const Icon(Icons.cake, color: Colors.pink, size: 18),

                                          const SizedBox(width: 8),

                                          GestureDetector(
                                            onTap: () => _mostrarInfoCliente(context, cliente),
                                            child: Icon(
                                              Icons.info_outline,
                                              color: corIcone,
                                              size: 20,
                                            ),
                                          ),
                                        ],
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
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildTotaisFlutuantes(),
          ),
        ],
      ),
    );
  }

  DateTime? _maisRecenteEntre(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
  
  Future<void> atualizarObservacoesLocais() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final obsFile = File('${dir.path}/observacoes.json');

      if (await obsFile.exists()) {
        final obsContent = await obsFile.readAsString();
        final Map<String, dynamic> obsData = json.decode(obsContent);

        setState(() {
          allObs = List<Map<String, dynamic>>.from(obsData['data'] ?? []);
        });

        print('🔄 Observações recarregadas (${allObs.length})');
      } else {
        print('⚠️ Nenhum arquivo de observações encontrado.');
      }
    } catch (e) {
      print('❌ Erro ao atualizar observações locais: $e');
    }
  }

  Future<void> _mostrarInfoCliente(BuildContext context, Cliente cliente) async {
    final hoje = DateTime.now();
    DateTime selectedDate = DateTime.now();

    bool visitado = false;
    final TextEditingController obsController = TextEditingController();

    List<Map<String, dynamic>> clienteObs = [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/observacoes.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);
        final List<dynamic> allObs = jsonData['data'] ?? [];

        clienteObs = allObs
            .where((o) => o['responsavel'] == cliente.responsavel)
            .map((o) => Map<String, dynamic>.from(o))
            .toList();
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro ao carregar observações do cliente ${cliente.id}: $e\nStackTrace: $stack');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            'Nova observação',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Visitado:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Checkbox(
                        value: visitado,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          visitado = val ?? false;
                          (context as Element).markNeedsBuild(); // Atualiza UI
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Observação (opcional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: obsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Digite aqui sua observação...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              if (clienteObs.isNotEmpty) ...[
                for (var o in (List<Map<String, dynamic>>.from(clienteObs)
                    ..sort((a, b) {
                      final dateA = DateTime.parse(a['data']);
                      final dateB = DateTime.parse(b['data']);
                      return dateB.compareTo(dateA); 
                    })))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateTime.parse(o['data']).day.toString().padLeft(2, '0')}/'
                          '${DateTime.parse(o['data']).month.toString().padLeft(2, '0')}/'
                          '${DateTime.parse(o['data']).year}  •  '
                          '${o['visitado'] == true ? 'Visitado' : 'Não visitado'}  •  '
                          '${o['nome_cliente'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if ((o['observacao'] ?? '').isNotEmpty)
                          Text(
                            o['observacao']!,
                            style: const TextStyle(height: 1.4),
                          ),
                      ],
                    ),
                  ),
              ] else
                const Text(
                  'Nenhuma observação registrada para este cliente.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final int? idVendedor = prefs.getInt('id_vendedor');

              if (idVendedor == null) {
                await LocalLogger.log('Erro: id_vendedor não encontrado no SharedPreferences');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: vendedor não encontrado')),
                );
                return;
              }

              final body = {
                'data': selectedDate.toIso8601String(),
                'visitado': visitado,
                'observacao': obsController.text.isNotEmpty ? obsController.text : null,
              };

              final url = '/clientes/${cliente.id}/observacoes';

              try {
                // salva local
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/observacoes.json');
                Map<String, dynamic> jsonData = {'data': []};

                if (await file.exists()) {
                  final content = await file.readAsString();
                  jsonData = json.decode(content);
                }

                final List<dynamic> localData = jsonData['data'] ?? [];
                localData.add({
                  'id_cliente': cliente.id,
                  'nome_cliente': cliente.nomeCliente,
                  'responsavel': cliente.responsavel,
                  'data': body['data'],
                  'visitado': body['visitado'],
                  'observacao': body['observacao'],
                });
                jsonData['data'] = localData;

                await file.writeAsString(json.encode(jsonData));

                // salva online (ou no pendents se nao houver internet)
                final online = await hasInternetConnection();
                if (online) {
                  final httpClient = HttpClient();
                  final response = await httpClient.post(url, body);

                  if (response.statusCode == 200) {
                    final respBody = json.decode(response.body);

                    if (respBody['status'] == 'ok') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Observação registrada com sucesso')),
                      );
                    } else {
                      await LocalLogger.log('Erro ao criar observação: ${respBody['mensagem']}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: ${respBody['mensagem']}')),
                      );
                    }
                  } else {
                    await LocalLogger.log('Erro HTTP ao criar observação (status ${response.statusCode})');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao registrar observação')),
                    );
                  }
                } else {
                  await OfflineQueue.addToQueue({
                    'url': url,
                    'body': body,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sem internet: observação salva para envio posterior')),
                  );
                }
              } catch (e, stack) {
                await LocalLogger.log('Erro ao criar observação: $e\nStackTrace: $stack');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao registrar observação')),
                );
              }

              Navigator.pop(context);
              await atualizarObservacoesLocais();
            },
            child: const Text('Salvar'),
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

  Widget _buildTotaisFlutuantes() {
    final clientesParaTotais = filteredClientes.isNotEmpty ? filteredClientes : allClientes;

    double totalLimiteBM = clientesParaTotais.fold(0, (sum, c) => sum + c.limite);
    double totalSaldoBM = clientesParaTotais.fold(0, (sum, c) => sum + c.saldo_limite);
    double totalLimiteC = clientesParaTotais.fold(0, (sum, c) => sum + c.limite_calculado);
    double totalSaldoC = clientesParaTotais.fold(0, (sum, c) => sum + c.saldo_limite_calculado);

    return SafeArea(
      bottom: true, 
      child: Container(
        width: double.infinity, 
        margin: const EdgeInsets.all(4), 
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              child: Text(
                "Totais",
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildColunaLimiteComLinhaInterna("Limite BM", formatarValor(totalLimiteBM), totalLimiteBM, true),
                  _buildColunaLimiteComLinhaInterna("Saldo BM", formatarValor(totalSaldoBM), totalSaldoBM, true),
                  _buildColunaLimiteComLinhaInterna("Limite C", formatarValor(totalLimiteC), totalLimiteC, true),
                  _buildColunaLimiteComLinhaInterna("Saldo C", formatarValor(totalSaldoC), totalSaldoC, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Cliente> _getFilteredClientes() {
    final query = searchController.text.trim().toLowerCase();
    final hoje = DateTime.now();

    final filtrados = allClientes.where((c) {
      final nome = c.nomeCliente.toLowerCase();
      final resp = c.responsavel.toLowerCase();
      return nome.contains(query) || resp.contains(query);
    }).toList();

    filtrados.sort((a, b) {
      final aAniversario = a.data_nasc != null &&
          a.data_nasc!.day == hoje.day &&
          a.data_nasc!.month == hoje.month;
      final bAniversario = b.data_nasc != null &&
          b.data_nasc!.day == hoje.day &&
          b.data_nasc!.month == hoje.month;

      // 1) aniversariantes do dia primeiro
      if (aAniversario && !bAniversario) return -1;
      if (!aAniversario && bAniversario) return 1;

      // 2) quem tem data_nasc vem antes de quem não tem (evita nulls no topo)
      final aHasDate = a.data_nasc != null;
      final bHasDate = b.data_nasc != null;
      if (aHasDate && !bHasDate) return -1;
      if (!aHasDate && bHasDate) return 1;

      // 3) por fim, ordem alfabética (case-insensitive)
      return a.nomeCliente.toLowerCase().compareTo(b.nomeCliente.toLowerCase());
    });

    return filtrados;
  }


  void _filterClientes(String query) {
    setState(() {    
      filteredClientes = _getFilteredClientes(); 
    });
  }

  String formatarValor(double valor) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',  
      symbol: '',       
      decimalDigits: 2,
    );
    return formatter.format(valor).trim();
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