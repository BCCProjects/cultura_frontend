import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favoritos_provider.dart';
import '../locais/widgets/local_card.dart';

class FavoritosScreen extends ConsumerWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus favoritos')),
      body: favs.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Nenhum favorito'))
            : ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => LocalCard(local: list[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
