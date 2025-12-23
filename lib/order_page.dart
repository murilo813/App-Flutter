import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/sync_service.dart';
import 'background/local_log.dart';
import 'background/pendents.dart';
import 'models/client.dart';
import 'models/product.dart';
import 'widgets/loading.dart';
import 'clients_page.dart';
import 'store_page.dart';
import 'resume_page.dart';
import 'secrets.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool loading = true;
  Cliente? clienteSelecionado;
  Map<String, dynamic>? pagamentoSelecionado;
  List<Product> produtosSelecionados = [];
  Map<int, TextEditingController> precoControllers = {};

  List<Cliente> clientes = [];
  List<Product> produtos = [];
  bool aplicarJuros = false;
  double jurosSelecionado = 0.0;
  
  final SyncService sync = SyncService();
  Map<int, int> quantidades = {};
  Map<int, TextEditingController> controllers = {};
  Map<int, double> precosEditados = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await sincronizarAoEntrar();
    });
  }

  Future<void> sincronizarAoEntrar() async {
    setState(() => loading = true);
    print("🔄 [OrdersPage] Iniciando sync ao entrar na tela...");

    final temInternet = await _hasInternet();
    print("🌐 [OrdersPage] Internet? $temInternet");

    if (temInternet) {
      print("📡 Internet detectada — sincronizando com o backend...");
      try {
        await sync.syncClientes();
        print("✔ Clientes sincronizados");

        await sync.syncObservacoes();
        print("✔ Observações sincronizadas");

        await sync.syncEstoqueGeral();
        print("✔ Estoque sincronizado");

        await OfflineQueue.trySendQueue(backendUrl);
        print("✔ Fila offline enviada");

        await LocalLogger.log("Sync inicial no OrdersPage concluído");
      } catch (e, stack) {
        print("❌ Erro na sincronização: $e");
        setState(() => loading = false);
      }
    }

    print("📥 Carregando clientes locais...");
    await carregarClientes();
    print("✔ Clientes carregados");

    print("📦 Carregando produtos locais...");
    await carregarProdutos();
    print("✔ Produtos carregados");

    print("🏁 Sync + carregamento da OrdersPage finalizado!");
    setState(() => loading = false);
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http.get(Uri.parse("$backendUrl/ping"))
        .timeout(const Duration(seconds: 6));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
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
    if (loading) {
      return const Scaffold(
        body: Loading(
          icon: Icons.shopping_cart,
          color: Colors.green,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Pedidos"), centerTitle: true),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            SingleChildScrollView(
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
                          builder: (_) => ClientsPage(modoSelecao: true),
                        ),
                      );
                      if (r != null) setState(() => clienteSelecionado = r);
                    },
                  ),

                  SizedBox(height: 1),

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

                      if (r != null) {
                        setState(() {
                          pagamentoSelecionado = r;
                          aplicarJuros = false; 
                        });

                        if (r.containsKey("juros")) {
                          jurosSelecionado = r["juros"] * 1.0;

                          Future.delayed(Duration(milliseconds: 100), () {
                            mostrarDialogoJuros();
                          });
                        }
                      }
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
                        0: FlexColumnWidth(1), // parcela
                        1: FlexColumnWidth(2), // vencimento
                        2: FlexColumnWidth(2), // valor parcela
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
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                              child: Text(
                                "Valor",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // ---- LINHAS DAS PARCELAS ----
                        ...gerarParcelas().map((p) {
                          int totalParcelas = gerarParcelas().length;
                          double valorParcela = calcularTotal() / totalParcelas;

                          return TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                child: Text(p["parcela"]!, textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                child: Text(p["vencimento"]!, textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                child: Text(
                                  formatador.format(valorParcela),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        }).toList(),

                        // ---- LINHA DO TOTAL ----
                        TableRow(
                          children: [
                            SizedBox(),

                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              child: Text(
                                "Total",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              child: Text(
                                formatador.format(calcularTotal()),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 10),
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

                    return Dismissible(
                      key: Key("produto_${p.id}"),
                      direction: DismissDirection.endToStart,

                      onUpdate: (details) {
                        if (details.direction == DismissDirection.endToStart) {
                          double limit = MediaQuery.of(context).size.width * 0.30;
                          if (details.progress * MediaQuery.of(context).size.width > limit) {
                            details = DismissUpdateDetails(
                              direction: details.direction,
                              reached: details.reached,
                              previousReached: details.previousReached,
                              progress: 0.30,
                            );
                          }
                        }
                      },

                      onDismissed: (_) {
                        setState(() {
                          produtosSelecionados.remove(p);
                          quantidades.remove(p.id);
                          controllers.remove(p.id);
                        });
                      },

                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nome,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),

                              SizedBox(height: 6),

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
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.black54),
                                        ),
                                      ),
                                      Text(
                                        "Disponível: $disp",
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (qtd > 1) {
                                            setState(() {
                                              quantidades[p.id] = qtd - 1;
                                              controllers[p.id]!.text =
                                                  (qtd - 1).toString();
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
                                          child: Icon(Icons.remove,
                                              color: Colors.red, size: 22),
                                        ),
                                      ),

                                      SizedBox(width: 14),

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
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
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

                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            quantidades[p.id] = qtd + 1;
                                            controllers[p.id]!.text =
                                                (qtd + 1).toString();
                                          });
                                        },
                                        child: Container(
                                          width: 25,
                                          height: 25,
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.add,
                                              color: Colors.green, size: 22),
                                        ),
                                      ),
                                    ],
                                  ),

                                  InkWell(
                                    onTap: () => editarPrecoProduto(p),
                                    child: Text(
                                      formatador.format(
                                        p.precoEditado ??
                                        (clienteSelecionado?.lista_preco == 2 ? p.preco2 : p.preco1)
                                      ),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),


                  GestureDetector(
                    onTap: () async {
                      final r = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StorePage(modoSelecao: true),
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
                          Text(
                            "Adicionar Produto",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (clienteSelecionado != null &&
                      pagamentoSelecionado != null &&
                      produtosSelecionados.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResumoPedidoPage(
                              cliente: clienteSelecionado!,
                              pagamento: pagamentoSelecionado!,
                              produtos: produtosSelecionados,
                              quantidades: quantidades,
                              total: calcularTotal(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Finalizar Pedido",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double parsePreco(String input) {
    input = input.trim();

    if (input.isEmpty) return 0.0;

    input = input.replaceAll(',', '.');

    final dots = '.'.allMatches(input).length;

    if (dots == 0) {
      return double.tryParse(input) ?? 0.0;
    }

    if (dots == 1) {
      int idx = input.indexOf('.');
      int after = input.length - idx - 1;

      if (after == 3) {
        return double.tryParse(input.replaceAll('.', '')) ?? 0.0;
      }

      return double.tryParse(input) ?? 0.0;
    }

    int last = input.lastIndexOf('.');
    String intPart = input.substring(0, last).replaceAll('.', '');
    String decPart = input.substring(last + 1);
    return double.tryParse("$intPart.$decPart") ?? 0.0;
  }


  void editarPrecoProduto(Product p) {
    final precoPadrao = (clienteSelecionado?.lista_preco == 2 ? p.preco2 : p.preco1) ?? 0.0;
    final precoMinimo = p.preco_minimo ?? 0.0;

    String precoInicial = (p.precoEditado ?? precoPadrao)
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    TextEditingController ctrl = TextEditingController(text: precoInicial)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: precoInicial.length,
      );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            double valorDigitado = parsePreco(ctrl.text);

            bool valido = valorDigitado >= precoMinimo;

            return AlertDialog(
              title: Text("Preço"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!valido)
                    Text(
                      "Preço abaixo do mínimo permitido!",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),

                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Digite o preço",
                      prefixText: "R\$ ",
                    ),
                    onChanged: (v) => setStateDialog(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: valido
                      ? () {
                          double novoPreco = parsePreco(ctrl.text);

                          setState(() {
                            p.precoEditado = novoPreco;
                          });

                          Navigator.pop(context);
                        }
                      : null,
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void mostrarDialogoJuros() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Aplicar juros?"),
          content: Text(
            "Deseja aplicar o acréscimo de ${jurosSelecionado.toStringAsFixed(2)}% definido para este plano de pagamento?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => aplicarJuros = false);
                Navigator.pop(context);
              },
              child: Text("Não"),
            ),
            TextButton(
              onPressed: () {
                setState(() => aplicarJuros = true);
                Navigator.pop(context);
              },
              child: Text("Sim"),
            ),
          ],
        );
      },
    );
  }

  final formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );
  
  double calcularTotal() {
    double total = 0.0;

    for (var p in produtosSelecionados) {
      final qtd = quantidades[p.id] ?? 1;

      final precoBase = (clienteSelecionado?.lista_preco == 2 ? p.preco2 : p.preco1) ?? 0.0;
      final preco = p.precoEditado ?? precoBase;

      total += preco * qtd;
    }

    if (aplicarJuros && jurosSelecionado > 0) {
      total = total + (total * (jurosSelecionado / 100));
    }

    return total;
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