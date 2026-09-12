import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';
import '../cubit/group_form_cubit.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InviteCubit(groupId)..generate(),
      child: const _InviteView(),
    );
  }
}

class _InviteView extends StatelessWidget {
  const _InviteView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.inviteMember)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: BlocConsumer<InviteCubit, InviteState>(
          listener: (context, state) {
            if (state is InviteError) {
              showTabbySnack(context, context.l10nError(state.message));
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  context.l10n.inviteCodeTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.inviteCodeShare,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 48),
                switch (state) {
                  InviteLoading() => const TabbyLoading(),
                  InviteReady(:final code) => Column(
                      children: [
                        Center(
                          child: TabbyInviteCode(
                            code: code,
                            copiedLabel: context.l10n.codeCopied,
                            size: TabbyInviteCodeSize.large,
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
                            onPressed: () =>
                                context.read<InviteCubit>().generate(),
                            icon: const Icon(Symbols.refresh_rounded, size: 18),
                            label: Text(context.l10n.generateNewCode),
                          ),
                        ),
                      ],
                    ),
                  InviteError() => const SizedBox.shrink(),
                },
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/home'),
                    child: Text(context.l10n.backHome),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
