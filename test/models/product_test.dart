import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/product.dart';

void main() {
  group('Product Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto Product', () {
      final json = {
        'id': 10,
        'nome': 'GLIFOSATO',
        'estoque_aurora': 15.5,
        'estoque_imbuia': 10.0,
        'estoque_vilanova': 5,
        'estoque_belavista': 0,
        'disponivel_aurora': 15.5,
        'disponivel_imbuia': 8.0,
        'disponivel_vilanova': 5,
        'disponivel_belavista': 0,
        'marca': 'MARCA TESTE',
        'preco1': 320.90,
        'preco2': 30.00,
        'preco_minimo': 300.00,
        'aplicacao': 'PASTAGEM',
      };

      final produto = Product.fromJson(json);

      expect(produto.id, 10);
      expect(produto.nome, 'GLIFOSATO');
      expect(
        produto.estoqueAurora,
        15.5,
        reason: 'Deve manter a precisão decimal',
      );
      expect(
        produto.estoqueVilanova,
        5.0,
        reason: 'Deve converter int para double corretamente',
      );
      expect(produto.marca, 'MARCA TESTE');
      expect(produto.preco_minimo, 300.00);
    });

    test('Deve lidar com campos nulos e opcionais usando valores padrão', () {
      final json = {
        'id': 1,
        'nome': 'PRODUTO SEM INFO',
        'estoque_aurora': null,
        'marca': 'GENERICO',
        'preco1': 10.0,
        'preco2': 9.0,
        // estoque_imbuia, preco_minimo e aplicacao ausentes
      };

      final produto = Product.fromJson(json);

      expect(produto.estoqueAurora, 0.0, reason: 'Estoque nulo deve virar 0.0');
      expect(
        produto.estoqueImbuia,
        0.0,
        reason: 'Campo ausente deve virar 0.0',
      );
      expect(
        produto.preco_minimo,
        0.0,
        reason: 'Preço mínimo ausente deve virar 0.0',
      );
      expect(
        produto.aplicacao,
        '',
        reason: 'Aplicação deve ser string vazia caso não venha',
      );
    });

    test('Deve formatar preços corretamente para PT-BR', () {
      final produto = Product(
        id: 1,
        nome: 'Teste',
        estoqueAurora: 0,
        estoqueImbuia: 0,
        estoqueVilanova: 0,
        estoqueBelavista: 0,
        disponivelAurora: 0,
        disponivelImbuia: 0,
        disponivelVilanova: 0,
        disponivelBelavista: 0,
        marca: '',
        preco1: 1250.50,
        preco2: 1000.00,
        preco_minimo: 950.45,
        aplicacao: '',
      );

      final precoFormatado = produto.preco1Formatado.replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final precoMinFormatado = produto.precomFormatado.replaceAll(
        RegExp(r'\s+'),
        '',
      );

      expect(precoFormatado, "1.250,50");
      expect(precoMinFormatado, "950,45");
    });

    test('Deve converter o objeto Product de volta para JSON corretamente', () {
      final produto = Product(
        id: 50,
        nome: 'SEMENTE',
        estoqueAurora: 20.5,
        estoqueImbuia: 0,
        estoqueVilanova: 0,
        estoqueBelavista: 0,
        disponivelAurora: 20.5,
        disponivelImbuia: 0,
        disponivelVilanova: 0,
        disponivelBelavista: 0,
        marca: 'SEMM',
        preco1: 45.0,
        preco2: 40.0,
        preco_minimo: 38.0,
        aplicacao: 'TERRA',
      );

      final json = produto.toJson();

      expect(json['id'], 50);
      expect(json['nome'], 'SEMENTE');
      expect(json['estoque_aurora'], 20.5);
      expect(json['marca'], 'SEMM');
      expect(json['aplicacao'], 'TERRA');
    });

    test('Deve permitir o uso do campo opcional precoEditado', () {
      final produto = Product(
        id: 1,
        nome: 'A',
        estoqueAurora: 0,
        estoqueImbuia: 0,
        estoqueVilanova: 0,
        estoqueBelavista: 0,
        disponivelAurora: 0,
        disponivelImbuia: 0,
        disponivelVilanova: 0,
        disponivelBelavista: 0,
        marca: '',
        preco1: 10,
        preco2: 10,
        preco_minimo: 10,
        aplicacao: '',
      );

      expect(produto.precoEditado, isNull);

      produto.precoEditado = 15.50;
      expect(produto.precoEditado, 15.50);
    });
  });
}
