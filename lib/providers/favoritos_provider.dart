import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/local.dart';
import '../core/services/api_service.dart';
import '../core/config.dart';

final favoritosProvider =
StateNotifierProvider<FavoritosNotifier, AsyncValue<List<Local>>>(
      (ref) => FavoritosNotifier(),
);

class FavoritosNotifier extends StateNotifier<AsyncValue<List<Local>>> {
  FavoritosNotifier() : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final favRes = await ApiService.instance.client.get(kApiFavoritos);
      final favList = favRes.data as List;

      final locaisRes = await ApiService.instance.client.get(kApiLocais);
      final allLocais = (locaisRes.data as List)
          .map((j) => Local.fromJson(j))
          .toList(growable: false);

      final favoritos = allLocais
          .where((l) => favList.any((f) => f['local'] == l.id))
          .toList(growable: false);

      // marca isFavorito em cada Local
      for (final l in favoritos) {
        l.isFavorito = true;
      }

      state = AsyncData(favoritos);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Faz o POST ou DELETE mínimo e atualiza só a lista em memória.
  Future<void> toggleFavorito(Local local) async {
    final current = state.value ?? [];
    final already = current.any((l) => l.id == local.id);

    // otimismo: atualiza antes da chamada
    final updated = already
        ? current.where((l) => l.id != local.id).toList()
        : [...current, local..isFavorito = true];
    state = AsyncData(updated);

    try {
      if (already) {
        // busca o ID do favorito no backend
        final resp = await ApiService.instance.client.get(kApiFavoritos);
        final fav = (resp.data as List)
            .firstWhere((f) => f['local'] == local.id, orElse: () => null);
        if (fav != null) {
          await ApiService.instance
              .client
              .delete('$kApiFavoritos${fav['id']}/');
        }
        local.isFavorito = false;
      } else {
        await ApiService.instance.client
            .post(kApiFavoritos, data: {"local": local.id, "visitado": false});
        local.isFavorito = true;
      }
    } catch (e) {
      // se falhar, reverte o estado e opcionalmente mostra um SnackBar
      state = AsyncData(await _reloadCurrent());
      rethrow;
    }
  }

  /// Em caso de erro no toggle, recarrega apenas o array atual do provider
  Future<List<Local>> _reloadCurrent() async {
    return state.value!;
  }
}
