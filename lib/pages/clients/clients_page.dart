import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'package:alembro/services/api/sync_data.dart';
import 'package:alembro/services/api/http_client.dart';
import 'package:alembro/services/connectivity.dart';
import 'package:alembro/services/local/local_log.dart';
import 'package:alembro/services/local/pendents.dart';
import 'package:alembro/widgets/loading.dart';
import 'package:alembro/widgets/error.dart';
import 'package:alembro/widgets/gradientgreen.dart';
import 'package:alembro/models/client.dart';
import 'clients_controller.dart';

class ClientsPage extends StatefulWidget {
  final bool modoSelecao;

  const ClientsPage({super.key, this.modoSelecao = false});

  @override
  ClientsPageState createState() => ClientsPageState();
}

class ClientsPageState extends State<ClientsPage> {
  final _controller = ClientController();
  List<Client> clientes = [];
  late List<Client> filteredClientes;
  late List<Client> allClientes = [];
  late List<Map<String, dynamic>> allObs = [];
  late TextEditingController searchController;
  String? ultimaAtualizacao;
  bool loading = true;
  bool erroCritico = false;
  final SyncService syncService = SyncService();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredClientes = [];
    checkConnectionAndLoadData();
  }

  Future<void> checkConnectionAndLoadData() async {
    setState(() { loading = true; erroCritico = false; });

    try {
      final online = await hasInternetConnection();

      if (online && !widget.modoSelecao) {
        await syncService.syncClients();
        await syncService.syncObservations();
      }

      final dadosProntos = await _controller.loadAndSort();

      setState(() {
        allClientes = dadosProntos;
        clientes = dadosProntos;
        filteredClientes = _getFilteredClientes();
        erroCritico = allClientes.isEmpty;
      });

    } catch (e) {
      await LocalLogger.log('Erro na página de clientes: $e');
      setState(() => erroCritico = true);
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
        body: Loading(icon: Icons.people, color: Colors.white),
      );
    }

    if (erroCritico) {
      return ErrorScreen(onRetry: checkConnectionAndLoadData);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Column(
            children: [
              // Top gradient container (AppBar fake)
              Container(
                decoration: const BoxDecoration(
                  gradient: GradientGreen.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 40, // status bar
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 35,
                      child: Stack(
                        children: [
                          if (Navigator.canPop(context))
                            const Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: BackButton(color: Colors.white),
                            ),
                          Center(
                            child: Text(
                              widget.modoSelecao
                                  ? 'Selecionar cliente'
                                  : 'Meus Clientes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (ultimaAtualizacao != null)
                      Text(
                        'Última atualização: ${_formatarData(ultimaAtualizacao!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Caixa de pesquisa branca
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Pesquisar cliente',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: _filterClientes,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // Lista de clientes
              Expanded(
                child:
                    filteredClientes.isEmpty
                        ? const Center(
                          child: Text(
                            'Você não tem clientes em sua carteira',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : filteredClientes.isEmpty
                        ? const Center(
                          child: Text(
                            'Nenhum cliente encontrado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 160),
                          itemCount: filteredClientes.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final cliente = filteredClientes[index];
                            final hoje = DateTime.now();
                            final isAniversariante =
                                cliente.birthday != null &&
                                cliente.birthday!.day == hoje.day &&
                                cliente.birthday!.month == hoje.month;

                            // Cálculo cor do ícone
                            final obsDoresponsible =
                                allObs
                                    .where(
                                      (o) =>
                                          o['responsible'] ==
                                          cliente.responsible,
                                    )
                                    .toList();

                            DateTime? ultimaObs;
                            if (obsDoresponsible.isNotEmpty) {
                              obsDoresponsible.sort(
                                (a, b) => DateTime.parse(
                                  b['data'],
                                ).compareTo(DateTime.parse(a['data'])),
                              );
                              ultimaObs = DateTime.parse(
                                obsDoresponsible.first['data'],
                              );
                            }

                            Color corIcone;
                            if (ultimaObs != null) {
                              final dias =
                                  DateTime.now().difference(ultimaObs).inDays;
                              corIcone =
                                  dias <= 10
                                      ? Colors.green
                                      : (dias <= 25
                                          ? Colors.orangeAccent
                                          : Colors.red);
                            } else if (cliente.lastSale != null) {
                              final diasSemCompra =
                                  DateTime.now()
                                      .difference(cliente.lastSale!)
                                      .inDays;
                              corIcone =
                                  diasSemCompra <= 10
                                      ? Colors.green
                                      : (diasSemCompra <= 25
                                          ? Colors.orangeAccent
                                          : Colors.red);
                            } else {
                              corIcone = Colors.grey;
                            }

                            return ListTile(
                              onTap:
                                  widget.modoSelecao
                                      ? () => Navigator.pop(context, cliente)
                                      : null,
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                cliente.clientName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (isAniversariante)
                                              const Icon(
                                                Icons.cake,
                                                color: Colors.pink,
                                                size: 18,
                                              ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap:
                                                  () => _mostrarInfoCliente(
                                                    context,
                                                    cliente,
                                                  ),
                                              child: Icon(
                                                Icons.info_outline,
                                                color: corIcone,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (cliente.responsible.isNotEmpty)
                                          Text(
                                            'Responsável: ${cliente.responsible}',
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
                        ),
              ),
            ],
          ),
          // Totais flutuantes
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

  Future<void> atualizarObservacoesLocais() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final obsFile = File('${dir.path}/observations.json');

      if (!await obsFile.exists()) return;

      final obsContent = await obsFile.readAsString();
      final Map<String, dynamic> obsData = json.decode(obsContent);

      if (!mounted) return;
      setState(() {
        allObs = List<Map<String, dynamic>>.from(obsData['data'] ?? []);
      });
    } catch (_) {
      // erro silencioso (arquivo corrompido, permissão, etc.)
    }
  }

  Future<void> _mostrarInfoCliente(
    BuildContext context,
    Client cliente,
  ) async {
    DateTime selectedDate = DateTime.now();

    bool visited = false;
    final TextEditingController obsController = TextEditingController();

    List<Map<String, dynamic>> clienteObs = [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/observations.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = json.decode(content);
        final List<dynamic> allObs = jsonData['data'] ?? [];

        clienteObs =
            allObs
                .where((o) => o['responsible'] == cliente.responsible)
                .map((o) => Map<String, dynamic>.from(o))
                .toList();
      }
    } catch (e, stack) {
      await LocalLogger.log(
        'Erro ao carregar observações do cliente ${cliente.clientId}: $e\nStackTrace: $stack',
      );
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white, // MATERIAL 3 (crítico)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Center(
              child: Text(
                'Nova observação',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                                locale: const Locale('pt', 'BR'),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.black, // header + OK
                                        onPrimary: Colors.white,
                                        surface:
                                            Colors.white, // fundo calendário
                                        onSurface: Colors.black, // textos
                                      ),
                                      dialogTheme: const DialogThemeData(
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'visited:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Checkbox(
                            value: visited,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              visited = val ?? false;
                              (context as Element)
                                  .markNeedsBuild(); // Atualiza UI
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
                              '${o['visited'] == true ? 'visited' : 'Não visitado'}  •  '
                              '${o['clientName'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if ((o['observation'] ?? '').isNotEmpty)
                              Text(
                                o['observation']!,
                                style: const TextStyle(height: 1.4),
                              ),
                          ],
                        ),
                      ),
                  ] else
                    const Text(
                      'Nenhuma observação registrada para este cliente.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fechar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);

                  final prefs = await SharedPreferences.getInstance();
                  final int? idVendedor = prefs.getInt('id_vendedor');

                  if (idVendedor == null) {
                    await LocalLogger.log(
                      'Erro: id_vendedor não encontrado no SharedPreferences',
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Erro: vendedor não encontrado'),
                      ),
                    );
                    return;
                  }

                  final body = {
                    'date': selectedDate.toIso8601String(),
                    'visited': visited,
                    'observation':
                        obsController.text.isNotEmpty
                            ? obsController.text
                            : null,
                  };

                  final url = '/clientes/${cliente.clientId}/observacoes';

                  try {
                    // salva local
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/observations.json');
                    Map<String, dynamic> jsonData = {'data': []};

                    if (await file.exists()) {
                      final content = await file.readAsString();
                      jsonData = json.decode(content);
                    }

                    final List<dynamic> localData = jsonData['data'] ?? [];
                    localData.add({
                      'clientId': cliente.clientId,
                      'clientName': cliente.clientName,
                      'responsible': cliente.responsible,
                      'date': body['date'],
                      'visited': body['visited'],
                      'observation': body['observation'],
                    });
                    jsonData['data'] = localData;

                    await file.writeAsString(json.encode(jsonData));

                    final online = await hasInternetConnection();
                    if (online) {
                      final httpClient = HttpClient();
                      final response = await httpClient.post(url, body);

                      if (response.statusCode == 200) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Observação registrada com sucesso'),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Erro ao registrar observação'),
                          ),
                        );
                      }
                    } else {
                      await OfflineQueue.addToQueue({'url': url, 'body': body});
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sem internet: observação salva para envio posterior',
                          ),
                        ),
                      );
                    }
                  } catch (e, stack) {
                    await LocalLogger.log(
                      'Erro ao criar observação: $e\nStackTrace: $stack',
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao registrar observação'),
                      ),
                    );
                  }

                  if (!dialogContext.mounted) return;
                  navigator.pop();
                  await atualizarObservacoesLocais();
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  Widget _buildLimitesTable(Client cliente) {
    return Row(
      children: [
        _buildColunaLimiteComLinhaInterna(
          "Limite BM",
          cliente.limitBMF,
          cliente.limitBM,
          true,
        ),
        _buildColunaLimiteComLinhaInterna(
          "Saldo BM",
          cliente.balanceBMF,
          cliente.balanceBM,
          true,
        ),
        _buildColunaLimiteComLinhaInterna(
          "Limite C",
          cliente.limitCF,
          cliente.limitC,
          true,
        ),
        _buildColunaLimiteComLinhaInterna(
          "Saldo C",
          cliente.balanceCF,
          cliente.balanceC,
          false,
        ),
      ],
    );
  }

  Widget _buildColunaLimiteComLinhaInterna(
    String titulo,
    String valorFormatado,
    double valorOriginal,
    bool temLinhaDireita,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right:
                temLinhaDireita
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
            Container(height: 1, color: Colors.grey.shade300),
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
    final clientesParaTotais =
        filteredClientes.isNotEmpty ? filteredClientes : allClientes;

    final double totalLimiteBM = clientesParaTotais.fold(
      0,
      (sum, c) => sum + c.limitBM,
    );
    final double totalSaldoBM = clientesParaTotais.fold(
      0,
      (sum, c) => sum + c.balanceBM,
    );
    final double totalLimiteC = clientesParaTotais.fold(
      0,
      (sum, c) => sum + c.limitC,
    );
    final double totalSaldoC = clientesParaTotais.fold(
      0,
      (sum, c) => sum + c.balanceC,
    );

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
                  _buildColunaLimiteComLinhaInterna(
                    "Limite BM",
                    formatarValor(totalLimiteBM),
                    totalLimiteBM,
                    true,
                  ),
                  _buildColunaLimiteComLinhaInterna(
                    "Saldo BM",
                    formatarValor(totalSaldoBM),
                    totalSaldoBM,
                    true,
                  ),
                  _buildColunaLimiteComLinhaInterna(
                    "Limite C",
                    formatarValor(totalLimiteC),
                    totalLimiteC,
                    true,
                  ),
                  _buildColunaLimiteComLinhaInterna(
                    "Saldo C",
                    formatarValor(totalSaldoC),
                    totalSaldoC,
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Client> _getFilteredClientes() {
    final query = searchController.text.trim().toLowerCase();

    final filtrados =
        allClientes.where((c) {
          final nome = c.clientName.toLowerCase();
          final resp = c.responsible.toLowerCase();
          return nome.contains(query) || resp.contains(query);
        }).toList();

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

  String _formatarData(String dataIso) {
    final dt = DateTime.parse(dataIso).toLocal();
    return '${_doisDigitos(dt.day)}/${_doisDigitos(dt.month)}/${dt.year} às ${_doisDigitos(dt.hour)}:${_doisDigitos(dt.minute)}';
  }

  String _doisDigitos(int n) => n.toString().padLeft(2, '0');
}
