import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/loyalty_brand.dart';
import '../../../shared/models/loyalty_card.dart';
import '../../../shared/models/loyalty_prefix_store.dart';
import '../../../shared/models/loyalty_scan.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/loyalty/loyalty_card_face.dart';
import '../../../shared/widgets/loyalty/loyalty_wallet_stack.dart';
import '../cubit/cards_cubit.dart';

part 'cards_widgets.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CardsCubit()..load(),
      child: const _CardsView(),
    );
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────

class _CardsView extends StatelessWidget {
  const _CardsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.myCards)),
          body: switch (state) {
            CardsInitial() || CardsLoading() => const TabbyLoading(),
            CardsError(:final message) => TabbyErrorState(
                message: context.l10nError(message),
                retryLabel: context.l10n.retry,
                onRetry: () => context.read<CardsCubit>().load(),
              ),
            CardsLoaded(:final cards) when cards.isEmpty => TabbyEmptyState(
                icon: Symbols.credit_card_rounded,
                title: context.l10n.noCards,
                body: context.l10n.noCardsHint,
                actionLabel: context.l10n.addCard,
                onAction: () => _showAddSheet(context),
              ),
            CardsLoaded(:final cards) => Column(
                children: [
                  Expanded(
                    child: cards.length <= 8
                        ? SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              LoyaltyCardLayout.screenHorizontalInset,
                              12,
                              LoyaltyCardLayout.screenHorizontalInset,
                              8,
                            ),
                            child: LoyaltyWalletStack(
                              cards: cards,
                              onTapCard: (c) => _openFullScreen(context, c),
                              onLongPressCard: (c) =>
                                  _showActions(context, c, cards),
                              onReorder: (list) =>
                                  context.read<CardsCubit>().reorder(list),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              LoyaltyCardLayout.screenHorizontalInset,
                              8,
                              LoyaltyCardLayout.screenHorizontalInset,
                              8,
                            ),
                            itemCount: cards.length,
                            onReorderItem: (oldIndex, newIndex) {
                              final list = List<LoyaltyCard>.from(cards);
                              final item = list.removeAt(oldIndex);
                              list.insert(newIndex, item);
                              context.read<CardsCubit>().reorder(list);
                            },
                            itemBuilder: (context, i) => Padding(
                              key: ValueKey(cards[i].id),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LoyaltyCardFace(
                                card: cards[i],
                                enableHero: true,
                                onTap: () =>
                                    _openFullScreen(context, cards[i]),
                                onLongPress: () =>
                                    _showActions(context, cards[i], cards),
                                trailing: ReorderableDragStartListener(
                                  index: i,
                                  child: Icon(
                                    Symbols.drag_indicator_rounded,
                                    color: cards[i]
                                        .brandFor(context.tabbySemantic.brandFallback)
                                        .onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: () => _showAddSheet(context),
                      child: Text(context.l10n.addCard),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  void _showAddSheet(BuildContext context) {
    showTabbySheet(
      context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CardsCubit>(),
        child: const _AddCardSheet(),
      ),
    );
  }
}

void _openFullScreen(BuildContext context, LoyaltyCard card) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _CardFullScreen(card: card),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    ),
  );
}

void _showActions(
  BuildContext context,
  LoyaltyCard card,
  List<LoyaltyCard> cards,
) {
  final cubit = context.read<CardsCubit>();
  final index = cards.indexWhere((c) => c.id == card.id);
  showTabbyActionSheet(
    context,
    actions: [
      TabbyActionSheetItem(
        label: context.l10n.showCard,
        icon: Symbols.fullscreen_rounded,
        onTap: () => _openFullScreen(context, card),
      ),
      if (index > 0)
        TabbyActionSheetItem(
          label: context.l10n.moveUp,
          icon: Symbols.arrow_upward_rounded,
          onTap: () {
            final list = List<LoyaltyCard>.from(cards);
            final item = list.removeAt(index);
            list.insert(index - 1, item);
            cubit.reorder(list);
          },
        ),
      if (index >= 0 && index < cards.length - 1)
        TabbyActionSheetItem(
          label: context.l10n.moveDown,
          icon: Symbols.arrow_downward_rounded,
          onTap: () {
            final list = List<LoyaltyCard>.from(cards);
            final item = list.removeAt(index);
            list.insert(index + 1, item);
            cubit.reorder(list);
          },
        ),
      TabbyActionSheetItem(
        label: context.l10n.delete,
        icon: Symbols.delete_rounded,
        danger: true,
        onTap: () => cubit.deleteCard(card.id),
      ),
    ],
  );
}
