import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth0_service.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  late String _u, _p;
  bool _googleLoading = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              '/images/screen.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Semi-transparent color overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF013F48).withOpacity(0.4),
            ),
          ),
          // Centered content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Faça seu login',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Usuário'),
                                onSaved: (v) => _u = v!.trim(),
                                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Senha'),
                                obscureText: true,
                                onSaved: (v) => _p = v!.trim(),
                                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                              ),
                              const SizedBox(height: 32),
                              auth.loading
                                  ? const Center(child: CircularProgressIndicator())
                                  : ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Entrar'),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: const Text('Ainda não tem conta? Cadastre-se'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _googleLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _handleGoogleLogin,
                      icon: Image.asset(
                        'images/google.png',
                        height: 24,
                      ),
                      label: const Text('Entrar com Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    try {
      await ref.read(authProvider.notifier).login(_u, _p);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      String message = 'Erro ao fazer login.';
      if (e is DioException) {
        final data = e.response?.data;
        final status = e.response?.statusCode;
        if (status == 401 && data is Map) {
          final detail = data['detail']?.toString().toLowerCase() ?? '';
          if (detail.contains('no active account')) {
            message = 'Usuário ou senha inválidos.';
          } else {
            message = data['detail'] ?? message;
          }
        } else if (data is Map && data['detail'] != null) {
          message = data['detail'];
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Google está disponível apenas no app.')),
      );
      return;
    }

    setState(() => _googleLoading = true);
    final token = await loginWithAuth0();
    setState(() => _googleLoading = false);
    if (!mounted) return;
    if (token != null) {
      ref.read(authProvider.notifier).setToken(token);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao fazer login com Google')),
      );
    }
  }
}