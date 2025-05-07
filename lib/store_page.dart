import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class StorePage extends StatefulWidget {
  final String storeName;

  StorePage({required this.storeName});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late Future<List<Product>> products;
  late List<Product> filteredProducts;
  late TextEditingController searchController;
  final ApiService apiService = ApiService();
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

  void checkConnectionAndLoadData() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('Sem conexão — carregando do arquivo local');
      final localData = await lerEstoqueLocalGeral();
      if (localData != null) {
        List<Product> localProducts = (localData['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
        setState(() {
          products = Future.value(localProducts);
          ultimaAtualizacao = localData['lastSynced']; 
        });
        print('Dados locais carregados: $localData');
      } else {
        setState(() {
          products = Future.error('Sem internet e sem dados locais');
        });
      }
    } else {
      print('Com conexão — carregando da API');
      setState(() {
        isSyncing = true; 
      });

      try {
        final fetched = await apiService.fetchProducts();
        final dataHoraAgora = DateTime.now().toIso8601String();

        await salvarEstoqueLocal(fetched, dataHoraAgora);

        setState(() {
          products = Future.value(fetched);  
          ultimaAtualizacao = dataHoraAgora;
          isSyncing = false;
        });
      } catch (e) {
        print('Erro ao buscar da API: $e');
        setState(() {
          products = Future.error('Erro ao carregar da API');
          isSyncing = false;
        });
      }
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
                  if (searchController.text.isNotEmpty) {
                    filteredProducts = snapshot.data!
                        .where((product) => product.nome
                            .toLowerCase()
                            .contains(searchController.text.toLowerCase()))
                        .toList();
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
                        title: Text(
                          product.nome,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(
                                        text: 'Preço 1: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: '${product.preco1Formatado}'),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 22),
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(
                                        text: 'Preço 2: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: '${product.preco2Formatado}'),
                                    ],
                                  ),
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
          'Disponível $store:',
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
        0: FixedColumnWidth(120), 
        1: FixedColumnWidth(40),  
        2: FixedColumnWidth(140), 
        3: FixedColumnWidth(40),  
      },
      children: rows.map((row) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('Estoque ${row[0]}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(row[1]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('Disponível ${row[0]}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(row[2]),
            ),
          ],
        );
      }).toList(),
    );
  }


  void _filterProducts(String query) {
    setState(() {
      filteredProducts = filteredProducts
          .where((product) =>
              product.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _formatarData(String dataIso) {
    final dt = DateTime.parse(dataIso).toLocal();
    return '${_doisDigitos(dt.day)}/${_doisDigitos(dt.month)}/${dt.year} às ${_doisDigitos(dt.hour)}:${_doisDigitos(dt.minute)}';
  }

  String _doisDigitos(int n) => n.toString().padLeft(2, '0');
}
