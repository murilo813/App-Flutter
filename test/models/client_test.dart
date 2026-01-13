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

      final cliente = Cliente.fromJson(json);

      expect(cliente.nomeCliente, 'MARCOLINO DOS SANTOS');
      expect(cliente.id, 123);
      expect(cliente.data_nasc?.year, 1990);
      expect(cliente.data_nasc?.month, 5);
      expect(cliente.data_nasc?.day, 15);
      expect(cliente.id, 123);
    });

    test('Deve lidar com campos nulos no JSON sem crashar', () {
      final json = {
        'nome_cliente': 'MARCOLINO DOS SANTOS',
        'limite': 0.0,
        'saldo_limite': 0.0,
        'limite_calculado': 0.0,
        'saldo_limite_calculado': 0.0,
        'id_cliente': 999,
        // data_nasc e lista_preco ausentes
      };

      final cliente = Cliente.fromJson(json);

      expect(cliente.responsavel, "", reason: 'Responsável deve ser "" caso não venha'); // testa os ??
      expect(cliente.lista_preco, 1, reason: 'Lista preço deve ser 1 caso não venha');
      expect(cliente.data_nasc, isNull, reason: 'Data nascimento deve aceitar nulo');
    });

    test('Deve tratar string de data vazia como null', () {
      final json = {
        'nome_cliente': 'MARCOLINO DOS SANTOS',
        'id_cliente': 1,
        'limite': 0.0,
        'saldo_limite': 0.0,
        'limite_calculado': 0.0,
        'saldo_limite_calculado': 0.0,
        'data_nasc': "",
      };
      final cliente = Cliente.fromJson(json);
      expect(cliente.data_nasc, isNull);
    });
    test('Deve formatar valores monetários corretamente para PT-BR', () {
      final cliente = Cliente(
        nomeCliente: 'MARCOLINO DOS SANTOS',
        responsavel: '',
        limite: -1250.50,
        saldo_limite: 0,
        limite_calculado: 0,
        saldo_limite_calculado: 0,
        id: 1,
      );

      final resultadoLimpo = cliente.limiteFormatado.replaceAll(
        RegExp(r'\s+'),
        '',
      ); // o pacote intl não usa espaço comum entre o negativo e o número, ele usa um caractere especial chamado NBSP, por isso fazemos isto
      expect(resultadoLimpo, "-1.250,50");
    });
    test('Deve converter o objeto Cliente de volta para JSON corretamente', () {
      final data = DateTime(1990, 5, 15);
      final cliente = Cliente(
        id: 123,
        nomeCliente: 'MARCOLINO DOS SANTOS',
        responsavel: 'MARCOS CASTRO',
        limite: 1000.0,
        saldo_limite: -500.0,
        limite_calculado: 1000.0,
        saldo_limite_calculado: 500.0,
        data_nasc: data,
        lista_preco: 2,
      );
      final json = cliente.toJson();
      expect(json['id_cliente'], 123);
      expect(json['nome_cliente'], 'MARCOLINO DOS SANTOS');
      expect(json['limite'], 1000.0);

      expect(json['data_nasc'], isA<DateTime>());
      expect((json['data_nasc'] as DateTime).year, 1990);
    });
  });
}