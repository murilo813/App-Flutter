import 'package:intl/intl.dart';

class Product {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  final int productId;
  final String productName;

  final double auroraStock;
  final double imbuiaStock;
  final double vilanovaStock;
  final double belavistaStock;

  final double auroraAvailable;
  final double imbuiaAvailable;
  final double vilanovaAvailable;
  final double belavistaAvailable;

  final String brand;
  final double price1;
  final double price2;
  final double minimalPrice;
  final String aplication;

  /// Apenas UI / estado local
  double? editedPrice;

  Product({
    required this.productId,
    required this.productName,
    required this.auroraStock,
    required this.imbuiaStock,
    required this.vilanovaStock,
    required this.belavistaStock,
    required this.auroraAvailable,
    required this.imbuiaAvailable,
    required this.vilanovaAvailable,
    required this.belavistaAvailable,
    required this.brand,
    required this.price1,
    required this.price2,
    required this.minimalPrice,
    required this.aplication,
    this.editedPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return Product(
      productId: json['productId'],
      productName: json['productName'],
      auroraStock: d(json['auroraStock']),
      imbuiaStock: d(json['imbuiaStock']),
      vilanovaStock: d(json['vilanovaStock']),
      belavistaStock: d(json['belavistaStock']),
      auroraAvailable: d(json['auroraAvailable']),
      imbuiaAvailable: d(json['imbuiaAvailable']),
      vilanovaAvailable: d(json['vilanovaAvailable']),
      belavistaAvailable: d(json['belavistaAvailable']),
      brand: json['brand'],
      price1: d(json['price1']),
      price2: d(json['price2']),
      minimalPrice: d(json['minimalPrice']),
      aplication: json['aplication'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'auroraStock': auroraStock,
      'imbuiaStock': imbuiaStock,
      'vilanovaStock': vilanovaStock,
      'belavistaStock': belavistaStock,
      'auroraAvailable': auroraAvailable,
      'imbuiaAvailable': imbuiaAvailable,
      'vilanovaAvailable': vilanovaAvailable,
      'belavistaAvailable': belavistaAvailable,
      'brand': brand,
      'price1': price1,
      'price2': price2,
      'minimalPrice': minimalPrice,
      'aplication': aplication,
    };
  }

  String _format(double valor) {
    return _formatter.format(valor).trim();
  }

  String get price1F => _format(price1);
  String get price2F => _format(price2);
  String get minimalPriceF => _format(minimalPrice);
}
