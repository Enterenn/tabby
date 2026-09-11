import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabby', style: GoogleFonts.baloo2(fontWeight: FontWeight.w800)),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: _HealthIndicator(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Mes groupes — Lot 1'),
      ),
    );
  }
}

/// Pastille de connexion serveur — appelle /health et affiche vert/rouge.
/// Accessible depuis l'AppBar, tap pour relancer le check.
class _HealthIndicator extends StatefulWidget {
  const _HealthIndicator();

  @override
  State<_HealthIndicator> createState() => _HealthIndicatorState();
}

class _HealthIndicatorState extends State<_HealthIndicator> {
  _Status _status = _Status.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _status = _Status.checking);
    try {
      await apiClient.dio.get('/health');
      if (mounted) setState(() => _status = _Status.ok);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _check,
      child: Tooltip(
        message: switch (_status) {
          _Status.checking => 'Vérification connexion serveur…',
          _Status.ok => 'Serveur connecté ✓',
          _Status.error => 'Serveur inaccessible — tap pour réessayer',
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: switch (_status) {
              _Status.checking => Colors.orange,
              _Status.ok => const Color(0xFF4C9A6A),
              _Status.error => const Color(0xFFE4573D),
            },
          ),
        ),
      ),
    );
  }
}

enum _Status { checking, ok, error }
