import 'package:dio/dio.dart';
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

      for (final l in favoritos) {
        l.isFavorito = true;
        final fav = favList.firstWhere((f) => f['local'] == l.id);
        l.favoritoId = fav['id'] as int;
      }

      state = AsyncData(favoritos);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleFavorito(Local local) async {
    final current = state.value ?? [];
    final already = current.any((l) => l.id == local.id);

    final updated = already
        ? current.where((l) => l.id != local.id).toList()
        : [...current, local..isFavorito = true];
    state = AsyncData(updated);

    try {
      if (already) {
        if (local.favoritoId != null) {
          await ApiService.instance.client
              .delete('$kApiFavoritos${local.favoritoId}/');
        } else {
          final resp = await ApiService.instance.client.get(kApiFavoritos);
          final fav = (resp.data as List)
              .firstWhere((f) => f['local'] == local.id, orElse: () => null);
          if (fav != null) {
            await ApiService.instance.client
                .delete('$kApiFavoritos${fav['id']}/');
          }
        }
        local.isFavorito = false;
        local.favoritoId = null;
      } else {
        final resp = await ApiService.instance.client.get(kApiFavoritos);
        final dup = (resp.data as List)
            .firstWhere((f) => f['local'] == local.id, orElse: () => null);

        if (dup != null) {
          local.isFavorito = true;
          local.favoritoId = dup['id'] as int;
        } else {
          final post = await ApiService.instance.client.post(
            kApiFavoritos,
            data: {"local": local.id, "visitado": false},
          );
          local.isFavorito = true;
          local.favoritoId = post.data['id'] as int;
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data.toString() ?? '';
      final dupKey =
          e.response?.statusCode == 500 && msg.contains('duplicate key');

      if (dupKey) {
        await fetch();
        return;
      }

      state = AsyncData(await _reloadCurrent());
      rethrow;
    } catch (_) {
      state = AsyncData(await _reloadCurrent());
      rethrow;
    }
  }

  Future<List<Local>> _reloadCurrent() async => state.value ?? [];
}
