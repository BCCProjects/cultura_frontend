import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  late String _u, _e, _p;
  bool _load = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Usuário'),
                onSaved: (v) => _u = v!.trim(),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E‑mail'),
                onSaved: (v) => _e = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                onSaved: (v) => _p = v!,
                validator: (v) =>
                v != null && v.length >= 4 ? null : 'Mínimo 4',
              ),
              const SizedBox(height: 32),
              _load
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submit,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() => _load = true);
    try {
      // cria usuário
      await ApiService.instance.client.post(
        kApiRegistro,
        data: {'username': _u, 'email': _e, 'password': _p},
      );
      // login automático
      await ref.read(authProvider.notifier).login(_u, _p);
      if (mounted) Navigator.pushReplacementNamed(context, '/locals');
    } on DioError catch (e) {
      final m = e.response?.data.toString() ?? e.message;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $m')));
      }
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }
}
