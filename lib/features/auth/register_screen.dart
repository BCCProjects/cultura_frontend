import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/models/cidade.dart';
import '../../core/models/estado.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cidades_provider.dart';
import '../../providers/estados_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Seleções
  Estado? _estadoSelecionado;
  Cidade? _cidadeSelecionada;

  bool _busy = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadosAsync = ref.watch(estadosProvider);
    final cidadesAsync = _estadoSelecionado != null
        ? ref.watch(cidadesPorEstadoProvider(_estadoSelecionado!.id))
        : const AsyncValue.data(<Cidade>[]);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput('Usuário', _usernameController, validator: _required),
              const SizedBox(height: 16),
              _buildInput('E-mail', _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v != null && v.contains('@') ? null : 'E-mail inválido'),
              const SizedBox(height: 16),
              _buildInput('Senha', _passwordController,
                  obscure: true, validator: (v) => v != null && v.length >= 4 ? null : 'Mínimo 4'),
              const SizedBox(height: 16),
              _buildInput('Confirmar senha', _confirmPasswordController,
                  obscure: true, validator: (v) => v == _passwordController.text ? null : 'Senhas não coincidem'),
              const SizedBox(height: 16),

              // Dropdown de estados
              estadosAsync.when(
                data: (estados) => DropdownButtonFormField<Estado>(
                  value: _estadoSelecionado,
                  items: estados.map<DropdownMenuItem<Estado>>((e) {
                    return DropdownMenuItem<Estado>(
                      value: e,
                      child: Text('${e.nome} (${e.sigla})'),
                    );
                  }).toList(),
                  onChanged: (estado) {
                    setState(() {
                      _estadoSelecionado = estado;
                      _cidadeSelecionada = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Estado'),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erro ao carregar estados: $e'),
              ),
              const SizedBox(height: 16),

              // Dropdown de cidades
              cidadesAsync.when(
                data: (cidades) => DropdownButtonFormField<Cidade>(
                  value: _cidadeSelecionada,
                  items: cidades.map<DropdownMenuItem<Cidade>>((c) {
                    return DropdownMenuItem<Cidade>(
                      value: c,
                      child: Text(c.nome),
                    );
                  }).toList(),
                  onChanged: (cidade) {
                    setState(() => _cidadeSelecionada = cidade);
                  },
                  decoration: const InputDecoration(labelText: 'Cidade'),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erro ao carregar cidades: $e'),
              ),
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

  // ===== Helpers =====

  String? _required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Obrigatório' : null;
  }

  Widget _buildInput(
      String label,
      TextEditingController controller, {
        bool obscure = false,
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
        TextCapitalization textCapitalization = TextCapitalization.none,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      // Envia os dados de registro
      await ApiService.instance.client.post(kApiRegistro, data: {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'cidade_id': _cidadeSelecionada?.id,
      });

      // Faz login automático
      await ref
          .read(authProvider.notifier)
          .login(_usernameController.text.trim(), _passwordController.text);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on DioException catch (e) {
      final msg = e.response?.data.toString() ?? e.message ?? 'Erro desconhecido';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $msg')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
