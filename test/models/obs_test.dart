import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/observation.dart';

void main() {
  group('Obs Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto Obs', () {
      final json = {
        'clientId': 2317,
        'clientName': 'JOEIMIR MARIAN',
        'responsible': 'ALEXANDRE MARIAN',
        'date': '1990-05-15',
        'visited': true,
        'observation': 'Nota de teste.',
      };

      final obs = Observation.fromJson(json);

      expect(obs.clientId, 2317);
      expect(obs.clientName, 'JOEIMIR MARIAN');
      expect(obs.responsible, 'ALEXANDRE MARIAN');
      expect(obs.date.year, 1990);
      expect(obs.date.month, 5);
      expect(obs.date.day, 15);
      expect(obs.visited, isTrue);
      expect(obs.observation, 'Nota de teste.');
    });

    test('Deve lidar com observation nula sem crashar', () {
      final json = {
        'clientId': 2317,
        'clientName': 'JOEIMIR MARIAN',
        'responsible': 'ALEXANDRE MARIAN',
        'date': '1990-05-15',
        'visited': true,
      };

      final obs = Observation.fromJson(json);

      expect(obs.observation, isNull);
    });

    test('Deve converter o objeto Obs de volta para JSON corretamente', () {
      final testDate = DateTime(2026, 1, 13);

      final obs = Observation(
        clientId: 2317,
        clientName: 'JOEIMIR MARIAN',
        responsible: 'ALEXANDRE MARIAN',
        date: testDate,
        visited: true,
        observation: 'Cliente atendeu na porta.',
      );

      final json = obs.toJson();

      expect(json['clientId'], 2317);
      expect(json['clientName'], 'JOEIMIR MARIAN');
      expect(json['responsible'], 'ALEXANDRE MARIAN');
      expect(json['date'], testDate.toIso8601String());
      expect(json['visited'], isTrue);
      expect(json['observation'], 'Cliente atendeu na porta.');
    });
  });
}
