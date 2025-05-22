import 'package:flutter/material.dart';

final _scrollController = ScrollController();
class CreditosScreen extends StatelessWidget {
  const CreditosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Nome da disciplina:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Text('Desenvolvimento de Software\n', textAlign: TextAlign.center),
                const Text(
                  'Nome do professor:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Text('Prof. Dr. Elvio Gilberto da Silva\n', textAlign: TextAlign.center),
                const Text(
                  'Integrantes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Davi Guilherme Grigolin\nFernando Rafael Lopes Filho\nGisler Antônio Ferrarezi Junior\nItalo Lenharo Thomazete\nVictor Augusto de Mattos Carbelotti\n',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Desenvolvimento:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/ciencia_da_computacao.jpg',
                  height: 100,
                  errorBuilder: (ctx, error, stack) => const Icon(Icons.broken_image, size: 100),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Apoio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/coordenadoria_de_extensao.jpg',
                  height: 100,
                  errorBuilder: (ctx, error, stack) => const Icon(Icons.broken_image, size: 100),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Cultivi – Guia de Pontos Culturais\n\n© 2025 – Todos os direitos reservados.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
