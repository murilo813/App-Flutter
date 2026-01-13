import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/user.dart';

void main() {
  group('User Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto User', () {
      final json = {
        'id': 1,
        'id_empresa': 10,
        'nome': 'joao',
        'id_vendedor': 123,
        'registrar_novo_disp': 0,
        'tipo_usuario': 'USER',
        'nomeclatura': 'Jõao da Silva',
        'ativo': 'S',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.usuario, 'joao'); // vem do banco como 'nome' mas vira 'usuario'
      expect(user.id_vendedor, 123);
      expect(user.tipo_usuario, 'USER');
      expect(user.ativo, 'S');
    });

    test('Deve lidar com o campo ativo sendo nulo', () {
      final json = {
        'id': 2,
        'id_empresa': 10,
        'nome': 'admin',
        'id_vendedor': 0,
        'registrar_novo_disp': 1,
        'tipo_usuario': 'ADMIN',
        'nomeclatura': 'Administrador',
        'ativo': null,
      };

      final user = User.fromJson(json);

      expect(user.ativo, isNull, reason: 'O campo ativo deve aceitar nulo');
    });

    test('Deve converter o objeto User de volta para JSON corretamente', () {
      final user = User(
        id: 1,
        id_empresa: 10,
        usuario: 'marcos_vendas',
        id_vendedor: 5,
        registrar_novo_disp: 0,
        tipo_usuario: 'USER',
        nomeclatura: 'Marcos Castro',
        ativo: 'S',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['nome'], 'marcos_vendas', reason: 'A variável "usuario" deve ser exportada como "nome" para o Backend');
      expect(json['id_vendedor'], 5);
      expect(json['tipo_usuario'], 'USER');
      expect(json['ativo'], 'S');
    });
  });
}
