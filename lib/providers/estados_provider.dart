import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/estado.dart';
import '../core/services/api_service.dart';
import '../core/config.dart';

final estadosProvider =
FutureProvider<List<Estado>>((ref) async {
  final res = await ApiService.instance.client.get(kApiEstados);
  return (res.data as List).map((e) => Estado.fromJson(e)).toList();
});
