import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locais_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/estados_provider.dart';
import '../../providers/cidades_provider.dart';
import 'widgets/local_card.dart';
import 'widgets/local_map.dart';
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

  @override
  void dispose() {
    _busca.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locais = ref.watch(locaisProvider);
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
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
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
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: locais.when(
        data: (l) => RefreshIndicator(
          onRefresh: () => ref.read(locaisProvider.notifier).refresh(),
          child: l.isEmpty
              ? const Center(child: Text('Nenhum local encontrado'))
              : ListView.builder(
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _filtrar);
  }

  Future<void> _abrirFiltro() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final estados = ref.watch(estadosProvider);
        return estados.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
          error: (e, _) => Padding(
              padding: const EdgeInsets.all(32), child: Text('Erro: $e')),
          data: (listaEstados) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Filtrar por', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  value: _estadoId,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: listaEstados
                      .map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text('${e.sigla} – ${e.nome}'),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _estadoId = v;
                      _cidadeId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_estadoId != null)
                  _DropdownCidades(
                    estadoId: _estadoId!,
                    valor: _cidadeId,
                    onChanged: (v) => setState(() => _cidadeId = v),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _filtrar();
                  },
                  child: const Text('Aplicar'),
                )
              ]),
            );
          },
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

class _DropdownCidades extends ConsumerWidget {
  final int estadoId;
  final int? valor;
  final ValueChanged<int?> onChanged;

  const _DropdownCidades(
      {required this.estadoId, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cidades = ref.watch(cidadesPorEstadoProvider(estadoId));
    return cidades.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Erro: $e'),
      data: (lista) => DropdownButtonFormField<int>(
        value: valor,
        decoration: const InputDecoration(labelText: 'Cidade'),
        items: lista
            .map((c) =>
            DropdownMenuItem(value: c.id, child: Text(c.nome)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
