import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await apiClient.dio.post('/groups/join', data: {
        'code': _codeCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu as rejoint le groupe !')),
        );
        context.go('/home');
      }
    } on DioException catch (e) {
      if (mounted) {
        final detail = e.response?.data?['detail']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (detail) {
              'Invalid invite code' => 'Code invalide',
              'Invite already used' => 'Ce code a déjà été utilisé',
              'Invite expired' => 'Ce code a expiré',
              'Already a member' => 'Tu es déjà membre de ce groupe',
              _ => detail ?? 'Erreur',
            }),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre un groupe')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('Entrer le code d\'invitation',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Demande le code à 6 chiffres à la personne qui a créé le groupe.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: context.tabbyType.clockDisplay.copyWith(
                      fontSize: 36,
                      letterSpacing: 8,
                    ),
                decoration: const InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  counterText: '',
                ),
                validator: (v) =>
                    v == null || v.length != 6 ? 'Code à 6 chiffres requis' : null,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Rejoindre'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
