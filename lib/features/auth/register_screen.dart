import 'dart:ui';
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

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Estado? _estadoSelecionado;
  Cidade? _cidadeSelecionada;

  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
      body: Stack(
        children: [
          // Background image, blur e overlay (igual ao login)
          Positioned.fill(
            child: Image.asset('images/screen.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xFF013F48).withOpacity(0.4)),
          ),

          // Conteúdo
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Crie sua conta',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Usuário
                          _buildInput(
                            'Usuário',
                            controller: _usernameController,
                            validator: _required,
                          ),
                          const SizedBox(height: 16),

                          // E-mail
                          _buildInput(
                            'E-mail',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : 'E-mail inválido',
                          ),
                          const SizedBox(height: 16),

                          // Senha
                          _buildInput(
                            'Senha',
                            controller: _passwordController,
                            obscure: !_showPassword,
                            suffix: IconButton(
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                      () => _showPassword = !_showPassword),
                            ),
                            validator: (v) => v != null && v.length >= 4
                                ? null
                                : 'Mínimo 4 caracteres',
                          ),
                          const SizedBox(height: 16),

                          // Confirmar senha
                          _buildInput(
                            'Confirmar senha',
                            controller: _confirmPasswordController,
                            obscure: !_showConfirmPassword,
                            suffix: IconButton(
                              icon: Icon(_showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                              _showConfirmPassword =
                              !_showConfirmPassword),
                            ),
                            validator: (v) => v == _passwordController.text
                                ? null
                                : 'Senhas não coincidem',
                          ),
                          const SizedBox(height: 16),

                          // Dropdown de Estado
                          estadosAsync.when(
                            data: (estados) => DropdownButtonFormField<Estado>(
                              value: _estadoSelecionado,
                              items: estados
                                  .map(
                                    (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('${e.nome} (${e.sigla})'),
                                ),
                              )
                                  .toList(),
                              onChanged: (e) => setState(() {
                                _estadoSelecionado = e;
                                _cidadeSelecionada = null;
                              }),
                              decoration:
                              const InputDecoration(labelText: 'Estado'),
                              validator: (v) =>
                              v == null ? 'Obrigatório' : null,
                            ),
                            loading: () =>
                            const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Erro ao carregar estados: $e'),
                                TextButton(
                                  onPressed: () =>
                                      ref.refresh(estadosProvider),
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dropdown de Cidade
                          cidadesAsync.when(
                            data: (cidades) => DropdownButtonFormField<Cidade>(
                              value: _cidadeSelecionada,
                              items: cidades
                                  .map(
                                    (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.nome),
                                ),
                              )
                                  .toList(),
                              onChanged: (c) =>
                                  setState(() => _cidadeSelecionada = c),
                              decoration:
                              const InputDecoration(labelText: 'Cidade'),
                              validator: (v) =>
                              v == null ? 'Obrigatório' : null,
                            ),
                            loading: () =>
                            const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Erro ao carregar cidades: $e'),
                                if (_estadoSelecionado != null)
                                  TextButton(
                                    onPressed: () => ref.refresh(
                                        cidadesPorEstadoProvider(
                                            _estadoSelecionado!.id)),
                                    child: const Text('Tentar novamente'),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Botão de registrar
                          _busy
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Registrar e entrar'),
                          ),

                          const SizedBox(height: 16),
                          // Voltar para login
                          TextButton(
                            onPressed: () => Navigator
                                .pushReplacementNamed(context, '/login'),
                            child: const Text(
                              'Já tem conta? Entrar',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para inputs
  Widget _buildInput(
      String label, {
        required TextEditingController controller,
        bool obscure = false,
        Widget? suffix,
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
      ),
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    try {
      await ApiService.instance.client.post(
        kApiRegistro,
        data: {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'cidade_id': _cidadeSelecionada?.id,
        },
      );
      await ref.read(authProvider.notifier).login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on DioException catch (e) {
      final msg = e.response?.data.toString() ??
          e.message ??
          'Erro desconhecido';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $msg')),
        );
      }
    } catch (e) {
      // Qualquer outro erro pega aqui
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
