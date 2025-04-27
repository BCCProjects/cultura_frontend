class Estado {
  final int id;
  final String nome;
  final String sigla;

  Estado({required this.id, required this.nome, required this.sigla});

  factory Estado.fromJson(Map j) =>
      Estado(id: j['id'], nome: j['nome'], sigla: j['sigla']);
}
