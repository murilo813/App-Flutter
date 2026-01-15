import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/observation.dart';

void main() {
  group('Obs Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto Obs', () {
      final json = {
        'id_cliente': 2317,
        'nome_cliente': 'JOEIMIR MARIAN',
        'responsavel': 'ALEXANDRE MARIAN',
        'data': '1990-05-15',
        'visitado': true,
        'observacao': 'Nota de teste.',
      };

      final obs = Observation.fromJson(json);

      expect(obs.idCliente, 2317);
      expect(obs.nomeCliente, 'JOEIMIR MARIAN');
      expect(obs.responsavel, 'ALEXANDRE MARIAN');
      expect(obs.data.year, 1990);
      expect(obs.data.month, 5);
      expect(obs.data.day, 15);
      expect(obs.visitado, isTrue);
      expect(obs.observacao, 'Nota de teste.');
    });

    test('Deve lidar com observacao nula sem crashar', () {
      final json = {
        'id_cliente': 2317,
        'nome_cliente': 'JOEIMIR MARIAN',
        'responsavel': 'ALEXANDRE MARIAN',
        'data': '1990-05-15',
        'visitado': true,
      };

      final obs = Observation.fromJson(json);

      expect(obs.observacao, isNull);
    });

    test('Deve converter o objeto Obs de volta para JSON corretamente', () {
      final dataTeste = DateTime(2026, 1, 13);

      final obs = Observation(
        idCliente: 2317,
        nomeCliente: 'JOEIMIR MARIAN',
        responsavel: 'ALEXANDRE MARIAN',
        data: dataTeste,
        visitado: true,
        observacao: 'Cliente atendeu na porta.',
      );

      final json = obs.toJson();

      expect(json['id_cliente'], 2317);
      expect(json['nome_cliente'], 'JOEIMIR MARIAN');
      expect(json['responsavel'], 'ALEXANDRE MARIAN');
      expect(json['data'], dataTeste.toIso8601String());
      expect(json['visitado'], isTrue);
      expect(json['observacao'], 'Cliente atendeu na porta.');
    });
  });
}
