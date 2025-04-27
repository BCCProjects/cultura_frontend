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

  // controladores – evitam problemas de “onSaved” fora de ordem
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _pwd1 = TextEditingController();
  final _pwd2 = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _user.dispose();
    _email.dispose();
    _pwd1.dispose();
    _pwd2.dispose();
    _cidade.dispose();
    _estado.dispose();
    super.dispose();
  }

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
              _input('Usuário', _user,
                  validator: _required,
                  textCapitalization: TextCapitalization.none),
              const SizedBox(height: 16),
              _input('E-mail', _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  v != null && v.contains('@') ? null : 'E-mail inválido'),
              const SizedBox(height: 16),
              _input('Senha', _pwd1,
                  obscure: true,
                  validator: (v) =>
                  v != null && v.length >= 4 ? null : 'Mínimo 4'),
              const SizedBox(height: 16),
              _input('Confirmar senha', _pwd2,
                  obscure: true,
                  validator: (v) =>
                  v == _pwd1.text ? null : 'Senhas não coincidem'),
              const SizedBox(height: 16),
              _input('Estado (sigla ex: SP)', _estado, validator: _required),
              const SizedBox(height: 16),
              _input('Cidade', _cidade, validator: _required),
              const SizedBox(height: 32),
              _busy
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submit,
                child: const Text('Registrar e entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Obrigatório' : null;

  Widget _input(String label, TextEditingController c,
      {bool obscure = false,
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
        TextCapitalization textCapitalization = TextCapitalization.words}) =>
      TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        obscureText: obscure,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
      );

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // cadastro
      await ApiService.instance.client.post(kApiRegistro, data: {
        'username': _user.text.trim(),
        'email': _email.text.trim(),
        'password': _pwd1.text,
        'cidade': _cidade.text.trim(),
        'estado': _estado.text.trim(),
      });

      // login automático
      await ref
          .read(authProvider.notifier)
          .login(_user.text.trim(), _pwd1.text);

      if (mounted) Navigator.pushReplacementNamed(context, '/locals');
    } on DioError catch (e) {
      final msg = e.response?.data.toString() ?? e.message;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $msg')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
