import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/local.dart';

class LocalDetailScreen extends StatefulWidget {
  final Local local;
  const LocalDetailScreen({super.key, required this.local});

  @override
  State<LocalDetailScreen> createState() => _LocalDetailScreenState();
}

class _LocalDetailScreenState extends State<LocalDetailScreen> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final local = widget.local;

    return Scaffold(
      appBar: AppBar(title: Text(local.nome)),
      body: ListView(
        primary: false,
        padding: const EdgeInsets.all(16),
        children: [
          _buildImageCarousel(local),
          const SizedBox(height: 8),
          _buildDotsIndicator(local),
          const SizedBox(height: 16),
          _buildInfoSection(local),
          const SizedBox(height: 16),
          _buildMap(local),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(Local local) {
    if (local.imagens.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.photo, size: 80, color: Colors.grey)),
      );
    }

    return CarouselSlider.builder(
      itemCount: local.imagens.length,
      itemBuilder: (context, index, realIndex) {
        final url = local.imagens[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullscreenImageCarousel(
                images: local.imagens,
                initialIndex: index,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (c, e, s) =>
                  const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  loadingBuilder: (c, child, progress) =>
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 220,
        viewportFraction: 0.92,
        enlargeCenterPage: true,
        autoPlay: true,
        enableInfiniteScroll: true,
        onPageChanged: (index, _) => setState(() => _activeIndex = index),
      ),
    );
  }

  Widget _buildDotsIndicator(Local local) {
    if (local.imagens.length < 2) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(local.imagens.length, (i) {
        final isActive = i == _activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        );
      }),
    );
  }

  Widget _buildInfoSection(Local local) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoTile('Tipo', local.tipo),
        _buildInfoTile('Descrição', local.descricao),
        if (local.endereco != null) _buildInfoTile('Endereço', local.endereco!),
        if (local.bairro != null) _buildInfoTile('Bairro', local.bairro!),
        if (local.cidade != null || local.estado != null)
          _buildInfoTile('Cidade/Estado', '${local.cidade ?? ''} - ${local.estado ?? ''}'),
        if (local.horarioFuncionamento != null)
          _buildInfoTile('Horário de Funcionamento', local.horarioFuncionamento!),
        if (local.linkExterno != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mais informações'),
            subtitle: Text(local.linkExterno!,
                style: const TextStyle(color: Colors.blue)),
            onTap: () async {
              final url = Uri.tryParse(local.linkExterno!);
              if (url != null && await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title:
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildMap(Local local) {
    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(local.latitude, local.longitude),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(local.id.toString()),
              position: LatLng(local.latitude, local.longitude),
            ),
          },
          zoomControlsEnabled: false,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
          },
        ),
      ),
    );
  }
}

// -----------------------------------------
// Fullscreen carousel when tapping uma imagem
// -----------------------------------------
class FullscreenImageCarousel extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const FullscreenImageCarousel({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _FullscreenImageCarouselState createState() =>
      _FullscreenImageCarouselState();
}

class _FullscreenImageCarouselState
    extends State<FullscreenImageCarousel> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CarouselSlider.builder(
              itemCount: widget.images.length,
              itemBuilder: (c, i, real) {
                final url = widget.images[i];
                return InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 80, color: Colors.white),
                    loadingBuilder: (c, child, progress) =>
                    progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                  ),
                );
              },
              options: CarouselOptions(
                initialPage: widget.initialIndex,
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                onPageChanged: (i, _) => setState(() => _currentIndex = i),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.images.asMap().entries.map((e) {
              final idx = e.key;
              final isActive = idx == _currentIndex;
              return Container(
                width: isActive ? 12 : 8,
                height: isActive ? 12 : 8,
                margin:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
