import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/local.dart';
import '../core/services/api_service.dart';
import '../core/config.dart';
import 'auth_provider.dart';

String? _q; int? _cidade; int? _estado;


final locaisProvider =
StateNotifierProvider<LocaisNotifier, AsyncValue<List<Local>>>(
        (ref) => LocaisNotifier(ref));

class LocaisNotifier extends StateNotifier<AsyncValue<List<Local>>> {
  final Ref ref;
  LocaisNotifier(this.ref) : super(const AsyncLoading()) {
    fetchLocais();
  }

  Future<void> fetchLocais({
    String? busca,
    int? cidade,
    int? estado,
  }) async {
    _q      = busca;
    _cidade = cidade;
    _estado = estado;
    try {
      final query = <String, dynamic>{
        if (_q  != null && _q!.isNotEmpty) 'search': _q,
        if (_cidade != null)              'cidade': _cidade,
        if (_estado  != null)             'estado':  _estado,
      };
      final res = await ApiService.instance.client
          .get(kApiLocais, queryParameters: query);

      final locais = (res.data as List)
          .map((e) => Local.fromJson(e))
          .toList(growable: false);

      await _marcarFavoritos(locais);
      state = AsyncData(locais);

    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  Future<void> refresh() =>
      fetchLocais(busca: _q, cidade: _cidade, estado: _estado);

  Future<void> _marcarFavoritos(List<Local> locais) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    final favRes = await ApiService.instance.client.get(kApiFavoritos);
    final ids = (favRes.data as List).map((f) => f['local']).toSet();
    for (final l in locais) {
      l.isFavorito = ids.contains(l.id);
    }
  }

  Future<void> toggleFavorito(Local local) async {
    local.isFavorito = !local.isFavorito;
    state = AsyncData([...state.value!]);

    if (local.isFavorito) {
      await ApiService.instance.client
          .post(kApiFavoritos, data: {"local": local.id, "visitado": false});
    } else {
      // encontra o favorito correspondente
      final resp = await ApiService.instance.client.get(kApiFavoritos);
      final fav = (resp.data as List)
          .firstWhere((f) => f['local'] == local.id, orElse: () => null);
      if (fav != null) {
        await ApiService.instance.client
            .delete('$kApiFavoritos${fav['id']}/');
      }
    }
  }

}
