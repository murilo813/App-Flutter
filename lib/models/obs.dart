class Obs {
  final int idCliente;
  final String nome_cliente;
  final String responsavel;
  final DateTime data;
  final bool visitado;
  final String? observacao;

  Obs({
    required this.idCliente,
    required this.nome_cliente,
    required this.responsavel,
    required this.data,
    required this.visitado,
    this.observacao,
  });

  factory Obs.fromJson(Map<String, dynamic> json) {
    return Obs(
      idCliente: json['id_cliente'],
      nome_cliente: json['nome_cliente'],
      responsavel: json['responsavel'],
      data: DateTime.parse(json['data']),
      visitado: json['visitado'] ?? false,
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'nome_cliente': nome_cliente,
      'responsavel': responsavel,
      'data': data,
      'visitado': visitado,
      'observacao': observacao,
    };
  }
}
