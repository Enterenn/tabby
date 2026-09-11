import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  String? _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  Future<void> _generateCode() async {
    setState(() => _loading = true);
    try {
      final response =
          await apiClient.dio.post('/groups/${widget.groupId}/invite');
      setState(() {
        _code = response.data['code'] as String;
        _loading = false;
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.response?.data?['detail']?.toString() ?? 'Erreur')),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inviter un membre')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('Code d\'invitation',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Partage ce code avec la personne à inviter. Il est valable 24h.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 48),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_code != null) ...[
              Center(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _code!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié !')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 28),
                    decoration: BoxDecoration(
                      // M3 : primaryContainer pour le fond, primary pour la bordure
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.primary, width: 2),
                    ),
                    child: Text(
                      _code!,
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                letterSpacing: 12,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Tap pour copier',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: TextButton.icon(
                  onPressed: _generateCode,
                  icon: const Icon(Symbols.refresh_rounded, size: 18),
                  label: const Text('Générer un nouveau code'),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Retour à l\'accueil'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
