import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/group.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../../../shared/widgets/tabby_logo.dart';
import '../cubit/home_cubit.dart';
import '../widgets/group_card.dart';
import '../widgets/new_group_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeCubit _cubit;
  GoRouter? _router;
  String _lastPath = '';
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    _cubit = HomeCubit()..loadGroups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _router = GoRouter.of(context);
      _lastPath = _router!.state.uri.path;
      _router!.routerDelegate.addListener(_onRouteChange);
      _listenerAdded = true;
    }
  }

  void _onRouteChange() {
    if (!mounted) return;
    final newPath = _router!.state.uri.path;
    // Recharge uniquement quand on revient sur /home depuis une autre route
    if (newPath == '/home' && _lastPath != '/home') {
      _cubit.loadGroups();
    }
    _lastPath = newPath;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChange);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _scrollController = ScrollController();
  final _headerLinkKey = GlobalKey();
  bool _headerLinkVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHeaderLinkVisibility);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateHeaderLinkVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateHeaderLinkVisibility() {
    final headerContext = _headerLinkKey.currentContext;
    if (headerContext == null) return;
    final box = headerContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final scrollable = Scrollable.maybeOf(headerContext);
    final viewport = scrollable?.context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;

    final headerTop = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final visible = headerTop + box.size.height > 0;
    if (visible != _headerLinkVisible) {
      setState(() => _headerLinkVisible = visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TabbyLogo(height: 28),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10nError(state.message), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context.read<HomeCubit>().loadGroups(),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            );
          }
          if (state is HomeLoaded) {
            final hasGroups = state.groups.isNotEmpty;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _updateHeaderLinkVisibility();
            });
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => context.read<HomeCubit>().loadGroups(),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      if (!hasGroups)
                        _HomeHeader(isEmpty: true)
                      else ...[
                        _HomeHeroBanner(groups: state.groups),
                        const SizedBox(height: 4),
                        _GroupsSectionHeader(
                          key: _headerLinkKey,
                          onNewGroup: () => showNewGroupSheet(context),
                        ),
                      ],
                      if (!hasGroups)
                        _EmptyState().animate(delay: 100.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.06, end: 0, duration: 500.ms, curve: Curves.easeOut)
                      else
                        ...state.groups.asMap().entries.map((e) =>
                          GroupCard(group: e.value, index: e.key)),
                      if (!hasGroups) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: ExpressiveCtaButton(
                            label: context.l10n.newGroup,
                            onPressed: () => showNewGroupSheet(context),
                          ),
                        ).animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      ],
                    ],
                  ),
                ),
                if (hasGroups)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 100,
                    child: IgnorePointer(
                      ignoring: _headerLinkVisible,
                      child: AnimatedOpacity(
                        opacity: _headerLinkVisible ? 0 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: context.tabbyShapes.radiusFull,
                              boxShadow: [
                                BoxShadow(
                                  color: context.tabbyColors.shadow
                                      .withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ExpressiveCtaButton(
                              label: context.l10n.newGroup,
                              onPressed: () => showNewGroupSheet(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _GroupsSectionHeader extends StatelessWidget {
  const _GroupsSectionHeader({super.key, required this.onNewGroup});

  final VoidCallback onNewGroup;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.yourGroups,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onNewGroup,
            child: Text(context.l10n.newGroup),
          ),
        ],
      ),
    );
  }
}

// ─── Hero solde global ────────────────────────────────────────────────────────

class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    final netBalance =
        groups.fold<double>(0, (sum, g) => sum + g.balance);
    final count = groups.length;

    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final color = netBalance.abs() < 0.01
        ? cs.onSurface
        : netBalance > 0
            ? context.tabbySemantic.success
            : context.tabbySemantic.danger;

    return Card(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              Symbols.account_balance_wallet_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.globalBalance,
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(context, netBalance),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              context.l10n.activeGroups(count),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: -0.05, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ─── Home header ──────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isEmpty});
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEmpty ? context.l10n.welcome : context.l10n.yourGroups,
            style: context.tabbyType.displayEditorial,
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty
                ? context.l10n.homeEmptyHint
                : context.l10n.homeGroupsHint,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: -0.05, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Material(
              color: cs.primaryContainer,
              elevation: 0,
              shape: context.tabbyShapes.circle(),
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Symbols.group_rounded,
                size: 48,
                color: cs.onPrimaryContainer,
                fill: 1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(context.l10n.homeEmptyTitle,
              style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            context.l10n.homeEmptyBody,
            style:
                tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
