import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/product.dart';
import '../services/sync_service.dart';
import 'local_log.dart';

class StorePage extends StatefulWidget {
  final String storeName;

  StorePage({required this.storeName});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late Future<List<Product>> products;
  late List<Product> filteredProducts;
  late List<Product> allProducts = [];
  late TextEditingController searchController;
  final SyncService syncService = SyncService();
  String? ultimaAtualizacao;
  bool isSyncing = false;

  final Map<String, String> storeLabels = {
    'aurora': 'Aurora',
    'imbuia': 'Imbuia',
    'vilanova': 'Vila Nova',
    'belavista': 'Bela Vista',
  };

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredProducts = [];
    products = Future.value([]);
    checkConnectionAndLoadData();
  }
  
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress
        .lookup('google.com')
        .timeout(const Duration(seconds: 10)); 
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void checkConnectionAndLoadData() async {
    final temInternet = await hasInternetConnection();

    Future<void> carregarDadosLocais() async {
      try {
        final localData = await syncService.lerEstoqueLocalGeral();
        if (localData != null) {
          List<Product> localProducts = (localData['data'] as List)
              .map((json) => Product.fromJson(json))
              .toList();
          setState(() {
            products = Future.value(localProducts);
            ultimaAtualizacao = localData['lastSynced'];
          });
        } else {
          await LocalLogger.log('Erro crítico: dados locais vazios');
          setState(() {
            products = Future.error('Sem dados locais disponíveis');
          });
        }
      } catch (e, stack) {
        await LocalLogger.log('Erro crítico ao carregar dados locais\nErro: $e\nStack: $stack');
        setState(() {
          products = Future.error('Erro ao carregar dados locais');
        });
      }
    }

    if (!temInternet) {
      print('Sem conexão — carregando do arquivo local');
      await carregarDadosLocais();
    } else {
      print('Com conexão — sincronizando com a API');
      setState(() {
        isSyncing = true;
      });

      try {
        await syncService.syncEstoqueGeral();
      } catch (e, stack) {
        print('Erro ao sincronizar estoque (storepage): $e');
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
    final tituloLoja = storeLabels[widget.storeName] ?? widget.storeName;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(tituloLoja),
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
                labelText: 'Pesquisar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhum produto disponível'));
                } else {
                  filteredProducts = snapshot.data!;
                  allProducts = snapshot.data!;
                  if (searchController.text.isNotEmpty) {
                    final query = searchController.text.toLowerCase();

                    filteredProducts = snapshot.data!.where((product) {
                      final matchesName = product.nome.toLowerCase().contains(query);
                      final matchesMarca = product.marca.toLowerCase().contains(query);
                      final matchesId = product.id.toString().contains(query);
                      final matchesAplicacao = product.aplicacao.toLowerCase().contains(query);
                      return matchesName || matchesMarca || matchesId || matchesAplicacao;
                    }).toList();
                  }

                  if (filteredProducts.isEmpty) {
                    return Center(child: Text('Nenhum produto encontrado'));
                  }

                  return ListView.separated(
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) => Divider(height: 20, thickness: 1),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.id}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12,               
                                color: Colors.black,        
                              ),
                            ),
                            Text(
                              product.nome,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.marca,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (product.aplicacao.isNotEmpty)
                                  Text(
                                    product.aplicacao,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            _buildEstoqueTable(product),
                          ],
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

  Widget _buildEstoqueDisponivelRow(String store, int estoque, int disponivel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(
          'Estoque $store:',
          style: TextStyle(fontWeight: FontWeight.bold), 
        ),
        SizedBox(width: 5), 
        Text('$estoque'), 
        SizedBox(width: 26), 
        Text(
          'Disponível:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 5), 
        Text('$disponivel'),
      ],
    );
  }

  Widget _buildEstoqueTable(Product product) {
    final List<List<String>> rows = [
      ['Aurora', '${product.estoqueAurora}', '${product.disponivelAurora}'],
      ['Imbuia', '${product.estoqueImbuia}', '${product.disponivelImbuia}'],
      ['Vila Nova', '${product.estoqueVilanova}', '${product.disponivelVilanova}'],
      ['Bela Vista', '${product.estoqueBelavista}', '${product.disponivelBelavista}'],
    ];

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(), // nome da loja
        1: FixedColumnWidth(60),  // QTD
        2: FixedColumnWidth(60),  // DISP
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
                      style: TextStyle(fontSize: 13, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Preço 1: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${product.preco1Formatado}',
                        ),
                      ],
                    ),
                  ),
                  // Preço 2 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Preço 2: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '${product.preco2Formatado}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                  style: TextStyle(
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
        }).toList(),
      ],
    );
  }

  void _filterProducts(String query) {
    setState(() {
      final lowerQuery = query.toLowerCase();

      filteredProducts = allProducts.where((product) {
        final matchesName = product.nome.toLowerCase().contains(lowerQuery);
        final matchesMarca = product.marca.toLowerCase().contains(lowerQuery);
        final matchesId = product.id.toString().contains(lowerQuery);
        final matchesAplicacao = product.aplicacao.toLowerCase().contains(lowerQuery);
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