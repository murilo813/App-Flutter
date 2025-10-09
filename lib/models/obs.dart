import 'package:intl/intl.dart';

class Obs {
  final int idCliente;
  final DateTime data;
  final bool visitado;
  final String? observacao;

  Obs({
    required this.idCliente,
    required this.data,
    required this.visitado,
    this.observacao,
  });

  factory Obs.fromJson(Map<String, dynamic> json) {
    return Obs(
      idCliente: json['id_cliente'],
      data: DateTime.parse(json['data']),
      visitado: json['visitado'] ?? false,
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'data': data,
      'visitado': visitado,
      'observacao': observacao,
    };
  }
}
