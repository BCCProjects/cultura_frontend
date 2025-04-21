import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locais_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/local_card.dart';
import 'widgets/local_map.dart';
import '../favoritos/favoritos_screen.dart';

class LocalListScreen extends ConsumerWidget {
  const LocalListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locais = ref.watch(locaisProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locais culturais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritosScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: locais.when(
        data: (l) => RefreshIndicator(
          onRefresh: () => ref.read(locaisProvider.notifier).fetchLocais(),
          child: ListView.builder(
            itemCount: l.length,
            itemBuilder: (_, i) => LocalCard(local: l[i]),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.map),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LocalMap()),
        ),
      ),
    );
  }
}
