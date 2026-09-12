import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

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
                  Text(context.l10nError(
                      e.response?.data?['detail']?.toString()))),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.inviteMember)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(context.l10n.inviteCodeTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              context.l10n.inviteCodeShare,
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
                      SnackBar(content: Text(context.l10n.codeCopied)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 28),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: context.tabbyShapes.radiusExtraLarge,
                      border: Border.all(color: cs.tertiary, width: 2),
                    ),
                    child: Text(
                      _code!,
                      style: context.tabbyType.clockDisplay.copyWith(
                        fontSize: 40,
                        letterSpacing: 12,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  context.l10n.tapToCopy,
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
                  label: Text(context.l10n.generateNewCode),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: Text(context.l10n.backHome),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
