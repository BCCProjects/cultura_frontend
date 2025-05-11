import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/local_map.dart';

class LocalMapScreen extends ConsumerWidget {
  const LocalMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: LocalMap(),
    );
  }
}
