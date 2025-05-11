// lib/features/locais/widgets/local_card.dart
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

    final tipoText =
        '${local.tipo[0].toUpperCase()}${local.tipo.substring(1)}';
    final subtitleText = [
      tipoText,
      if (local.cidade != null && local.estado != null)
        '${local.cidade} – ${local.estado}'
    ].join('\n');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LocalDetailScreen(local: local)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // imagem ou ícone
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: local.imagens.isNotEmpty
                    ? Image.network(
                  local.imagens.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.photo, size: 30),
                ),
              ),
              const SizedBox(width: 12),

              // texto e botão
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(local.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // botão favorito
              IconButton(
                icon: Icon(
                  local.isFavorito
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: local.isFavorito ? Colors.red : null,
                ),
                constraints: const BoxConstraints(), // sem altura/largura mínima
                padding: EdgeInsets.zero, // sem padding interno
                splashRadius: 20,
                onPressed: logged
                    ? () async {
                  try {
                    await ref
                        .read(locaisProvider.notifier)
                        .toggleFavorito(local);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Erro ao (des)favoritar: $e')),
                    );
                  }
                }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
