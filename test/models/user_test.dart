import 'package:flutter_test/flutter_test.dart';
import 'package:alembro/models/user.dart';

void main() {
  group('User Model - Unit Tests', () {
    test('Deve converter JSON corretamente para objeto User', () {
      final json = {
        'userId': 1,
        'companyId': 10,
        'userName': 'joao',
        'sellerId': 123,
        'deviceCredit': 0,
        'userType': 'USER',
        'nomenclature': 'João da Silva',
        'active': 'S',
      };

      final user = User.fromJson(json);

      expect(user.userId, 1);
      expect(user.companyId, 10);
      expect(user.userName, 'joao'); 
      expect(user.sellerId, 123);
      expect(user.deviceCredit, 0);
      expect(user.userType, 'USER');
      expect(user.nomenclature, 'João da Silva');
      expect(user.active, 'S');
    });

    test('Deve lidar com o campo active sendo nulo', () {
      final json = {
        'userId': 2,
        'companyId': 10,
        'userName': 'admin',
        'sellerId': 0,
        'deviceCredit': 1,
        'userType': 'ADMIN',
        'nomenclature': 'Administrador',
        'active': null,
      };

      final user = User.fromJson(json);

      expect(user.active, isNull);
    });

    test('Deve converter o objeto User de volta para JSON corretamente', () {
      const user = User(
        userId: 1,
        companyId: 10,
        userName: 'marcos_vendas',
        sellerId: 5,
        deviceCredit: 0,
        userType: 'USER',
        nomenclature: 'Marcos Castro',
        active: 'S',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['companyId'], 10);
      expect(
        json['nome'],
        'marcos_vendas',
        reason:
            'A variável "userName" deve ser exportada como "nome" para o Backend',
      );
      expect(json['sellerId'], 5);
      expect(json['deviceCredit'], 0);
      expect(json['userType'], 'USER');
      expect(json['active'], 'S');
    });
  });
}
