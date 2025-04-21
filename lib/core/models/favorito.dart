class Favorito {
  final int id;
  final int localId;

  Favorito({required this.id, required this.localId});

  factory Favorito.fromJson(Map<String, dynamic> j) =>
      Favorito(id: j['id'], localId: j['local']);
}
