class Cliente {
    final String nomeCliente;
    final double limite;

    Cliente({
        required this.nomeCliente,
        required this.limite,
    });

    factory Cliente.fromJson(Map<String, dynamic> json) {
        return Cliente(
            nomeCliente: json['nome_cliente'] as String,
            limite: (json['limite'] is int)
                ? (json['limite'] as int).toDouble()
                : (json['limite'] as double),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'nome_cliente': nomeCliente,
            'limite': limite,
        };
    }
}