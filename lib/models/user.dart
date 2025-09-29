import 'package:intl/intl.dart';

class User {
  final int id;
  final int id_empresa;
  final String usuario;
  final int id_vendedor;
  final int registrar_novo_disp;
  final String tipo_usuario;
  final String nomeclatura;

  User({
    required this.id,
    required this.id_empresa,
    required this.usuario,
    required this.id_vendedor,
    required this.registrar_novo_disp,
    required this.tipo_usuario,
    required this.nomeclatura,
  });

  // como eu tenho certeza do tipo que os valores vem da api, eu nao trato outros tipos de dados ou faço conversoes
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      id_empresa: json['id_empresa'],
      usuario: json['nome'],
      id_vendedor: json['id_vendedor'],
      registrar_novo_disp: json ['registrar_novo_disp'],
      tipo_usuario: json ['tipo_usuario'],
      nomeclatura: json ['nomeclatura'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_empresa': id_empresa,
      'nome': usuario,
      'id_vendedor': id_vendedor,
      'registrar_novo_disp': registrar_novo_disp,
      'tipo_usuario': tipo_usuario,
      'nomeclatura': nomeclatura,
    };
  }
}