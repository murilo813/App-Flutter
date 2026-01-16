import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/client.dart';

void main() {
  group('Cliente Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto Cliente', () {
      final json = {
        'clientName': 'MARCOLINO DOS SANTOS',
        'responsible': 'MARCOS CASTRO',
        'limitBM': 1000.0,
        'balanceBM': -500.0,
        'limitC': 1000.0,
        'balanceC': 500.0,
        'clientId': 123,
        'birthday': '1990-05-15',
        'priceList': 2,
      };

      final client = Client.fromJson(json);

      expect(client.clientName, 'MARCOLINO DOS SANTOS');
      expect(client.responsible, 'MARCOS CASTRO');
      expect(client.clientId, 123);
      expect(client.priceList, 2);
      expect(client.birthday?.year, 1990);
      expect(client.birthday?.month, 5);
      expect(client.birthday?.day, 15);
    });

    test('Deve lidar com campos nulos no JSON sem crashar', () {
      final json = {
        'clientName': 'MARCOLINO DOS SANTOS',
        'limitiBM': 0.0,
        'balanceBM': 0.0,
        'limitC': 0.0,
        'balanceC': 0.0,
        'clientId': 999,
      };

      final client = Client.fromJson(json);

      expect(client.responsible, '');
      expect(client.priceList, 1);
      expect(client.birthday, isNull);
    });

    test('Deve tratar string de data vazia como null', () {
      final json = {
        'clientName': 'MARCOLINO DOS SANTOS',
        'clientId': 1,
        'limitBM': 0.0,
        'balanceBM': 0.0,
        'limitC': 0.0,
        'balanceC': 0.0,
        'birthday': '',
      };

      final client = Client.fromJson(json);
      expect(client.birthday, isNull);
    });

    test('Deve formatar valores monetários corretamente para PT-BR', () {
      final client = Client(
        clientId: 1,
        clientName: 'MARCOLINO DOS SANTOS',
        responsible: '',
        limitBM: -1250.50,
        balanceBM: 0,
        limitC: 0,
        balanceC: 0,
      );

      final cleanResult = client.limitBMF.replaceAll(
        RegExp(r'\s+'),
        '',
      );

      expect(cleanResult, '-1.250,50');
    });

    test('Deve converter o objeto Cliente de volta para JSON corretamente', () {
      final date = DateTime(1990, 5, 15);

      final client = Client(
        clientId: 123,
        clientName: 'MARCOLINO DOS SANTOS',
        responsible: 'MARCOS CASTRO',
        limitBM: 1000.0,
        balanceBM: -500.0,
        limitC: 1000.0,
        balanceC: 500.0,
        birthday: date,
        priceList: 2,
      );

      final json = client.toJson();

      expect(json['clientId'], 123);
      expect(json['clientName'], 'MARCOLINO DOS SANTOS');
      expect(json['limit'], 1000.0);
      expect(json['birthday'], date.toIso8601String());
    });
  });
}
