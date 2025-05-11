// lib/features/locais/local_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locais_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/estados_provider.dart';
import '../../providers/cidades_provider.dart';
import 'widgets/local_card.dart';
import 'widgets/local_carousel.dart';
import '../favoritos/favoritos_screen.dart';

class LocalListScreen extends ConsumerStatefulWidget {
  const LocalListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocalListScreen> createState() => _LocalListScreenState();
}

class _LocalListScreenState extends ConsumerState<LocalListScreen> {
  final _busca = TextEditingController();
  Timer? _debounce;
  int? _cidadeId;
  int? _estadoId;
  String? _selectedType;

  static const tipos = [
    {'value': 'museu', 'label': 'Museu'},
    {'value': 'teatro', 'label': 'Teatro'},
    {'value': 'biblioteca', 'label': 'Biblioteca'},
    {'value': 'centro', 'label': 'Centro Cultural'},
    {'value': 'zoologico', 'label': 'Zoológico'},
    {'value': 'parque', 'label': 'Parque de Diversões'},
    {'value': 'igreja', 'label': 'Igreja'},
    {'value': 'jardim', 'label': 'Jardim'},
    {'value': 'shopping', 'label': 'Shopping'},
  ];

  @override
  void dispose() {
    _busca.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // pré‐carrega locais e estados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locaisProvider.notifier).refresh();
      ref.read(estadosProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locaisAsync = ref.watch(locaisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locais culturais'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _busca,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _abrirFiltro,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritosScreen()),
              );
              ref.read(locaisProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: locaisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (todosLocais) {
          // aplica filtro de tipo sobre os locais já filtrados por estado/cidade
          final locaisFiltradosPorTipo = _selectedType == null
              ? todosLocais
              : todosLocais
              .where((l) => l.tipo == _selectedType)
              .toList();

          // decide a mensagem de "nenhum local"
          String mensagemNenhum;
          if (_cidadeId != null) {
            mensagemNenhum = 'Nenhum local encontrado na cidade selecionada.';
          } else if (_estadoId != null) {
            mensagemNenhum = 'Nenhum local encontrado no estado selecionado.';
          } else {
            mensagemNenhum = 'Nenhum local encontrado.';
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(locaisProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // ChoiceChips de tipo
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: tipos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final tipo = tipos[i];
                      final selected = tipo['value'] == _selectedType;
                      return ChoiceChip(
                        label: Text(tipo['label']!),
                        selected: selected,
                        onSelected: (sel) => setState(() {
                          _selectedType = sel ? tipo['value'] : null;
                        }),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Se choosen type → carousel, senão lista
                if (_selectedType != null) ...[
                  if (locaisFiltradosPorTipo.isEmpty)
                    _buildPlaceholder(mensagemNenhum)
                  else
                    LocalCarousel(locais: locaisFiltradosPorTipo),
                ] else ...[
                  if (todosLocais.isEmpty)
                    _buildPlaceholder(mensagemNenhum)
                  else
                    for (final local in todosLocais)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: LocalCard(local: local),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Widget de placeholder personalizado
  Widget _buildPlaceholder(String mensagem) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          mensagem,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _filtrar);
  }

  Future<void> _abrirFiltro() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        int? selEstado = _estadoId;
        int? selCidade = _cidadeId;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              final estadosAsync = ref.watch(estadosProvider);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Filtrar por',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),

                    // estados
                    estadosAsync.when(
                      loading: () => const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Erro: $e'),
                      data: (listaEstados) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            value: selEstado,
                            decoration:
                            const InputDecoration(labelText: 'Estado'),
                            items: listaEstados
                                .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.sigla} – ${e.nome}'),
                            ))
                                .toList(),
                            onChanged: (v) => setModalState(() {
                              selEstado = v;
                              selCidade = null;
                            }),
                          ),
                          const SizedBox(height: 16),

                          // cidades
                          if (selEstado != null)
                            Consumer(builder: (_, ref2, __) {
                              final cidadesAsync =
                              ref2.watch(cidadesPorEstadoProvider(selEstado!));
                              return cidadesAsync.when(
                                loading: () =>
                                const LinearProgressIndicator(),
                                error: (e, _) => Text('Erro: $e'),
                                data: (listaCidades) =>
                                    DropdownButtonFormField<int>(
                                      value: selCidade,
                                      decoration: const InputDecoration(
                                          labelText: 'Cidade'),
                                      items: listaCidades
                                          .map((c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.nome),
                                      ))
                                          .toList(),
                                      onChanged: (v) => setModalState(() {
                                        selCidade = v;
                                      }),
                                    ),
                              );
                            }),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _estadoId = selEstado;
                                      _cidadeId = selCidade;
                                    });
                                    _filtrar();
                                  },
                                  child: const Text('Aplicar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Limpar filtros'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _estadoId = null;
                                      _cidadeId = null;
                                      _selectedType = null;
                                    });
                                    _filtrar();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _filtrar() {
    ref.read(locaisProvider.notifier).fetchLocais(
      busca: _busca.text.trim(),
      cidade: _cidadeId,
      estado: _estadoId,
    );
  }
}
