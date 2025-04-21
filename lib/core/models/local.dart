class Local {
  final int id;
  final String nome;
  final String tipo;
  final String descricao;
  final double latitude;
  final double longitude;
  final List<String> imagens;

  bool isFavorito;

  Local({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.imagens,
    this.isFavorito = false,
  });

  factory Local.fromJson(Map<String, dynamic> j) => Local(
    id: j['id'],
    nome: j['nome'],
    tipo: j['tipo'],
    descricao: j['descricao'] ?? '',
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    imagens: (j['imagens'] as List<dynamic>?)
        ?.map((i) => i['arquivo'] as String)
        .toList() ??
        [],
  );
}
