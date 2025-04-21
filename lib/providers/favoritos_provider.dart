import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/local.dart';
import '../core/services/api_service.dart';
import '../core/config.dart';

final favoritosProvider =
StateNotifierProvider<FavoritosNotifier, AsyncValue<List<Local>>>(
        (ref) => FavoritosNotifier());

class FavoritosNotifier extends StateNotifier<AsyncValue<List<Local>>> {
  FavoritosNotifier() : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final favRes = await ApiService.instance.client.get(kApiFavoritos);
      final favList = favRes.data as List;

      // Para este MVP precisamos também dos dados completos do local.
      final locaisRes = await ApiService.instance.client.get(kApiLocais);
      final locais = (locaisRes.data as List)
          .map((j) => Local.fromJson(j))
          .where((l) => favList.any((f) => f['local'] == l.id))
          .toList(growable: false);

      state = AsyncData(locais);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
