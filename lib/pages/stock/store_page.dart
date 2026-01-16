import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/api/sync_data.dart';
import 'package:alembro/services/connectivity.dart';
import '../../services/local/local_log.dart';
import '../../services/local/pendents.dart';
import '../../widgets/loading.dart';
import '../../widgets/error.dart';
import '../../widgets/gradientgreen.dart';
import 'stock_controller.dart';

class StorePage extends StatefulWidget {
  final bool modoSelecao;

  const StorePage({super.key, this.modoSelecao = false});

  @override
  StorePageState createState() => StorePageState();
}

class StorePageState extends State<StorePage> with WidgetsBindingObserver {
  final _stockController = StockController();
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

  Future<void> checkConnectionAndLoadData() async {
    setState(() {
      loading = true;
      erroCritico = false;
    });

    try {
      final temInternet = await hasInternetConnection();

      if (!widget.modoSelecao && temInternet) {
        try {
          await syncService.syncStock();
        } catch (e, stack) {
          await LocalLogger.log('Erro na sincronização de estoque: $e\n$stack');
        }
      }

      // 2. Carga de Dados (Sempre carrega do local após a tentativa de sync)
      final StockData data = await _stockController.loadStock();

      setState(() {
        allProducts = data.products;
        filteredProducts = data.products;
        ultimaAtualizacao = data.lastSynced;
        
        // Se após tentar carregar ainda estiver vazio, dá erro crítico
        erroCritico = allProducts.isEmpty;
      });

    } catch (e, stack) {
      await LocalLogger.log('Erro crítico em StorePage: $e\n$stack');
      setState(() => erroCritico = true);
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
                        color: Colors.black.withValues(alpha: 0.1),
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
                                '${product.productId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                product.productName,
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
                                    product.brand,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (product.aplication.isNotEmpty)
                                    Text(
                                      product.aplication,
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
      ['Aurora', '${product.auroraStock}', '${product.auroraAvailable}'],
      ['Imbuia', '${product.imbuiaStock}', '${product.imbuiaAvailable}'],
      [
        'Vila Nova',
        '${product.vilanovaStock}',
        '${product.vilanovaAvailable}',
      ],
      [
        'Bela Vista',
        '${product.belavistaStock}',
        '${product.belavistaAvailable}',
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
                        TextSpan(text: product.price1F),
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
                          TextSpan(text: product.price2F),
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
            final matchesName = product.productName.toLowerCase().contains(lowerQuery);
            final matchesMarca = product.brand.toLowerCase().contains(
              lowerQuery,
            );
            final matchesId = product.productId.toString().contains(lowerQuery);
            final matchesAplicacao = product.aplication.toLowerCase().contains(
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
