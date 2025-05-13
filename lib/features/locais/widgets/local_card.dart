// lib/features/locais/widgets/local_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/local.dart';
import '../../../providers/locais_provider.dart';
import '../../../providers/auth_provider.dart';
import '../local_detail_screen.dart';

class LocalCard extends ConsumerWidget {
  final Local local;
  final bool large;
  const LocalCard({Key? key, required this.local, this.large = false})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logged = ref.watch(authProvider).token != null;

    final tipoText =
        '${local.tipo[0].toUpperCase()}${local.tipo.substring(1)}';
    final subtitleText = [
      tipoText,
      if (local.cidade != null && local.estado != null)
        '${local.cidade} – ${local.estado}',
    ].join('\n');

    // ───── layout PEQUENO (inalterado) ─────
    if (!large) {
      return _smallCard(context, ref, logged, subtitleText);
    }

    // ───── layout GRANDE (corrigido) ─────
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LocalDetailScreen(local: local)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,                 // ← shrink-wrap
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem com proporção 16:9
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _Thumb(local: local),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(local.nome,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(tipoText,
                            style: const TextStyle(fontSize: 14)),
                        if (local.cidade != null && local.estado != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('${local.cidade} – ${local.estado}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                  _FavButton(local: local, logged: logged),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- versão pequena extraída p/ clareza ----------
  Widget _smallCard(BuildContext ctx, WidgetRef ref, bool logged,
      String subtitleText) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => LocalDetailScreen(local: local)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(local: local, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(local.nome,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitleText,
                        style:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              _FavButton(local: local, logged: logged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail reutilizável
class _Thumb extends StatelessWidget {
  final Local local;
  final double? size;
  const _Thumb({Key? key, required this.local, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = size ?? double.infinity;
    final h = size ?? double.infinity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: local.imagens.isNotEmpty
          ? Image.network(local.imagens.first,
          width: w,
          height: h,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _ph(w, h))
          : _ph(w, h),
    );
  }

  Widget _ph(double w, double h) => Container(
    width: w,
    height: h,
    color: Colors.grey[300],
    child: const Icon(Icons.photo, size: 40),
  );
}

/// Botão de favorito
class _FavButton extends ConsumerWidget {
  final Local local;
  final bool logged;
  const _FavButton({Key? key, required this.local, required this.logged})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        local.isFavorito ? Icons.favorite : Icons.favorite_border,
        color: local.isFavorito ? Colors.red : null,
      ),
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      splashRadius: 20,
      onPressed: logged
          ? () async {
        try {
          await ref.read(locaisProvider.notifier).toggleFavorito(local);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao (des)favoritar: $e')),
          );
        }
      }
          : null,
    );
  }
}
