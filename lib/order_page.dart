import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/sync_service.dart';
import 'background/local_log.dart';
import 'models/client.dart';
import 'models/product.dart';
import 'clients_page.dart';
import 'store_page.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Cliente? clienteSelecionado;
  Map<String, dynamic>? pagamentoSelecionado;
  List<Product> produtosSelecionados = [];

  List<Cliente> clientes = [];
  List<Product> produtos = [];

  final SyncService sync = SyncService();
  Map<int, int> quantidades = {};
  Map<int, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    carregarClientes();
    carregarProdutos();
  }

  Future<void> carregarClientes() async {
    final dados = await sync.lerClientesLocal();
    setState(() => clientes = dados);
  }

  Future<void> carregarProdutos() async {
    final dados = await sync.lerEstoqueLocalGeral();
    setState(() => produtos = dados);
  }

  List<Map<String, String>> gerarParcelas() {
    if (pagamentoSelecionado == null) return [];

    final hoje = DateTime.now();
    final prazos = List<int>.from(pagamentoSelecionado!["prazo"]);
    List<Map<String, String>> lista = [];

    for (int i = 0; i < prazos.length; i++) {
      final venc = hoje.add(Duration(days: prazos[i]));
      lista.add({
        "parcela": "${i + 1}",
        "vencimento": "${venc.day.toString().padLeft(2, '0')}/"
            "${venc.month.toString().padLeft(2, '0')}/"
            "${venc.year}"
      });
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pedidos"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo("Cliente"),
            _caixaSelecao(
              label: clienteSelecionado?.responsavel ?? "Selecionar Cliente",
              icon: Icons.person_search,
              onTap: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientsPage(
                      modoSelecao: true, 
                    ),
                  ),
                );
                if (r != null) setState(() => clienteSelecionado = r);
              },
            ),
            SizedBox(height: 5),

            _titulo("Forma de Pagamento"),
            _caixaSelecao(
              label: pagamentoSelecionado?['nome'] ?? "Selecionar Forma de pagamento",
              icon: Icons.payment,
              onTap: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelecaoPagamentoPage(),
                  ),
                );
                if (r != null) setState(() => pagamentoSelecionado = r);
              },
            ),
            SizedBox(height: 5),

            if (pagamentoSelecionado != null) ...[
              SizedBox(height: 1),

              Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                columnWidths: {
                  0: FlexColumnWidth(1),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                        child: Text(
                          "Parcela",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                        child: Text(
                          "Vencimento",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  ...gerarParcelas().map((p) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Text(
                            p["parcela"]!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Text(
                            p["vencimento"]!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              SizedBox(height: 1),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Divider(thickness: 2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Produtos",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(thickness: 2)),
                ],
              ),
            ),
            SizedBox(height: 1),

            ...produtosSelecionados.map((p) {
              final qtd = quantidades[p.id] ?? 1;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome
                      Text(
                        p.nome,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),

                      // Disponível
                      FutureBuilder(
                        future: getEmpresa(),
                        builder: (context, snap) {
                          if (!snap.hasData) return SizedBox();

                          int emp = snap.data!;
                          int est = estoquePorEmpresa(p, emp);
                          int disp = disponivelPorEmpresa(p, emp);

                          return Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  "Estoque: $est",
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ),
                              Text(
                                "Disponível: $disp",
                                style: TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 10),

                      // ==============================
                      //       CONTROLE DE QUANTIDADE
                      // ==============================
                      Row(
                        children: [
                          // BOTÃO DE DIMINUIR
                          InkWell(
                            onTap: () {
                              if (qtd > 1) {
                                setState(() {
                                  quantidades[p.id] = qtd - 1;
                                  controllers[p.id]!.text = (qtd - 1).toString();
                                });
                              }
                            },
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.remove, color: Colors.red, size: 22),
                            ),
                          ),

                          SizedBox(width: 14),

                          // INPUT DE QUANTIDADE
                          Container(
                            width: 50,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: TextFormField(
                              controller: controllers[p.id],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) {
                                int n = int.tryParse(v) ?? 1;
                                if (n < 1) n = 1;
                                setState(() => quantidades[p.id] = n);
                              },
                            ),
                          ),

                          SizedBox(width: 14),

                          // BOTÃO DE AUMENTAR
                          InkWell(
                            onTap: () {
                              setState(() {
                                quantidades[p.id] = qtd + 1;
                                controllers[p.id]!.text = (qtd + 1).toString();
                              });
                            },
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, color: Colors.green, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            GestureDetector(
              onTap: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StorePage(
                      modoSelecao: true,
                    ),
                  ),
                );
                if (r != null) {
                  setState(() {
                    produtosSelecionados.add(r);

                    quantidades[r.id] = 1;

                    controllers[r.id] = TextEditingController(text: "1");
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Adicionar Produto",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<int> getEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_empresa') ?? 1;
  }

  int estoquePorEmpresa(Product p, int empresa) {
    switch (empresa) {
      case 1: return p.estoqueBelavista;
      case 2: return p.estoqueImbuia;
      case 3: return p.estoqueVilanova;
      case 4: return p.estoqueAurora;
      default: return 0;
    }
  }

  int disponivelPorEmpresa(Product p, int empresa) {
    switch (empresa) {
      case 1: return p.disponivelBelavista;
      case 2: return p.disponivelImbuia;
      case 3: return p.disponivelVilanova;
      case 4: return p.disponivelAurora;
      default: return 0;
    }
  }

  Widget _titulo(String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(txt,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _caixaSelecao({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Icon(icon)],
        ),
      ),
    );
  }
}

// ================= PAGAMENTO =================
class SelecaoPagamentoPage extends StatelessWidget {
  final List<Map<String, dynamic>> metodos = const [
    // crediario
    {"id": 66, "nome": "7 dias crediario", "prazo": [7], "parcelas": 1},
    {"id": 67, "nome": "14 dias crediario", "prazo": [14], "parcelas": 1},
    {"id": 2, "nome": "28 dias crediario", "prazo": [28], "parcelas": 1},
    {"id": 29, "nome": "42 dias crediario (45 dias)", "prazo": [42], "parcelas": 1, "juros": 2.81},
    {"id": 31, "nome": "56 dias crediario (60 dias)", "prazo": [56], "parcelas": 1, "juros": 3.77},
    {"id": 32, "nome": "84 dias crediario (90 dias)", "prazo": [84], "parcelas": 1, "juros": 5.7},

    {"id": 37, "nome": "2 parcelas crediario", "prazo": [28, 56], "parcelas": 2, "juros": 2.81},
    {"id": 35, "nome": "3 parcelas crediario (1 parcela avista)", "prazo": [0, 28, 56], "parcelas": 3},
    {"id": 39, "nome": "3 parcelas crediario", "prazo": [28, 56, 84], "parcelas": 3, "juros": 3.77},
    {"id": 45, "nome": "4 parcelas crediario", "prazo": [28, 56, 84, 112], "parcelas": 4, "juros": 4.73},
    {"id": 41, "nome": "5 parcelas crediario", "prazo": [28, 56, 84, 112, 140], "parcelas": 5, "juros": 5.7},
    {"id": 42, "nome": "7 parcelas crediario", "prazo": [28, 56, 84, 112, 140, 168, 196], "parcelas": 7, "juros": 7.67},

    // boleto
    {"id": 64, "nome": "7 dias boleto", "prazo": [7], "parcelas": 1},
    {"id": 65, "nome": "14 dias boleto", "prazo": [14], "parcelas": 1},
    {"id": 28, "nome": "28 dias boleto", "prazo": [28], "parcelas": 1},
    {"id": 30, "nome": "42 dias boleto (45 dias)", "prazo": [42], "parcelas": 1, "juros": 2.81},
    {"id": 33, "nome": "56 dias boleto (60 dias)", "prazo": [56], "parcelas": 1, "juros": 3.77},
    {"id": 34, "nome": "84 dias boleto (90 dias)", "prazo": [84], "parcelas": 1, "juros": 5.7},
    {"id": 49, "nome": "112 dias boleto (120 dias)", "prazo": [112], "parcelas": 1, "juros": 7.67},
    {"id": 48, "nome": "140 dias boleto (150 dias)", "prazo": [140], "parcelas": 1, "juros": 9.68},

    {"id": 38, "nome": "2 parcelas boleto", "prazo": [28, 56], "parcelas": 2, "juros": 2.81},
    {"id": 36, "nome": "3 parcelas boleto (1 parcela avista)", "prazo": [0, 28, 56], "parcelas": 3},
    {"id": 40, "nome": "3 parcelas boleto", "prazo": [28, 56, 84], "parcelas": 3, "juros": 3.77},
    {"id": 46, "nome": "4 parcelas boleto (1 parcela avista)", "prazo": [0, 28, 56, 84], "parcelas": 4, "juros": 2.81},
    {"id": 47, "nome": "6 parcelas boleto", "prazo": [28, 56, 84, 112, 140, 168], "parcelas": 6, "juros": 6.68},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forma de Pagamento")),
        body: ListView(
          children: metodos.map((m) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(
                  m["nome"],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Icon(Icons.check_circle_outline),
                onTap: () => Navigator.pop(context, m),
              ),
            );
          }).toList(),
        ),
    );
  }
}