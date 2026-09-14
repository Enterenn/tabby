import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/loyalty_brand.dart';
import '../../../shared/models/loyalty_brand_category.dart';
import '../../../shared/models/loyalty_card.dart';
import '../../../shared/models/loyalty_code_value.dart';
import '../../../shared/models/loyalty_prefix_store.dart';
import '../../../shared/models/loyalty_cards_view.dart';
import '../../../shared/models/loyalty_scan.dart';
import '../../../shared/models/loyalty_screenshot_text.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/loyalty/loyalty_card_face.dart';
import '../../../shared/widgets/loyalty/loyalty_machine_code.dart';
import '../../../shared/widgets/loyalty/loyalty_wallet_stack.dart';
import '../cubit/cards_cubit.dart';

part 'cards_fullscreen.dart';
part 'cards_scanner.dart';
part 'cards_add_sheet.dart';

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

class _CardsView extends StatefulWidget {
  const _CardsView();

  @override
  State<_CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<_CardsView> {
  LoyaltyCardsView _view = LoyaltyCardsView.wallet;
  LoyaltyBrandCategory? _category;
  bool _useFrequent = true;

  @override
  void initState() {
    super.initState();
    LoyaltyCardsViewStore.load().then((view) {
      if (mounted) setState(() => _view = view);
    });
  }

  Future<void> _setView(LoyaltyCardsView view) async {
    setState(() => _view = view);
    await LoyaltyCardsViewStore.save(view);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        final hasCards = state is CardsLoaded && state.cards.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.myCards),
            actions: [
              if (hasCards) _CardsViewMenu(value: _view, onSelected: _setView),
            ],
          ),
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
              onAction: () => _showCardSheet(context),
            ),
            CardsLoaded(:final cards, :final frequent) => _CardsBody(
              cards: cards,
              frequent: frequent,
              view: _view,
              category: _category,
              useFrequent: _useFrequent,
              onFrequent: () => setState(() {
                _useFrequent = true;
                _category = null;
              }),
              onAll: () => setState(() {
                _useFrequent = false;
                _category = null;
              }),
              onCategory: (category) => setState(() {
                _useFrequent = false;
                _category = category;
              }),
            ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _CardsViewMenu extends StatelessWidget {
  const _CardsViewMenu({required this.value, required this.onSelected});

  final LoyaltyCardsView value;
  final ValueChanged<LoyaltyCardsView> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LoyaltyCardsView>(
      tooltip: context.l10n.cardsViewTooltip,
      icon: Icon(_iconFor(value)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final view in LoyaltyCardsView.values)
          PopupMenuItem(
            value: view,
            child: Row(
              children: [
                Icon(_iconFor(view)),
                const SizedBox(width: 12),
                Text(_label(context, view)),
                if (view == value) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Symbols.check_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static IconData _iconFor(LoyaltyCardsView view) => switch (view) {
    LoyaltyCardsView.wallet => Symbols.layers_rounded,
    LoyaltyCardsView.grid => Symbols.grid_view_rounded,
    LoyaltyCardsView.compact => Symbols.view_agenda_rounded,
  };

  static String _label(BuildContext context, LoyaltyCardsView view) =>
      switch (view) {
        LoyaltyCardsView.wallet => context.l10n.cardsViewWallet,
        LoyaltyCardsView.grid => context.l10n.cardsViewGrid,
        LoyaltyCardsView.compact => context.l10n.cardsViewCompact,
      };
}

class _CardsBody extends StatefulWidget {
  const _CardsBody({
    required this.cards,
    required this.frequent,
    required this.view,
    required this.category,
    required this.useFrequent,
    required this.onFrequent,
    required this.onAll,
    required this.onCategory,
  });

  final List<LoyaltyCard> cards;
  final List<LoyaltyCard> frequent;
  final LoyaltyCardsView view;
  final LoyaltyBrandCategory? category;
  final bool useFrequent;
  final VoidCallback onFrequent;
  final VoidCallback onAll;
  final ValueChanged<LoyaltyBrandCategory> onCategory;

  @override
  State<_CardsBody> createState() => _CardsBodyState();
}

class _CardsBodyState extends State<_CardsBody> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_CardsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category == widget.category &&
        oldWidget.view == widget.view &&
        oldWidget.useFrequent == widget.useFrequent) {
      return;
    }
    if (!_scroll.hasClients || _scroll.offset == 0) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  LoyaltyBrandCategory? _selectedOf(List<LoyaltyBrandCategory> present) {
    final category = widget.category;
    if (category != null && present.contains(category)) return category;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final present = LoyaltyBrandCategory.presentIn(widget.cards);
    final selected = _selectedOf(present);
    final showFrequent = widget.frequent.isNotEmpty;
    final frequentSelected =
        showFrequent && widget.useFrequent && selected == null;
    final visible = frequentSelected
        ? widget.frequent
        : selected == null
        ? widget.cards
        : widget.cards
              .where((card) => LoyaltyBrandCategory.ofCard(card) == selected)
              .toList();
    final showBrandChips = present.length >= 2;
    final showChips = showFrequent || showBrandChips;
    final filterKey = frequentSelected
        ? '${widget.view.name}-frequent'
        : '${widget.view.name}-${selected?.name ?? 'all'}';

    return Column(
      children: [
        if (showChips)
          _CategoryChips(
            present: present,
            selected: selected,
            showFrequent: showFrequent,
            frequentSelected: frequentSelected,
            showBrandChips: showBrandChips,
            onFrequent: widget.onFrequent,
            onAll: widget.onAll,
            onCategory: widget.onCategory,
          ),
        Expanded(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (notification) {
              notification.disallowIndicator();
              return false;
            },
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                LoyaltyCardLayout.screenHorizontalInset,
                showChips ? 4 : 12,
                LoyaltyCardLayout.screenHorizontalInset,
                24,
              ),
              child: Column(
                children: [
                  _cardsSwitcher(filterKey, visible),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => _showCardSheet(context),
                    child: Text(context.l10n.addCard),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardsSwitcher(String filterKey, List<LoyaltyCard> visible) {
    final switcher = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          for (final child in previous)
            Positioned(top: 0, left: 0, right: 0, child: child),
          ?current,
        ],
      ),
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(fade),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(filterKey),
        child: _cardsForView(context, visible),
      ),
    );
    if (widget.view == LoyaltyCardsView.wallet) return switcher;
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: switcher,
    );
  }

  Widget _cardsForView(BuildContext context, List<LoyaltyCard> visible) {
    return switch (widget.view) {
      LoyaltyCardsView.wallet => LoyaltyWalletStack(
        cards: visible,
        onTapCard: (c) => _openFullScreen(context, c),
        onReorder: (list) => context.read<CardsCubit>().reorder(
          LoyaltyBrandCategory.mergeVisibleOrder(widget.cards, list),
        ),
      ),
      LoyaltyCardsView.grid => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final tileWidth = (constraints.maxWidth - gap) / 2;
          final tileHeight = tileWidth / 1.52;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in visible)
                SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: LoyaltyCardFace(
                    card: card,
                    style: LoyaltyCardFaceStyle.tile,
                    height: tileHeight,
                    onTap: () => _openFullScreen(context, card),
                    onLongPress: () =>
                        _showActions(context, card, widget.cards),
                  ),
                ),
            ],
          );
        },
      ),
      LoyaltyCardsView.compact => Column(
        children: [
          for (final card in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LoyaltyCardFace(
                card: card,
                style: LoyaltyCardFaceStyle.compact,
                height: 76,
                onTap: () => _openFullScreen(context, card),
                onLongPress: () => _showActions(context, card, widget.cards),
              ),
            ),
        ],
      ),
    };
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.present,
    required this.selected,
    required this.showFrequent,
    required this.frequentSelected,
    required this.showBrandChips,
    required this.onFrequent,
    required this.onAll,
    required this.onCategory,
  });

  final List<LoyaltyBrandCategory> present;
  final LoyaltyBrandCategory? selected;
  final bool showFrequent;
  final bool frequentSelected;
  final bool showBrandChips;
  final VoidCallback onFrequent;
  final VoidCallback onAll;
  final ValueChanged<LoyaltyBrandCategory> onCategory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            if (showFrequent)
              _chip(
                context,
                label: context.l10n.cardsCategoryFrequent,
                selected: frequentSelected,
                onTap: onFrequent,
              ),
            _chip(
              context,
              label: context.l10n.cardsCategoryAll,
              selected: !frequentSelected && selected == null,
              onTap: onAll,
            ),
            if (showBrandChips)
              for (final category in present)
                _chip(
                  context,
                  label: _label(context, category),
                  selected: !frequentSelected && selected == category,
                  onTap: () => onCategory(category),
                ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? cs.tertiaryContainer : cs.surfaceContainerHighest,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected ? cs.onTertiaryContainer : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _label(BuildContext context, LoyaltyBrandCategory category) {
    final l10n = context.l10n;
    return switch (category) {
      LoyaltyBrandCategory.groceries => l10n.cardsCategoryGroceries,
      LoyaltyBrandCategory.pets => l10n.cardsCategoryPets,
      LoyaltyBrandCategory.fashion => l10n.cardsCategoryFashion,
      LoyaltyBrandCategory.home => l10n.cardsCategoryHome,
      LoyaltyBrandCategory.food => l10n.cardsCategoryFood,
      LoyaltyBrandCategory.tech => l10n.cardsCategoryTech,
      LoyaltyBrandCategory.sport => l10n.cardsCategorySport,
      LoyaltyBrandCategory.other => l10n.cardsCategoryOther,
    };
  }
}

