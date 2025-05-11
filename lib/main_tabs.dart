import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/locais/local_list_screen.dart';
import 'features/creditos/creditos_screen.dart';
import 'features/locais/local_map_screen.dart'; // Novo import

final selectedTabProvider = StateProvider<int>((_) => 0);

class MainTabs extends ConsumerWidget {
  const MainTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(selectedTabProvider);

    final pages = <Widget>[
      const LocalListScreen(),     // Home
      const LocalMapScreen(),     // Novo: Mapa
      const CreditosScreen(),     // Créditos
    ];

    final destinations = const <NavigationDestination>[
      NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),      // Novo
      NavigationDestination(icon: Icon(Icons.info), label: 'Créditos'),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(selectedTabProvider.notifier).state = i,
        destinations: destinations,
      ),
    );
  }
}
