import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/cidade.dart';
import '../core/services/api_service.dart';
import '../core/config.dart';

final cidadesPorEstadoProvider =
FutureProvider.family<List<Cidade>, int>((ref, estadoId) async {
  final res = await ApiService.instance.client
      .get(kApiCidades, queryParameters: {'estado': estadoId});
  return (res.data as List).map((e) => Cidade.fromJson(e)).toList();
});
