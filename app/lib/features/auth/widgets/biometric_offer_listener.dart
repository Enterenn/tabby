import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/tabby_sheet.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/biometric_cubit.dart';

/// Propose d'activer la biométrie après un premier login email / mot de passe.
class BiometricOfferListener extends StatelessWidget {
  const BiometricOfferListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, next) =>
          prev is! AuthAuthenticated && next is AuthAuthenticated,
      listener: (context, state) => _maybeOffer(context),
      child: child,
    );
  }
}

Future<void> _maybeOffer(BuildContext context) async {
  final auth = context.read<AuthCubit>();
  if (!auth.consumeBiometricOffer()) return;

  final bio = context.read<BiometricCubit>();
  await bio.refreshAvailability();
  if (!bio.state.available || bio.state.enabled) return;
  if (!context.mounted) return;

  final accept = await showTabbyDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.biometricEnableTitle),
      content: Text(ctx.l10n.biometricEnableBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.biometricNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.biometricEnableConfirm),
        ),
      ],
    ),
  );

  if (!context.mounted) return;
  if (accept == true) {
    final ok = await bio.enable(context.l10n.biometricLockReason);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.biometricFailed)),
      );
    }
  } else {
    await bio.declineOffer();
  }
}
