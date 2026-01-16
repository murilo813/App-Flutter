import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/product.dart';

void main() {
  group('Product Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto Product', () {
      final json = {
        'productId': 10,
        'productName': 'GLIFOSATO',
        'auroraStock': 15.5,
        'imbuiaStock': 10.0,
        'vilanovaStock': 5,
        'belavistaStock': 0,
        'auroraAvailable': 15.5,
        'imbuiaAvailable': 8.0,
        'vilanovaAvailable': 5,
        'belavistaAvailable': 0,
        'brand': 'MARCA TESTE',
        'price1': 320.90,
        'price2': 30.00,
        'minimalPrice': 300.00,
        'aplication': 'PASTAGEM',
      };

      final product = Product.fromJson(json);

      expect(product.productId, 10);
      expect(product.productName, 'GLIFOSATO');
      expect(
        product.auroraStock,
        15.5,
        reason: 'Deve manter a precisão decimal',
      );
      expect(
        product.vilanovaStock,
        5.0,
        reason: 'Deve converter int para double corretamente',
      );
      expect(product.brand, 'MARCA TESTE');
      expect(product.minimalPrice, 300.00);
    });

    test('Deve lidar com campos nulos e opcionais usando valores padrão', () {
      final json = {
        'productId': 1,
        'productName': 'PRODUTO SEM INFO',
        'auroraStock': null,
        'brand': 'GENERICO',
        'price1': 10.0,
        'price2': 9.0,
        // imbuiaStock, minimalPrice e aplication ausentes
      };

      final product = Product.fromJson(json);

      expect(product.auroraStock, 0.0, reason: 'Estoque nulo deve virar 0.0');
      expect(
        product.imbuiaStock,
        0.0,
        reason: 'Campo ausente deve virar 0.0',
      );
      expect(
        product.minimalPrice,
        0.0,
        reason: 'Preço mínimo ausente deve virar 0.0',
      );
      expect(
        product.aplication,
        '',
        reason: 'Aplicação deve ser string vazia caso não venha',
      );
    });

    test('Deve formatar preços corretamente para PT-BR', () {
      final product = Product(
        productId: 1,
        productName: 'Teste',
        auroraStock: 0,
        imbuiaStock: 0,
        vilanovaStock: 0,
        belavistaStock: 0,
        auroraAvailable: 0,
        imbuiaAvailable: 0,
        vilanovaAvailable: 0,
        belavistaAvailable: 0,
        brand: '',
        price1: 1250.50,
        price2: 1000.00,
        minimalPrice: 950.45,
        aplication: '',
      );

      final formatedPrice = product.price1F.replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final formatedMinimalPrice = product.minimalPriceF.replaceAll(
        RegExp(r'\s+'),
        '',
      );

      expect(formatedPrice, "1.250,50");
      expect(formatedMinimalPrice, "950,45");
    });

    test('Deve converter o objeto Product de volta para JSON corretamente', () {
      final product = Product(
        productId: 50,
        productName: 'SEMENTE',
        auroraStock: 20.5,
        imbuiaStock: 0,
        vilanovaStock: 0,
        belavistaStock: 0,
        auroraAvailable: 20.5,
        imbuiaAvailable: 0,
        vilanovaAvailable: 0,
        belavistaAvailable: 0,
        brand: 'SEMM',
        price1: 45.0,
        price2: 40.0,
        minimalPrice: 38.0,
        aplication: 'TERRA',
      );

      final json = product.toJson();

      expect(json['productId'], 50);
      expect(json['productName'], 'SEMENTE');
      expect(json['auroraStock'], 20.5);
      expect(json['brand'], 'SEMM');
      expect(json['aplication'], 'TERRA');
    });

    test('Deve permitir o uso do campo opcional precoEditado', () {
      final product = Product(
        productId: 1,
        productName: 'A',
        auroraStock: 0,
        imbuiaStock: 0,
        vilanovaStock: 0,
        belavistaStock: 0,
        auroraAvailable: 0,
        imbuiaAvailable: 0,
        vilanovaAvailable: 0,
        belavistaAvailable: 0,
        brand: '',
        price1: 10,
        price2: 10,
        minimalPrice: 10,
        aplication: '',
      );

      expect(product.editedPrice, isNull);

      product.editedPrice = 15.50;
      expect(product.editedPrice, 15.50);
    });
  });
}
