import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'models/product.dart';
import 'services/sync_service.dart';
import 'background/local_log.dart';
import 'background/pendents.dart';
import 'widgets/loading.dart';
import 'widgets/error.dart';
import 'widgets/gradientgreen.dart';
import 'secrets.dart';

class StorePage extends StatefulWidget {
  final bool modoSelecao;

  const StorePage({super.key, this.modoSelecao = false});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with WidgetsBindingObserver {
  late List<Product> filteredProducts;
  late List<Product> allProducts = [];
  late TextEditingController searchController;
  final SyncService syncService = SyncService();
  String? ultimaAtualizacao;
  bool loading = true;
  bool erroCritico = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchController = TextEditingController();

    Timer? debounce;

    searchController.addListener(() {
      if (debounce?.isActive ?? false) debounce!.cancel();
      debounce = Timer(const Duration(milliseconds: 500), () {
        final termoAtual = searchController.text.trim();
        if (termoAtual.isNotEmpty) {
          _savePesquisa(termoAtual);
        }
      });
    });

    filteredProducts = [];
    allProducts = [];
    checkConnectionAndLoadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _savePesquisa(searchController.text);
    }
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
      final file = File('${dir.path}/estoque_geral.json');

      if (!await file.exists()) {
        await LocalLogger.log(
          'Offline e sem cache: estoque_geral.json não encontrado',
        );

        setState(() {
          allProducts = [];
          filteredProducts = [];
          ultimaAtualizacao = null;
        });
        return;
      }

      final content = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(content);

      final List<Product> localProducts =
          (jsonData['data'] as List).map((e) => Product.fromJson(e)).toList();

