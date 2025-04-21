import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/local.dart';

class LocalDetailScreen extends StatelessWidget {
  final Local local;
  const LocalDetailScreen({super.key, required this.local});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(local.nome)),
      body: ListView(
        children: [
          // Galeria simples
          SizedBox(
            height: 220,
            child: local.imagens.isEmpty
                ? const Center(child: Icon(Icons.photo, size: 80))
                : PageView(
              children: local.imagens
                  .map((url) => Image.network(url, fit: BoxFit.cover))
                  .toList(),
            ),
          ),
          ListTile(
            title: const Text('Tipo'),
            subtitle: Text(local.tipo),
          ),
          ListTile(
            title: const Text('Descrição'),
            subtitle: Text(local.descricao.isNotEmpty
                ? local.descricao
                : 'Sem descrição disponível'),
          ),
          SizedBox(
            height: 250,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(local.latitude, local.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(local.id.toString()),
                  position: LatLng(local.latitude, local.longitude),
                )
              },
              zoomControlsEnabled: false,
            ),
          ),
        ],
      ),
    );
  }
}
