import 'package:intl/intl.dart';

class Product {
  final int id;
  final String nome;
  final int estoqueAurora;
  final int estoqueImbuia;
  final int estoqueVilanova;
  final int estoqueBelavista;
  final int disponivelAurora;
  final int disponivelImbuia;
  final int disponivelVilanova;
  final int disponivelBelavista;
  final String marca;
  final double preco1;
  final double preco2;
  final double preco_minimo;
  final String aplicacao;

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
    required this.preco_minimo,
    required this.aplicacao,
    this.precoEditado,
  });

  // como eu tenho certeza do tipo que os valores vem da api, eu nao trato outros tipos de dados ou faço conversoes
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nome: json['nome'],  
      estoqueAurora: (double.tryParse(json['estoque_aurora']?.toString() ?? '0') ?? 0).toInt(),
      estoqueImbuia: (double.tryParse(json['estoque_imbuia']?.toString() ?? '0') ?? 0).toInt(),
      estoqueVilanova: (double.tryParse(json['estoque_vilanova']?.toString() ?? '0') ?? 0).toInt(),
      estoqueBelavista: (double.tryParse(json['estoque_belavista']?.toString() ?? '0') ?? 0).toInt(),
      disponivelAurora: (double.tryParse(json['disponivel_aurora']?.toString() ?? '0') ?? 0).toInt(),
      disponivelImbuia: (double.tryParse(json['disponivel_imbuia']?.toString() ?? '0') ?? 0).toInt(),
      disponivelVilanova: (double.tryParse(json['disponivel_vilanova']?.toString() ?? '0') ?? 0).toInt(),
      disponivelBelavista: (double.tryParse(json['disponivel_belavista']?.toString() ?? '0') ?? 0).toInt(),
      marca: json['marca'],
      preco1: json['preco1'],
      preco2: json['preco2'],
      preco_minimo: (json['preco_minimo'] ?? 0).toDouble(),
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
      'preco_minimo': preco_minimo,
      'aplicacao': aplicacao,
    };
  }

  String formatarPreco(double preco) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(preco).trim();
  }

  String get preco1Formatado => formatarPreco(preco1);
  String get preco2Formatado => formatarPreco(preco2);
  String get precomFormatado => formatarPreco(preco_minimo);
}