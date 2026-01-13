import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'services/sync_service.dart';
import 'background/local_log.dart';
import 'background/pendents.dart';
import 'models/client.dart';
import 'models/product.dart';
import 'widgets/loading.dart';
import 'widgets/error.dart';
import 'widgets/gradientgreen.dart';
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
  bool erroCritico = false;
  String? mensagemErro;
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

    try {
      final temInternet = await _hasInternet();

      if (temInternet) {
        try {
          await sync.syncClientes();
          await sync.syncObservacoes();
          await sync.syncEstoqueGeral();
          await OfflineQueue.trySendQueue(backendUrl);
        } catch (e, stack) {
          await LocalLogger.log(
            'Erro no sync inicial OrdersPage\nErro: $e\nStack: $stack',
          );
        }
      }

      await carregarClientes();
      await carregarProdutos();

      if (clientes.isEmpty || produtos.isEmpty) {
        setState(() {
          erroCritico = true;
        });
        return;
      }
    } catch (e, stack) {
      await LocalLogger.log('Erro crítico OrdersPage\nErro: $e\nStack: $stack');

      setState(() {
        erroCritico = true;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http
          .get(Uri.parse("$backendUrl/ping"))
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
        "vencimento":
            "${venc.day.toString().padLeft(2, '0')}/"
            "${venc.month.toString().padLeft(2, '0')}/"
            "${venc.year}",
      });
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Loading(icon: Icons.shopping_cart, color: Colors.white),
      );
    }

    if (erroCritico) {
      return ErrorScreen(onRetry: sincronizarAoEntrar);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: GradientGreen.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
        ),
        title: const Text(
          "Pedidos",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo("Cliente"),
            _caixaSelecao(
              label: clienteSelecionado?.nomeCliente ?? "Selecionar Cliente",
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
            const SizedBox(height: 1),

            _titulo("Forma de Pagamento"),
            _caixaSelecao(
              label:
                  pagamentoSelecionado?['nome'] ??
                  "Selecionar Forma de pagamento",
              icon: Icons.payment,
              onTap: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SelecaoPagamentoPage()),
                );
                if (r != null) {
                  setState(() {
                    pagamentoSelecionado = r;
                    aplicarJuros = false;
                  });
                  if (r.containsKey("juros")) {
                    jurosSelecionado = r["juros"] * 1.0;
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      mostrarDialogoJuros,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 5),

            if (pagamentoSelecionado != null) ...[
              const SizedBox(height: 1),
              _buildParcelasTable(),
              const SizedBox(height: 10),
            ],

            _buildSectionTitle("Produtos"),

            ...produtosSelecionados.map(_buildProdutoItem).toList(),

            _buildAddProdutoButton(),

            if (clienteSelecionado != null &&
                pagamentoSelecionado != null &&
                produtosSelecionados.isNotEmpty)
              _buildFinalizarPedidoButton(),
          ],
        ),
      ),
    );
  }

  // ====================== AUXILIARES ======================

  Widget _buildParcelasTable() {
    final parcelas = gerarParcelas();
    final totalParcelas = parcelas.length;
    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          children:
              [
                "Parcela",
                "Vencimento",
                "Valor",
              ].map((t) => _tableCell(t, bold: true)).toList(),
        ),
        ...parcelas.map((p) {
          final valorParcela = calcularTotal() / totalParcelas;
          return TableRow(
            children: [
              _tableCell(p["parcela"]!),
              _tableCell(p["vencimento"]!),
              _tableCell(formatador.format(valorParcela)),
            ],
          );
        }),
        TableRow(
          children: [
            const SizedBox(),
            _tableCell("Total", fontSize: 14, bold: true),
            _tableCell(
              formatador.format(calcularTotal()),
              fontSize: 16,
              bold: true,
              color: Colors.green.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Padding _tableCell(
    String text, {
    double fontSize = 13,
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 2)),
        ],
      ),
    );
  }

  Widget _buildProdutoItem(Product p) {
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
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.nome,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              FutureBuilder(
                future: getEmpresa(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();
                  final emp = snap.data!;
                  final est = estoquePorEmpresa(p, emp);
                  final disp = disponivelPorEmpresa(p, emp);
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
              const SizedBox(height: 10),
              _buildProdutoQuantityRow(p, qtd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoQuantityRow(Product p, int qtd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            _buildQuantityButton(
              Icons.remove,
              Colors.red,
              Colors.red.shade100,
              () {
                if (qtd > 1) {
                  setState(() {
                    quantidades[p.id] = qtd - 1;
                    controllers[p.id]!.text = (qtd - 1).toString();
                  });
                }
              },
            ),
            const SizedBox(width: 14),
            _buildQuantityInput(p),
            const SizedBox(width: 14),
            _buildQuantityButton(
              Icons.add,
              Colors.green,
              Colors.green.shade100,
              () {
                setState(() {
                  quantidades[p.id] = qtd + 1;
                  controllers[p.id]!.text = (qtd + 1).toString();
                });
              },
            ),
          ],
        ),
        InkWell(
          onTap: () => editarPrecoProduto(p),
          child: Text(
            formatador.format(
              p.precoEditado ??
                  (clienteSelecionado?.lista_preco == 2 ? p.preco2 : p.preco1),
            ),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(
    IconData icon,
    Color color,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildQuantityInput(Product p) {
    return Container(
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
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
    );
  }

  Widget _buildAddProdutoButton() {
    return GestureDetector(
      onTap: () async {
        final r = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StorePage(modoSelecao: true)),
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
          children: const [
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
    );
  }

  Widget _buildFinalizarPedidoButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ResumoPedidoPage(
                  clienteId: clienteSelecionado!.id,
                  cliente: clienteSelecionado!,
                  pagamentoId: pagamentoSelecionado!["id"],
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
          gradient: GradientGreen.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
    final precoPadrao =
        (clienteSelecionado?.lista_preco == 2 ? p.preco2 : p.preco1);
    final precoMinimo = p.preco_minimo;

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
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                  onPressed:
                      valido
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

  final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

  double calcularTotal() {
    double total = 0.0;

    for (var p in produtosSelecionados) {
      final qtd = quantidades[p.id] ?? 1;

      final precoBase =
          (clienteSelecionado?.lista_preco == 2 ? p.preco2 : p.preco1);
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

  double estoquePorEmpresa(Product p, int empresa) {
    switch (empresa) {
      case 1:
        return p.estoqueBelavista;
      case 2:
        return p.estoqueImbuia;
      case 3:
        return p.estoqueVilanova;
      case 4:
        return p.estoqueAurora;
      default:
        return 0;
    }
  }

  double disponivelPorEmpresa(Product p, int empresa) {
    switch (empresa) {
      case 1:
        return p.disponivelBelavista;
      case 2:
        return p.disponivelImbuia;
      case 3:
        return p.disponivelVilanova;
      case 4:
        return p.disponivelAurora;
      default:
        return 0;
    }
  }

  Widget _titulo(String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      txt,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _caixaSelecao({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
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
    {
      "id": 66,
      "nome": "7 dias crediario",
      "prazo": [7],
      "parcelas": 1,
    },
    {
      "id": 67,
      "nome": "14 dias crediario",
      "prazo": [14],
      "parcelas": 1,
    },
    {
      "id": 2,
      "nome": "28 dias crediario",
      "prazo": [28],
      "parcelas": 1,
    },
    {
      "id": 29,
      "nome": "42 dias crediario (45 dias)",
      "prazo": [42],
      "parcelas": 1,
      "juros": 2.81,
    },
    {
      "id": 31,
      "nome": "56 dias crediario (60 dias)",
      "prazo": [56],
      "parcelas": 1,
      "juros": 3.77,
    },
    {
      "id": 32,
      "nome": "84 dias crediario (90 dias)",
      "prazo": [84],
      "parcelas": 1,
      "juros": 5.7,
    },

    {
      "id": 37,
      "nome": "2 parcelas crediario",
      "prazo": [28, 56],
      "parcelas": 2,
      "juros": 2.81,
    },
    {
      "id": 35,
      "nome": "3 parcelas crediario (1 parcela avista)",
      "prazo": [0, 28, 56],
      "parcelas": 3,
    },
    {
      "id": 39,
      "nome": "3 parcelas crediario",
      "prazo": [28, 56, 84],
      "parcelas": 3,
      "juros": 3.77,
    },
    {
      "id": 45,
      "nome": "4 parcelas crediario",
      "prazo": [28, 56, 84, 112],
      "parcelas": 4,
      "juros": 4.73,
    },
    {
      "id": 41,
      "nome": "5 parcelas crediario",
      "prazo": [28, 56, 84, 112, 140],
      "parcelas": 5,
      "juros": 5.7,
    },
    {
      "id": 42,
      "nome": "7 parcelas crediario",
      "prazo": [28, 56, 84, 112, 140, 168, 196],
      "parcelas": 7,
      "juros": 7.67,
    },

    // boleto
    {
      "id": 64,
      "nome": "7 dias boleto",
      "prazo": [7],
      "parcelas": 1,
    },
    {
      "id": 65,
      "nome": "14 dias boleto",
      "prazo": [14],
      "parcelas": 1,
    },
    {
      "id": 28,
      "nome": "28 dias boleto",
      "prazo": [28],
      "parcelas": 1,
    },
    {
      "id": 30,
      "nome": "42 dias boleto (45 dias)",
      "prazo": [42],
      "parcelas": 1,
      "juros": 2.81,
    },
    {
      "id": 33,
      "nome": "56 dias boleto (60 dias)",
      "prazo": [56],
      "parcelas": 1,
      "juros": 3.77,
    },
    {
      "id": 34,
      "nome": "84 dias boleto (90 dias)",
      "prazo": [84],
      "parcelas": 1,
      "juros": 5.7,
    },
    {
      "id": 49,
      "nome": "112 dias boleto (120 dias)",
      "prazo": [112],
      "parcelas": 1,
      "juros": 7.67,
    },
    {
      "id": 48,
      "nome": "140 dias boleto (150 dias)",
      "prazo": [140],
      "parcelas": 1,
      "juros": 9.68,
    },

    {
      "id": 38,
      "nome": "2 parcelas boleto",
      "prazo": [28, 56],
      "parcelas": 2,
      "juros": 2.81,
    },
    {
      "id": 36,
      "nome": "3 parcelas boleto (1 parcela avista)",
      "prazo": [0, 28, 56],
      "parcelas": 3,
    },
    {
      "id": 40,
      "nome": "3 parcelas boleto",
      "prazo": [28, 56, 84],
      "parcelas": 3,
      "juros": 3.77,
    },
    {
      "id": 46,
      "nome": "4 parcelas boleto (1 parcela avista)",
      "prazo": [0, 28, 56, 84],
      "parcelas": 4,
      "juros": 2.81,
    },
    {
      "id": 47,
      "nome": "6 parcelas boleto",
      "prazo": [28, 56, 84, 112, 140, 168],
      "parcelas": 6,
      "juros": 6.68,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Forma de Pagamento")),
      body: ListView(
        children:
            metodos.map((m) {
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
