class Obs {
  final int idCliente;
  final String nomeCliente;
  final String responsavel;
  final DateTime data;
  final bool visitado;
  final String? observacao;

  Obs({
    required this.idCliente,
    required this.nomeCliente,
    required this.responsavel,
    required this.data,
    required this.visitado,
    this.observacao,
  });

  factory Obs.fromJson(Map<String, dynamic> json) {
    return Obs(
      idCliente: json['id_cliente'],
      nomeCliente: json['nome_cliente'],
      responsavel: json['responsavel'],
      data: DateTime.parse(json['data']),
      visitado:
          json['visitado'] is bool ? json['visitado'] : json['visitado'] == 1,
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'nome_cliente': nomeCliente,
      'responsavel': responsavel,
      'data': data.toIso8601String(),
      'visitado': visitado,
      'observacao': observacao,
    };
  }
}
