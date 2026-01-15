class User {
  final int id;
  final int idEmpresa;
  final String usuario;
  final int idVendedor;
  final int registrarNovoDisp;
  final String tipoUsuario;
  final String nomeclatura;
  final String? ativo;

  const User({
    required this.id,
    required this.idEmpresa,
    required this.usuario,
    required this.idVendedor,
    required this.registrarNovoDisp,
    required this.tipoUsuario,
    required this.nomeclatura,
    this.ativo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      idEmpresa: json['id_empresa'] as int,
      usuario: json['nome'] as String,
      idVendedor: json['id_vendedor'] as int,
      registrarNovoDisp: json['registrar_novo_disp'] as int,
      tipoUsuario: json['tipo_usuario'] as String,
      nomeclatura: json['nomeclatura'] as String,
      ativo: json['ativo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_empresa': idEmpresa,
      'nome': usuario,
      'id_vendedor': idVendedor,
      'registrar_novo_disp': registrarNovoDisp,
      'tipo_usuario': tipoUsuario,
      'nomeclatura': nomeclatura,
      'ativo': ativo,
    };
  }
}
