import 'package:intl/intl.dart';

class Product {
  final String nome;
  final int estoqueAurora;
  final int estoqueImbuia;
  final int estoqueVilanova;
  final int estoqueBelavista;
  final int disponivelAurora;
  final int disponivelImbuia;
  final int disponivelVilanova;
  final int disponivelBelavista;
  final double preco1;
  final double preco2;

  Product({
    required this.nome,
    required this.estoqueAurora,
    required this.estoqueImbuia,
    required this.estoqueVilanova,
    required this.estoqueBelavista,
    required this.disponivelAurora,
    required this.disponivelImbuia,
    required this.disponivelVilanova,
    required this.disponivelBelavista,
    required this.preco1,
    required this.preco2,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nome: json['nome'] ?? '',  
      estoqueAurora: int.tryParse(json['estoque_aurora']?.toString() ?? '0') ?? 0,
      estoqueImbuia: int.tryParse(json['estoque_imbuia']?.toString() ?? '0') ?? 0,
      estoqueVilanova: int.tryParse(json['estoque_vilanova']?.toString() ?? '0') ?? 0,
      estoqueBelavista: int.tryParse(json['estoque_belavista']?.toString() ?? '0') ?? 0,
      disponivelAurora: int.tryParse(json['disponivel_aurora']?.toString() ?? '0') ?? 0,
      disponivelImbuia: int.tryParse(json['disponivel_imbuia']?.toString() ?? '0') ?? 0,
      disponivelVilanova: int.tryParse(json['disponivel_vilanova']?.toString() ?? '0') ?? 0,
      disponivelBelavista: int.tryParse(json['disponivel_belavista']?.toString() ?? '0') ?? 0,
      preco1: double.tryParse(json['preco1']?.toString() ?? '0.0') ?? 0.0,
      preco2: double.tryParse(json['preco2']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'estoque_aurora': estoqueAurora,
      'estoque_imbuia': estoqueImbuia,
      'estoque_vilanova': estoqueVilanova,
      'estoque_belavista': estoqueBelavista,
      'disponivel_aurora': disponivelAurora,
      'disponivel_imbuia': disponivelImbuia,
      'disponivel_vilanova': disponivelVilanova,
      'disponivel_belavista': disponivelBelavista,
      'preco1': preco1,
      'preco2': preco2,
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
}
