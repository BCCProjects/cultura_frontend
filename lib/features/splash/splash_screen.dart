import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';    // <-- import correto
import '../../main_tabs.dart';
import '../auth/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String message = 'Carregando...';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) fn();
  }

  Future<void> _startInitialization() async {
    final isAuth = await _initializeBackend();
    await Future.delayed(const Duration(seconds: 8));

    if (!_disposed && mounted) {
      if (isAuth) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainTabs()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<bool> _initializeBackend() async {
    // 1) Leia o access token salvo
    final access = await AuthStorage.readAccess();
    // 2) Injete no ApiService antes de qualquer request
    if (access != null && access.isNotEmpty) {
      ApiService.instance.setToken(access);
    }

    try {
      _safeSetState(() => message = 'Acordando servidor...');
      await ApiService.instance.client.get('/api/locais/estados');

      _safeSetState(() => message = 'Verificando autenticação...');
      await Future.delayed(const Duration(seconds: 1));

      return access != null && access.isNotEmpty;
    } catch (e) {
      _safeSetState(() => message = 'Carregando...');
      await Future.delayed(const Duration(seconds: 3));
      if (!_disposed && mounted) {
        return _initializeBackend();
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/template.png',
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
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF013F48).withOpacity(0.4),
            ),
          ),
          // Conteúdo central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/cultural_loading.json',
                  width: 150,
                  repeat: true,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
