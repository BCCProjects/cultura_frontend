import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locais_provider.dart';
import '../locais/widgets/local_card.dart';

class FavoritosScreen extends ConsumerWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locaisAsync = ref.watch(locaisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus favoritos')),
      body: locaisAsync.when(
        data: (list) {
          // só pega os que já estão marcados como favoritos
          final favs = list.where((l) => l.isFavorito).toList();
          if (favs.isEmpty) {
            return const Center(child: Text('Nenhum favorito'));
          }
          return ListView.builder(
            itemCount: favs.length,
            itemBuilder: (_, i) => LocalCard(local: favs[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
