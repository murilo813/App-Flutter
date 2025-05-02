import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database/local_database.dart'; // banco local

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

  // Mapeia os nomes técnicos para nomes a ser exibidos
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
        var result = await Connectivity().checkConnectivity();

        if (result == ConnectivityResult.none) {
            // SEM INTERNET → Carrega dados locais
            final localData = await LocalDatabase.getProductsByStore(widget.storeName);
            setState(() {
                products = Future.value(localData);
            });
        } else {
            // COM INTERNET → Busca da API, exibe na tela e depois salva localmente
            try {
                final fetched = await apiService.fetchProducts(widget.storeName);

                setState(() {
                    products = Future.value(fetched); // Mostra dados da API imediatamente
                });

                await LocalDatabase.insertProducts(fetched, widget.storeName); // Salva no banco local em segundo plano
            } catch (e) {
                print('Erro ao buscar dados da API: $e');

                // Em caso de erro na API, tenta mostrar dados locais como fallback
                final localData = await LocalDatabase.getProductsByStore(widget.storeName);
                setState(() {
                    products = Future.value(localData);
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts, // Filtra os produtos conforme o usuário digita
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No products available'));
                } else {
                  // Atualiza a lista filtrada com base na pesquisa
                  if (filteredProducts.isEmpty) {
                    filteredProducts = snapshot.data!;
                  }
                  // Se houver algo digitado na barra de pesquisa, filtra
                  if (searchController.text.isNotEmpty) {
                    filteredProducts = snapshot.data!
                        .where((product) => product.nome.toLowerCase().contains(searchController.text.toLowerCase()))
                        .toList();
                  }
                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ListTile(
                        title: Text(product.nome),
                        subtitle: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                  text: 'Estoque: ',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: '${product.estoque},  '),
                              TextSpan(
                                  text: 'Disponível: ',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: '${product.disponivel}'),
                            ],
                          ),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                      text: 'Preço 1: ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${product.preco1Formatado}'),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                      text: 'Preço 2: ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${product.preco2Formatado}'),
                                ],
                              ),
                            ),
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
  // Função para filtrar os produtos com base no texto da pesquisa
  void _filterProducts(String query) {
    setState(() {
      filteredProducts = filteredProducts
          .where((product) =>
              product.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
}
