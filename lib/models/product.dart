import 'package:intl/intl.dart';

class Product {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  final int id;
  final String nome;

  final double estoqueAurora;
  final double estoqueImbuia;
  final double estoqueVilanova;
  final double estoqueBelavista;

  final double disponivelAurora;
  final double disponivelImbuia;
  final double disponivelVilanova;
  final double disponivelBelavista;

  final String marca;
  final double preco1;
  final double preco2;
  final double precoMinimo;
  final String aplicacao;

  /// Apenas UI / estado local
  double? precoEditado;

  Product({
    required this.id,
    required this.nome,
    required this.estoqueAurora,
    required this.estoqueImbuia,
    required this.estoqueVilanova,
    required this.estoqueBelavista,
    required this.disponivelAurora,
    required this.disponivelImbuia,
    required this.disponivelVilanova,
    required this.disponivelBelavista,
    required this.marca,
    required this.preco1,
    required this.preco2,
    required this.precoMinimo,
    required this.aplicacao,
    this.precoEditado,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return Product(
      id: json['id'],
      nome: json['nome'],
      estoqueAurora: d(json['estoque_aurora']),
      estoqueImbuia: d(json['estoque_imbuia']),
      estoqueVilanova: d(json['estoque_vilanova']),
      estoqueBelavista: d(json['estoque_belavista']),
      disponivelAurora: d(json['disponivel_aurora']),
      disponivelImbuia: d(json['disponivel_imbuia']),
      disponivelVilanova: d(json['disponivel_vilanova']),
      disponivelBelavista: d(json['disponivel_belavista']),
      marca: json['marca'],
      preco1: d(json['preco1']),
      preco2: d(json['preco2']),
      precoMinimo: d(json['preco_minimo']),
      aplicacao: json['aplicacao'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'estoque_aurora': estoqueAurora,
      'estoque_imbuia': estoqueImbuia,
      'estoque_vilanova': estoqueVilanova,
      'estoque_belavista': estoqueBelavista,
      'disponivel_aurora': disponivelAurora,
      'disponivel_imbuia': disponivelImbuia,
      'disponivel_vilanova': disponivelVilanova,
      'disponivel_belavista': disponivelBelavista,
      'marca': marca,
      'preco1': preco1,
      'preco2': preco2,
      'preco_minimo': precoMinimo,
      'aplicacao': aplicacao,
    };
  }

  String _formatar(double valor) {
    return _formatter.format(valor).trim();
  }

  String get preco1Formatado => _formatar(preco1);
  String get preco2Formatado => _formatar(preco2);
  String get precoMinimoFormatado => _formatar(precoMinimo);
}
