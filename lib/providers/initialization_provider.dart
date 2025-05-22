// lib/providers/initialization_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';

final initializationProvider = FutureProvider<void>((ref) async {
  await ApiService.instance.client.get('/api/locais/estados/');
});
