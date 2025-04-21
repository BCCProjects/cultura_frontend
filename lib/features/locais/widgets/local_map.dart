import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/locais_provider.dart';

class LocalMap extends ConsumerWidget {
  const LocalMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locais = ref.read(locaisProvider).value ?? [];

    if (locais.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Nenhum local carregado')));
    }

    final first = locais.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(first.latitude, first.longitude),
          zoom: 12,
        ),
        markers: {
          for (final l in locais)
            Marker(
              markerId: MarkerId(l.id.toString()),
              position: LatLng(l.latitude, l.longitude),
              infoWindow: InfoWindow(title: l.nome),
            ),
        },
      ),
    );
  }
}
