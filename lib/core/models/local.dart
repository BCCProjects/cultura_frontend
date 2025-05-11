class Local {
  final int id;
  final String nome;
  final String tipo;
  final String descricao;
  final double latitude;
  final double longitude;
  final List<String> imagens;

  final String? cidade;
  final String? estado;

  final String? endereco;
  final String? bairro;
  final String? horarioFuncionamento;
  final String? linkExterno;

  bool isFavorito;

  Local({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.imagens,
    this.cidade,
    this.estado,
    this.endereco,
    this.bairro,
    this.horarioFuncionamento,
    this.linkExterno,
    this.isFavorito = false,
  });

  factory Local.fromJson(Map<String, dynamic> j) {
    final cidadeNome = j['cidade_nome'] as String?;
    final estadoSigla = j['estado_sigla'] as String?;

    final imagensJson = j['imagens'] as List<dynamic>?;
    final imagensList = imagensJson != null
        ? imagensJson
        .map((i) => (i as Map<String, dynamic>)['arquivo'] as String)
        .toList()
        : <String>[];

    return Local(
      id: j['id'] as int,
      nome: j['nome'] as String,
      tipo: j['tipo'] as String,
      descricao: (j['descricao'] as String?) ?? '',
      latitude: (j['latitude'] as num).toDouble(),
      longitude: (j['longitude'] as num).toDouble(),
      imagens: imagensList,
      cidade: cidadeNome,
      estado: estadoSigla,
      endereco: j['endereco'] as String?,
      bairro: j['bairro'] as String?,
      horarioFuncionamento: j['horario_funcionamento'] as String?,
      linkExterno: j['link_externo'] as String?,
    );
  }
}