void _showCardSheet(BuildContext context, {LoyaltyCard? existing}) {
  showTabbySheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<CardsCubit>(),
      child: _AddCardSheet(existing: existing),
    ),
  );
}

Future<void> _confirmDeleteCard(
  BuildContext context,
  CardsCubit cubit,
  LoyaltyCard card,
) async {
  final confirmed = await showTabbyConfirm(
    context,
    title: context.l10n.deleteLoyaltyCardTitle,
    body: context.l10n.deleteLoyaltyCardBody(card.brandName),
    confirmLabel: context.l10n.delete,
    danger: true,
  );
  if (!confirmed || !context.mounted) return;
  await cubit.deleteCard(card.id);
}

void _openFullScreen(BuildContext context, LoyaltyCard card) {
  final cubit = context.read<CardsCubit>();
  cubit.recordOpen(card.id);
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (routeContext, animation, secondaryAnimation) =>
          _CardFullScreen(
            card: card,
            onEdit: () {
              Navigator.of(routeContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  _showCardSheet(context, existing: card);
                }
              });
            },
            onDelete: () {
              Navigator.of(routeContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (context.mounted) {
                  await _confirmDeleteCard(context, cubit, card);
                }
              });
            },
          ),
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
      TabbyActionSheetItem(
        label: context.l10n.edit,
        icon: Symbols.edit_rounded,
        onTap: () => _showCardSheet(context, existing: card),
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
        onTap: () => _confirmDeleteCard(context, cubit, card),
      ),
    ],
  );
}
