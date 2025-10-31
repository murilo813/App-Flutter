import 'package:intl/intl.dart';

class Cliente {
  final String nomeCliente;
  final String responsavel;
  final double limite;
  final double saldo_limite;
  final double limite_calculado;
  final double saldo_limite_calculado;
  final DateTime? data_nasc;
  final int id; 
  final DateTime? ultima_compra;

  Cliente({
    required this.nomeCliente,
    required this.responsavel,
    required this.limite,
    required this.saldo_limite,
    required this.limite_calculado,
    required this.saldo_limite_calculado,
    this.data_nasc,
    required this.id,
    this.ultima_compra,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      nomeCliente: json['nome_cliente'],
      responsavel: json['responsavel'] ?? "",
      limite: json['limite'],
      saldo_limite: json['saldo_limite'],
      limite_calculado: json['limite_calculado'],
      saldo_limite_calculado: json['saldo_limite_calculado'],
      data_nasc: json['data_nasc'] != null && json['data_nasc'] != ""
          ? DateTime.parse(json['data_nasc'])
          : null,
      id: json['id_cliente'], 
      ultima_compra: json['ultima_compra'] != null && json['ultima_compra'] != ""
          ? DateTime.parse(json['ultima_compra'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome_cliente': nomeCliente,
      'responsavel': responsavel,
      'limite': limite,
      'saldo_limite': saldo_limite,
      'limite_calculado': limite_calculado,
      'saldo_limite_calculado': saldo_limite_calculado,
      'data_nasc': data_nasc,
      'id_cliente': id,
      'ultima_compra': ultima_compra,
    };
  }

  String formatarlimites(double limites) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(limites).trim();
  }

  String get limiteFormatado => formatarlimites(limite);
  String get saldoFormatado => formatarlimites(saldo_limite);
  String get limiteCFormatado => formatarlimites(limite_calculado);
  String get saldoCFormatado => formatarlimites(saldo_limite_calculado);
}