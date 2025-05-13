import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/local.dart';
import '../../../providers/locais_provider.dart';
import '../../../providers/auth_provider.dart';
import '../local_detail_screen.dart';

class LocalCarousel extends ConsumerWidget {
  final List<Local> locais;
  const LocalCarousel({Key? key, required this.locais}) : super(key: key);

  // Altura do slide. Mantivemos 260 px, igual ao design original
  static const double _slideHeight = 261;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locais.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Nenhum local cadastrado para este tipo.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: CarouselSlider.builder(
        itemCount: locais.length,
        options: CarouselOptions(
          height: _slideHeight,
          enlargeCenterPage: true,                   // mantém o efeito
          viewportFraction: 0.75,
          enableInfiniteScroll: false,
        ),
        itemBuilder: (ctx, index, _) {
          final local = locais[index];
          final logged = ref.watch(authProvider).token != null;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocalDetailScreen(local: local),
              ),
            ),
            child: _CarouselCard(
              local: local,
              logged: logged,
              onToggleFavorito: () async {
                try {
                  await ref
                      .read(locaisProvider.notifier)
                      .toggleFavorito(local);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao (des)favoritar: $e')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

/// Card enxuto para o carrossel.
/// Usa `Flexible` em vez de `Expanded` e fontes menores, evitando overflow
/// quando o slide é encolhido pelo efeito `enlargeCenterPage`.
class _CarouselCard extends StatelessWidget {
  final Local local;
  final bool logged;
  final VoidCallback onToggleFavorito;

  const _CarouselCard({
    Key? key,
    required this.local,
    required this.logged,
    required this.onToggleFavorito,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tipoText =
        '${local.tipo[0].toUpperCase()}${local.tipo.substring(1)}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagem (altura fixa p/ manter proporção)
          SizedBox(
            height: 130,
            width: double.infinity,
            child: local.imagens.isNotEmpty
                ? Image.network(
              local.imagens.first,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),

          // Texto + botão favorito (pode encolher)
          Flexible(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(local.nome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(tipoText, style: const TextStyle(fontSize: 13)),
                        if (local.cidade != null && local.estado != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('${local.cidade} – ${local.estado}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),

                  // Favorito
                  IconButton(
                    icon: Icon(
                      local.isFavorito
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: local.isFavorito ? Colors.red : null,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    onPressed: logged ? onToggleFavorito : null,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[300],
    child: const Icon(Icons.photo, size: 40),
  );
}
