import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/client.dart';
import 'models/product.dart';
import 'pedido_confirmado_page.dart';

class ResumoPedidoPage extends StatefulWidget {
  final Cliente cliente;
  final Map<String, dynamic> pagamento;
  final List<Product> produtos;
  final Map<int, int> quantidades;
  final double total;

  const ResumoPedidoPage({
    required this.cliente,
    required this.pagamento,
    required this.produtos,
    required this.quantidades,
    required this.total,
    Key? key,
  }) : super(key: key);

  @override
  State<ResumoPedidoPage> createState() => _ResumoPedidoPageState();
}

class _ResumoPedidoPageState extends State<ResumoPedidoPage> {
  double juros = 0.0;
  double desconto = 0.0;
  final formatador = NumberFormat.simpleCurrency(locale: "pt_BR");

  @override
  void initState() {
    super.initState();

    double totalProdutos = 0;
    for (var p in widget.produtos) {
      final qtd = widget.quantidades[p.id] ?? 1;
      final preco = (p.precoEditado ?? p.preco1);
      totalProdutos += preco * qtd;
    }

    juros = widget.total - totalProdutos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          "Resumo do Pedido",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Cliente:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.cliente.responsavel, style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),

            Text("Forma de Pagamento:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.pagamento["nome"], style: TextStyle(fontSize: 18)),
            SizedBox(height: 5),

            Row(
              children: [
                Expanded(child: Divider(thickness: 2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Produtos",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(thickness: 2)),
              ],
            ),

            SizedBox(height: 1),

            /// produtos
            Expanded(
              child: ListView.builder(
                itemCount: widget.produtos.length,
                itemBuilder: (_, i) {
                  final p = widget.produtos[i];
                  final qtd = widget.quantidades[p.id] ?? 1;
                  final preco = (p.precoEditado ?? p.preco1);
                  final totalProduto = preco * qtd;

                  return Column(
                    children: [
                      SizedBox(height: 4),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.nome,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "$qtd",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Valor Unitário: ${formatador.format(preco)}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            formatador.format(totalProduto),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 1),

                      Divider(thickness: 1),

                    ],
                  );
                },
              ),
            ),

            SizedBox(height: 4),

            Divider(thickness: 2),

            // totais
            Builder(
              builder: (_) {
                double totalProdutos = 0;

                for (var p in widget.produtos) {
                  final qtd = widget.quantidades[p.id] ?? 1;
                  final preco = (p.precoEditado ?? p.preco1);
                  totalProdutos += preco * qtd;
                }

                double totalCalculado = totalProdutos + juros - desconto;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total dos Produtos",
                          style: TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold,),
                        ),
                        Text(
                          formatador.format(totalProdutos),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Juros",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            editarValor(
                              titulo: "Editar Juros",
                              valorAtual: juros,
                              onSalvar: (v) => juros = v,
                            );
                          },
                          child: Text(
                            formatador.format(juros),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Desconto",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            editarValor(
                              titulo: "Editar Desconto",
                              valorAtual: desconto,
                              onSalvar: (v) => desconto = v,
                            );
                          },
                          child: Text(
                            formatador.format(desconto),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TOTAL:",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatador.format(getTotalCalculado()),
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),


            SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PedidoConfirmadoPage(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Confirmar Pedido",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getTotalCalculado() {
    double totalProdutos = 0;

    for (var p in widget.produtos) {
      final qtd = widget.quantidades[p.id] ?? 1;
      final preco = (p.precoEditado ?? p.preco1);
      totalProdutos += preco * qtd;
    }

    return totalProdutos + juros - desconto;
  }

  void editarValor({
    required String titulo,
    required double valorAtual,
    required Function(double) onSalvar,
  }) {
    final texto = valorAtual.toStringAsFixed(2).replaceAll('.', ',');

    TextEditingController ctrl = TextEditingController(text: texto)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: texto.length,
      );

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(titulo),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Digite o valor",
                  prefixText: "R\$ ",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    final valor = parsePreco(ctrl.text);
                    setState(() => onSalvar(valor));
                    Navigator.pop(context);
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      },
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
}
