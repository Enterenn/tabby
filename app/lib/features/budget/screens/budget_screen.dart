import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/token_storage.dart';
import '../../../core/auth/group_admin.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/budget.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/expressive/expressive_donut_chart.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/stats.dart';
import '../cubit/budget_cubit.dart';

part 'budget_widgets.dart';

bool _isAdminOf(List<Group> groups, String? groupId) {
  final userId = tokenStorage.userId;
  if (groupId == null) {
    return groups.any((g) => isGroupAdmin(userId: userId, ownerId: g.ownerId));
  }
  for (final group in groups) {
    if (group.id == groupId) {
      return isGroupAdmin(userId: userId, ownerId: group.ownerId);
    }
  }
  return false;
}

List<Group> _adminGroups(List<Group> groups) {
  return groups
      .where((g) => isGroupAdmin(userId: tokenStorage.userId, ownerId: g.ownerId))
      .toList();
}

// ─── Entry point ──────────────────────────────────────────────────────────────

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BudgetCubit()..load(),
      child: const _BudgetView(),
    );
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: state is BudgetLoaded
                ? _MonthNav(
                    year: state.selectedYear,
                    monthLabel: state.stats.monthLabel(
                      Localizations.localeOf(context).toString(),
                    ),
                    isCurrentMonth: state.selectedYear == DateTime.now().year &&
                        state.selectedMonth == DateTime.now().month,
                  )
                : Text(context.l10n.budget),
          ),
          body: switch (state) {
            BudgetInitial() || BudgetLoading() => const TabbyLoading(),
            BudgetError(:final message) => TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<BudgetCubit>().load(),
              ),
            BudgetLoaded() => _BudgetContent(
                state: state,
                canCreate: _isAdminOf(state.groups, state.selectedGroupId),
                onCreateBudget: () => _showCreateDialog(context, state),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, BudgetLoaded state) {
    showTabbyFormDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: _BudgetDialog(state: state),
      ),
    );
  }
}