      setState(() {
        allProducts = localProducts;
        filteredProducts = localProducts;
        ultimaAtualizacao = jsonData['lastSynced'];
      });
    } catch (e, stack) {
      await LocalLogger.log(
        'Erro ao carregar dados locais\nErro: $e\nStack: $stack',
      );

      setState(() {
        allProducts = [];
        filteredProducts = [];
        ultimaAtualizacao = null;
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

      if (widget.modoSelecao) {
        await carregarDadosLocais();
      } else if (!temInternet) {
        await carregarDadosLocais();
      } else {
        List<Product> produtos = [];
        try {
          produtos = await syncService.syncEstoqueGeral();
        } catch (e, stack) {
          await LocalLogger.log('Erro na sincronização: $e\n$stack');
        }

        // Atualiza o estado com os produtos sincronizados
        if (produtos.isNotEmpty) {
          setState(() {
            allProducts = produtos;
            filteredProducts = produtos;
            ultimaAtualizacao = DateTime.now().toIso8601String();
          });
        }

        // Se ainda não tiver produtos, tenta carregar local
        if (produtos.isEmpty) await carregarDadosLocais();
      }

      if (allProducts.isEmpty) {
        setState(() {
          erroCritico = true;
        });
      }
    } catch (e, stack) {
      await LocalLogger.log(
        'Erro crítico em checkConnectionAndLoadData\nErro: $e\nStack: $stack',
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Loading(icon: Icons.inventory_2_outlined, color: Colors.white),
      );
    }
    if (erroCritico) {
      return ErrorScreen(onRetry: checkConnectionAndLoadData);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: GradientGreen.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 40,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              children: [
                // AppBar fake
                SizedBox(
                  height: 35, // altura típica do AppBar
                  child: Stack(
                    children: [
                      // Botão de voltar
                      if (Navigator.canPop(context))
                        const Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: BackButton(color: Colors.white),
                        ),
                      // Título centralizado na tela
                      Center(
                        child: Text(
                          widget.modoSelecao ? "Selecionar Produto" : "Estoque",
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
                // Última atualização
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
                // Caixa de pesquisa branca com borda arredondada
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
              ],
            ),
          ),

          // Resto da página
          Expanded(
            child:
                loading
                    ? const Center(
                      child: Loading(
                        icon: Icons.inventory,
                        color: Colors.green,
                      ),
                    )
                    : filteredProducts.isEmpty
                    ? Center(
                      child: Text(
                        searchController.text.isEmpty
                            ? 'Nenhum produto disponível'
                            : 'Nenhum produto encontrado',
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredProducts.length,
                      separatorBuilder:
                          (context, index) =>
                              const Divider(height: 20, thickness: 1),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];

                        return ListTile(
                          onTap:
                              widget.modoSelecao
                                  ? () => Navigator.pop(context, product)
                                  : null,
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                product.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.marca,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (product.aplicacao.isNotEmpty)
                                    Text(
                                      product.aplicacao,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _buildEstoqueTable(product),
                            ],
                          ),
                          trailing: null,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstoqueTable(Product product) {
    final List<List<String>> rows = [
      ['Aurora', '${product.estoqueAurora}', '${product.disponivelAurora}'],
      ['Imbuia', '${product.estoqueImbuia}', '${product.disponivelImbuia}'],
      [
        'Vila Nova',
        '${product.estoqueVilanova}',
        '${product.disponivelVilanova}',
      ],
      [
        'Bela Vista',
        '${product.estoqueBelavista}',
        '${product.disponivelBelavista}',
      ],
    ];

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(), // nome da loja
        1: FixedColumnWidth(60), // QTD
        2: FixedColumnWidth(60), // DISP
      },
      border: TableBorder.symmetric(
        inside: BorderSide(width: 1, color: Colors.grey.shade300),
      ),
      children: [
        // Cabeçalho
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Preço 1
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'Preço 1: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: product.preco1Formatado),
                      ],
                    ),
                  ),
                  // Preço 2
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Preço 2: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: product.preco2Formatado),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text(
                  'Qtd',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text(
                  'Disp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Dados das lojas
        ...rows.map((row) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  row[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(row[1], textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(row[2], textAlign: TextAlign.center),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _savePesquisa(String termo) async {
    termo = termo.trim();
    if (termo.isEmpty) return;

    final queue = await OfflineQueue.getQueue();

    final outros = queue.where((item) => item['url'] != '/pesquisa').toList();

    List<String> termosSalvos = [];
    if (queue.isNotEmpty) {
      final itemPesquisa = queue.firstWhere(
        (item) => item['url'] == '/pesquisa',
        orElse: () => {},
      );
      if (itemPesquisa.containsKey('body') &&
          itemPesquisa['body'].containsKey('termos')) {
        termosSalvos = List<String>.from(itemPesquisa['body']['termos']);
      }
    }

    if (!termosSalvos.contains(termo)) {
      termosSalvos.add(termo);
    }

    await OfflineQueue.clearQueue();
    for (final item in outros) {
      await OfflineQueue.addToQueue(item);
    }

    final data = {
      'url': '/pesquisa',
      'body': {'termos': termosSalvos},
    };
    await OfflineQueue.addToQueue(data);
  }

  void _filterProducts(String query) {
    setState(() {
      final lowerQuery = query.toLowerCase();

      filteredProducts =
          allProducts.where((product) {
            final matchesName = product.nome.toLowerCase().contains(lowerQuery);
            final matchesMarca = product.marca.toLowerCase().contains(
              lowerQuery,
            );
            final matchesId = product.id.toString().contains(lowerQuery);
            final matchesAplicacao = product.aplicacao.toLowerCase().contains(
              lowerQuery,
            );
            return matchesName || matchesMarca || matchesId || matchesAplicacao;
          }).toList();
    });
  }

  String _formatarData(String dataIso) {
    final dt = DateTime.parse(dataIso).toLocal();
    return '${_doisDigitos(dt.day)}/${_doisDigitos(dt.month)}/${dt.year} às ${_doisDigitos(dt.hour)}:${_doisDigitos(dt.minute)}';
  }

  String _doisDigitos(int n) => n.toString().padLeft(2, '0');
}
