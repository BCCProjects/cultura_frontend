class Cidade {
  final int id;
  final String nome;
  final int estadoId;

  Cidade({required this.id, required this.nome, required this.estadoId});

  factory Cidade.fromJson(Map j) =>
      Cidade(id: j['id'], nome: j['nome'], estadoId: j['estado']['id']);
}
