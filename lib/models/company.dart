enum Company {
  belaVista(1, "Bela Vista"),
  imbuia(2, "Imbuia"),
  vilaNova(3, "Vila Nova"),
  aurora(4, "Aurora"),
  desconhecida(0, "Desconhecida");

  final int id;
  final String name;

  const Company(this.id, this.name);

  static Company fromId(int? id) {
    return Company.values.firstWhere(
      (e) => e.id == id,
      orElse: () => Company.desconhecida,
    );
  }
}
