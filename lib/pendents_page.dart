import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'background/pendents.dart';
import 'secrets.dart';

class PendentsPage extends StatefulWidget {
  const PendentsPage({Key? key}) : super(key: key);

  @override
  State<PendentsPage> createState() => _PendentsPageState();
}

class _PendentsPageState extends State<PendentsPage> {
  List<Map<String, dynamic>> pendentes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final data = await OfflineQueue.getQueue();
    setState(() {
      pendentes = data;
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Pendentes (${pendentes.length})"),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            tooltip: "Forçar envio",
            onPressed: () async {
              await OfflineQueue.trySendQueue(backendUrl);
              await carregar();
            },
          ),
        ],
      ),
      body:
          carregando
              ? Center(child: CircularProgressIndicator())
              : pendentes.isEmpty
              ? Center(child: Text("Nenhum pedido pendente"))
              : ListView.builder(
                itemCount: pendentes.length,
                itemBuilder: (_, i) {
                  final item = pendentes[i];
                  final body = item['body'];
                  final createdAt = item['created_at'];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// rota
                          Text(
                            item['url'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// data
                          if (item['created_at'] != null)
                            Text(
                              "Criado em: ${formatarData(item['created_at'])}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),

                          const SizedBox(height: 8),

                          /// JSON bruto
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prettyJson(item['body']),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String prettyJson(dynamic body) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  String formatarData(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
