import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/client.dart';

void main() {
  group('Cliente Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto Cliente', () {
      final json = {
        'nome_cliente': 'MARCOLINO DOS SANTOS',
        'responsavel': 'MARCOS CASTRO',
        'limite': 1000.0,
        'saldo_limite': -500.0,
        'limite_calculado': 1000.0,
        'saldo_limite_calculado': 500.0,
        'id_cliente': 123,
        'data_nasc': '1990-05-15',
        'lista_preco': 2,
      };

      final cliente = Client.fromJson(json);

      expect(cliente.nomeCliente, 'MARCOLINO DOS SANTOS');
      expect(cliente.responsavel, 'MARCOS CASTRO');
      expect(cliente.id, 123);
      expect(cliente.listaPreco, 2);
      expect(cliente.dataNasc?.year, 1990);
      expect(cliente.dataNasc?.month, 5);
      expect(cliente.dataNasc?.day, 15);
    });

    test('Deve lidar com campos nulos no JSON sem crashar', () {
      final json = {
        'nome_cliente': 'MARCOLINO DOS SANTOS',
        'limite': 0.0,
        'saldo_limite': 0.0,
        'limite_calculado': 0.0,
        'saldo_limite_calculado': 0.0,
        'id_cliente': 999,
      };

      final cliente = Client.fromJson(json);

      expect(cliente.responsavel, '');
      expect(cliente.listaPreco, 1);
      expect(cliente.dataNasc, isNull);
    });

    test('Deve tratar string de data vazia como null', () {
      final json = {
        'nome_cliente': 'MARCOLINO DOS SANTOS',
        'id_cliente': 1,
        'limite': 0.0,
        'saldo_limite': 0.0,
        'limite_calculado': 0.0,
        'saldo_limite_calculado': 0.0,
        'data_nasc': '',
      };

      final cliente = Client.fromJson(json);
      expect(cliente.dataNasc, isNull);
    });

    test('Deve formatar valores monetários corretamente para PT-BR', () {
      final cliente = Client(
        id: 1,
        nomeCliente: 'MARCOLINO DOS SANTOS',
        responsavel: '',
        limite: -1250.50,
        saldoLimite: 0,
        limiteCalculado: 0,
        saldoLimiteCalculado: 0,
      );

      final resultadoLimpo = cliente.limiteFormatado.replaceAll(
        RegExp(r'\s+'),
        '',
      );

      expect(resultadoLimpo, '-1.250,50');
    });

    test('Deve converter o objeto Cliente de volta para JSON corretamente', () {
      final data = DateTime(1990, 5, 15);

      final cliente = Client(
        id: 123,
        nomeCliente: 'MARCOLINO DOS SANTOS',
        responsavel: 'MARCOS CASTRO',
        limite: 1000.0,
        saldoLimite: -500.0,
        limiteCalculado: 1000.0,
        saldoLimiteCalculado: 500.0,
        dataNasc: data,
        listaPreco: 2,
      );

      final json = cliente.toJson();

      expect(json['id_cliente'], 123);
      expect(json['nome_cliente'], 'MARCOLINO DOS SANTOS');
      expect(json['limite'], 1000.0);
      expect(json['data_nasc'], data.toIso8601String());
    });
  });
}
