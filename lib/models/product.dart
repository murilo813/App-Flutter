import 'package:intl/intl.dart';

class Product {
  final String nome;
  final String estoque;
  final String disponivel;
  final double preco1;
  final double preco2;

  Product({
    required this.nome,
    required this.estoque,
    required this.disponivel,
    required this.preco1,
    required this.preco2,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nome: json['nome'] ?? '',
      estoque: json['estoque'] ?? '',
      disponivel: json['disponivel'] ?? '',
      preco1: double.tryParse(json['preco1']?.toString() ?? '0.0') ?? 0.0,
      preco2: double.tryParse(json['preco2']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  // Para exibição formatada (R$ com vírgula)
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

  // Para salvar no banco local
  Map<String, dynamic> toMap() => {
        'nome': nome,
        'estoque': estoque,
        'disponivel': disponivel,
        'preco1': preco1,
        'preco2': preco2,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        nome: map['nome'] ?? '',
        estoque: map['estoque'] ?? '',
        disponivel: map['disponivel'] ?? '',
        preco1: (map['preco1'] as num).toDouble(),
        preco2: (map['preco2'] as num).toDouble(),
      );
}
