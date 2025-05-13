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
import 'package:lottie/lottie.dart';

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
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locaisProvider.notifier).refresh();
      ref.read(estadosProvider);
    });
  }

  @override
  void dispose() {
    _busca.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locaisAsync = ref.watch(locaisProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Image.asset('assets/images/Cultivi.png', width: 60, height: 60),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cultivi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Explore espaços culturais da sua cidade', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
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
                    tooltip: 'Sair',
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),

            // Busca
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _busca,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xff016343)),
                  suffixIcon: IconButton(icon: const Icon(Icons.filter_list), onPressed: _abrirFiltro),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Chips de tipo
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
                    onSelected: (sel) {
                      setState(() => _selectedType = sel ? tipo['value'] : null);
                      _filtrar();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Lista de locais
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : locaisAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (todosLocais) {
                  // Aplica filtro de tipo
                  final filtrados = _selectedType == null
                      ? todosLocais
                      : todosLocais.where((l) => l.tipo == _selectedType).toList();

                  if (filtrados.isEmpty) {
                    return SizedBox.expand(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset('assets/lottie/cultural_empty.json', width: 200, height: 200, fit: BoxFit.contain, repeat: false),
                          const SizedBox(height: 16),
                          const Text('Nenhum local encontrado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }

                  // Se houver filtro de tipo ativo, todos grandes
                  if (_selectedType != null) {
                    return RefreshIndicator(
                      onRefresh: () => ref.read(locaisProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtrados.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: LocalCard(local: filtrados[i], large: true),
                        ),
                      ),
                    );
                  }

                  // Sem filtro de tipo: mantém carousel + lista padrão
                  return RefreshIndicator(
                    onRefresh: () => ref.read(locaisProvider.notifier).refresh(),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        if (filtrados.length >= 3)
                          LocalCarousel(locais: filtrados.take(3).toList()),
                        const SizedBox(height: 8),
                        for (final local in filtrados.skip(3))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: LocalCard(local: local),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 24, right: 24, top: 24),
          child: StatefulBuilder(
            builder: (ctx2, setModal) {
              final estadosAsync = ref.watch(estadosProvider);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Filtrar por', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    estadosAsync.when(
                      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => Text('Erro: $e'),
                      data: (listaEstados) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            value: selEstado,
                            decoration: const InputDecoration(labelText: 'Estado'),
                            items: listaEstados.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.sigla} – ${e.nome}'))).toList(),
                            onChanged: (v) => setModal(() { selEstado = v; selCidade = null; }),
                          ),
                          const SizedBox(height: 16),
                          if (selEstado != null)
                            Consumer(builder: (_, ref2, __) {
                              final cidadesAsync = ref2.watch(cidadesPorEstadoProvider(selEstado!));
                              return cidadesAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text('Erro: $e'),
                                data: (listaCidades) => DropdownButtonFormField<int>(
                                  value: selCidade,
                                  decoration: const InputDecoration(labelText: 'Cidade'),
                                  items: listaCidades.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                                  onChanged: (v) => setModal(() => selCidade = v),
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
                                    setState(() { _estadoId = selEstado; _cidadeId = selCidade; });
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
                                    setState(() { _estadoId = null; _cidadeId = null; _selectedType = null; });
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

  Future<void> _filtrar() async {
    setState(() => _isLoading = true);
    await ref.read(locaisProvider.notifier).fetchLocais(busca: _busca.text.trim(), cidade: _cidadeId, estado: _estadoId);
    setState(() => _isLoading = false);
  }
}
