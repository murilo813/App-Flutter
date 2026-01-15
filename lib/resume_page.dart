import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'services/http_client.dart';
import 'background/pendents.dart';
import 'background/local_log.dart';
import 'models/client.dart';
import 'models/product.dart';
import 'widgets/gradientgreen.dart';
import 'pedido_confirmado_page.dart';
import 'secrets.dart';

class ResumoPedidoPage extends StatefulWidget {
  final int clienteId;
  final Cliente cliente;
  final int pagamentoId;
  final DateTime? vencimentoEditado;
  final Map<String, dynamic> pagamento;
  final List<Product> produtos;
  final Map<int, int> quantidades;
  final double total;

  const ResumoPedidoPage({
    required this.clienteId,
    required this.cliente,
    required this.pagamentoId,
    this.vencimentoEditado,
    required this.pagamento,
    required this.produtos,
    required this.quantidades,
    required this.total,
    super.key,
  });

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
      totalProdutos += precoProduto(p) * qtd;
    }

    juros = widget.total - totalProdutos;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
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
            const Text(
              "Cliente:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.cliente.nomeCliente,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),

            const Text(
              "Forma de Pagamento:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.pagamento["nome"],
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 5),

            const Row(
              children: [
                Expanded(child: Divider(thickness: 2)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Produtos",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider(thickness: 2)),
              ],
            ),

            const SizedBox(height: 1),

            /// produtos
            Expanded(
              child: ListView.builder(
                itemCount: widget.produtos.length,
                itemBuilder: (_, i) {
                  final p = widget.produtos[i];
                  final qtd = widget.quantidades[p.id] ?? 1;
                  final preco = precoProduto(p);
                  final totalProduto = preco * qtd;

                  return Column(
                    children: [
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "$qtd",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Valor Unitário: ${formatador.format(preco)}",
                            style: const TextStyle(
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

                      const SizedBox(height: 1),

                      const Divider(thickness: 1),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            const Divider(thickness: 2),

            // totais
            Builder(
              builder: (_) {
                double totalProdutos = 0;

                for (var p in widget.produtos) {
                  final qtd = widget.quantidades[p.id] ?? 1;
                  totalProdutos += precoProduto(p) * qtd;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total dos Produtos",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatador.format(totalProdutos),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
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
                              onSalvar: (v) {
                                setState(() {
                                  juros = v;
                                });
                              },
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

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
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
                              onSalvar: (v) {
                                setState(() {
                                  desconto = v;
                                });
                              },
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
                const Text(
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

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                final url = "/pedido";
                final body = montarJsonPedido();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PedidoConfirmadoPage(),
                  ),
                );

                () async {
                  try {
                    final online = await hasInternetConnection();

                    if (online) {
                      final httpClient = HttpClient();
                      final response = await httpClient.post(url, body);

                      if (response.statusCode != 200) {
                        await OfflineQueue.addToQueue({
                          "url": url,
                          "body": body,
                        });
                      }
                    } else {
                      await OfflineQueue.addToQueue({"url": url, "body": body});
                    }
                  } catch (e, stack) {
                    await LocalLogger.log('Erro ao enviar pedido: $e\n$stack');

                    await OfflineQueue.addToQueue({"url": url, "body": body});
                  }
                }();
              },

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: GradientGreen.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
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

  Map<String, dynamic> montarJsonPedido() {
    final Map<String, dynamic> json = {
      "id_cliente": widget.clienteId,
      "listaPreco": widget.cliente.listaPreco,
      "id_pagamento": widget.pagamentoId,
      "juros": juros,
      "desconto": desconto,
      "data": DateTime.now().toIso8601String(),
      "itens":
          widget.produtos.map((p) {
            final qtd = widget.quantidades[p.id] ?? 1;

            return {
              "id_produto": p.id,
              "quantidade": qtd,
              "preco_unitario": precoProduto(p),
            };
          }).toList(),
    };

    if (widget.vencimentoEditado != null) {
      json["data_vencimento"] = widget.vencimentoEditado!.toIso8601String();
    }

    return json;
  }

  double precoProduto(Product p) {
    if (p.precoEditado != null) {
      return p.precoEditado!;
    }

    return widget.cliente.listaPreco == 2 ? p.preco2 : p.preco1;
  }

  double getTotalCalculado() {
    double totalProdutos = 0;

    for (var p in widget.produtos) {
      final qtd = widget.quantidades[p.id] ?? 1;
      totalProdutos += precoProduto(p) * qtd;
    }

    return totalProdutos + juros - desconto;
  }

  void editarValor({
    required String titulo,
    required double valorAtual,
    required Function(double) onSalvar,
  }) {
    final texto = valorAtual.toStringAsFixed(2).replaceAll('.', ',');

    final TextEditingController ctrl = TextEditingController(text: texto)
      ..selection = TextSelection(baseOffset: 0, extentOffset: texto.length);

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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Digite o valor",
                  prefixText: "R\$ ",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    final valor = parsePreco(ctrl.text);
                    setState(() => onSalvar(valor));
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
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
      final int idx = input.indexOf('.');
      final int after = input.length - idx - 1;

      if (after == 3) {
        return double.tryParse(input.replaceAll('.', '')) ?? 0.0;
      }

      return double.tryParse(input) ?? 0.0;
    }

    final int last = input.lastIndexOf('.');
    final String intPart = input.substring(0, last).replaceAll('.', '');
    final String decPart = input.substring(last + 1);

    return double.tryParse("$intPart.$decPart") ?? 0.0;
  }
}
