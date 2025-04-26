import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/local.dart';
import '../../../providers/locais_provider.dart';
import '../../../providers/auth_provider.dart';
import '../local_detail_screen.dart';

class LocalCard extends ConsumerWidget {
  final Local local;
  const LocalCard({super.key, required this.local});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logged = ref.watch(authProvider).token != null;

    return Card(
      child: ListTile(
        leading: local.imagens.isNotEmpty
            ? Image.network(local.imagens.first,
            width: 60, height: 60, fit: BoxFit.cover)
            : const Icon(Icons.photo, size: 40),
        title: Text(local.nome),
        subtitle: Text(local.tipo),
        trailing: IconButton(
          icon: Icon(
            local.isFavorito ? Icons.favorite : Icons.favorite_border,
            color: local.isFavorito ? Colors.red : null,
          ),
          onPressed: logged
              ? () => ref.read(locaisProvider.notifier).toggleFavorito(local)
              : null,
        ),
        // AQUI É O PULO DO GATO
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocalDetailScreen(local: local),
            ),
          );
        },
      ),
    );
  }
}
