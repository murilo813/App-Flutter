import 'package:intl/intl.dart';

class Client {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  final int id;
  final String nomeCliente;
  final String responsavel;
  final double limite;
  final double saldoLimite;
  final double limiteCalculado;
  final double saldoLimiteCalculado;
  final DateTime? dataNasc;
  final DateTime? ultimaCompra;
  final int listaPreco;

  Client({
    required this.id,
    required this.nomeCliente,
    required this.responsavel,
    required this.limite,
    required this.saldoLimite,
    required this.limiteCalculado,
    required this.saldoLimiteCalculado,
    this.dataNasc,
    this.ultimaCompra,
    this.listaPreco = 1,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id_cliente'],
      nomeCliente: json['nome_cliente'],
      responsavel: json['responsavel'] ?? '',
      limite: (json['limite'] as num).toDouble(),
      saldoLimite: (json['saldo_limite'] as num).toDouble(),
      limiteCalculado: (json['limite_calculado'] as num).toDouble(),
      saldoLimiteCalculado: (json['saldo_limite_calculado'] as num).toDouble(),
      dataNasc:
          json['data_nasc'] != null && json['data_nasc'] != ''
              ? DateTime.tryParse(json['data_nasc'])
              : null,
      ultimaCompra:
          json['ultima_compra'] != null && json['ultima_compra'] != ''
              ? DateTime.tryParse(json['ultima_compra'])
              : null,
      listaPreco: json['lista_preco'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': id,
      'nome_cliente': nomeCliente,
      'responsavel': responsavel,
      'limite': limite,
      'saldo_limite': saldoLimite,
      'limite_calculado': limiteCalculado,
      'saldo_limite_calculado': saldoLimiteCalculado,
      'data_nasc': dataNasc?.toIso8601String(),
      'ultima_compra': ultimaCompra?.toIso8601String(),
      'lista_preco': listaPreco,
    };
  }

  String _formatar(double valor) {
    return _formatter.format(valor).trim();
  }
  String get limiteFormatado => _formatar(limite);
  String get saldoFormatado => _formatar(saldoLimite);
  String get limiteCalculadoFormatado => _formatar(limiteCalculado);
  String get saldoCalculadoFormatado => _formatar(saldoLimiteCalculado);
}
