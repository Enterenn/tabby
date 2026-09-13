import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/date.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/budget.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/expressive/expressive_donut_chart.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/group.dart';
import '../../../shared/models/personal_expense.dart';
import '../../../shared/models/spend_scope.dart';
import '../../../shared/models/stats.dart';
import '../../personal/widgets/personal_expense_edit_dialog.dart';
import '../cubit/budget_cubit.dart';

part 'budget_widgets.dart';
part 'budget_stats.dart';
part 'budget_card.dart';
part 'budget_personal.dart';

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
            BudgetLoaded() => RefreshIndicator(
                onRefresh: () => context.read<BudgetCubit>().load(
                      year: state.selectedYear,
                      month: state.selectedMonth,
                      groupId: state.selectedGroupId,
                    ),
                child: _BudgetContent(
                  state: state,
                  canCreate: true,
                  onCreateBudget: () => _showCreateDialog(context, state),
                ),
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
