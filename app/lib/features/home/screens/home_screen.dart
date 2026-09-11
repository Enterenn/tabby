import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/group.dart';
import '../../../shared/widgets/expressive/expressive.dart';
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

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/tabby_color.svg',
          height: 28,
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: _HealthIndicator(),
          ),
        ],
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
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context.read<HomeCubit>().loadGroups(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          if (state is HomeLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().loadGroups(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (state.groups.isEmpty)
                    _HomeHeader(isEmpty: true)
                  else ...[
                    _HomeHeroBanner(groups: state.groups),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        'Tes groupes',
                        style: context.tabbyType.displayEditorial,
                      ),
                    ),
                  ],
                  if (state.groups.isEmpty)
                    _EmptyState().animate(delay: 100.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.06, end: 0, duration: 500.ms, curve: Curves.easeOut)
                  else
                    ...state.groups.asMap().entries.map((e) =>
                      GroupCard(group: e.value, index: e.key)),
                  const SizedBox(height: 16),
                  Center(
                    child: ExpressiveCtaButton(
                      label: 'Nouveau groupe',
                      onPressed: () => showNewGroupSheet(context),
                    ),
                  ).animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _HealthIndicator extends StatefulWidget {
  const _HealthIndicator();

  @override
  State<_HealthIndicator> createState() => _HealthIndicatorState();
}

class _HealthIndicatorState extends State<_HealthIndicator> {
  _Status _status = _Status.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _status = _Status.checking);
    try {
      await apiClient.dio.get('/health');
      if (mounted) setState(() => _status = _Status.ok);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _check,
      child: Tooltip(
        message: switch (_status) {
          _Status.checking => 'Vérification connexion serveur…',
          _Status.ok => 'Serveur connecté ✓',
          _Status.error => 'Serveur inaccessible — tap pour réessayer',
        },
        child: SizedBox(
          width: 14,
          height: 14,
          child: Material(
            color: switch (_status) {
              _Status.checking => context.tabbySemantic.warning,
              _Status.ok => context.tabbySemantic.success,
              _Status.error => context.tabbySemantic.danger,
            },
            elevation: 0,
            shape: context.tabbyShapes.circle(),
            clipBehavior: Clip.antiAlias,
          ),
        ),
      ),
    );
  }
}

enum _Status { checking, ok, error }

// ─── Hero solde global ────────────────────────────────────────────────────────

class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    final netBalance =
        groups.fold<double>(0, (sum, g) => sum + g.balance);
    final count = groups.length;
    final subtitle = count == 1 ? '1 groupe actif' : '$count groupes actifs';

    return ExpressiveHeroBanner(
      label: 'Solde global',
      value: netBalance.abs().toStringAsFixed(2),
      suffix: ' €',
      subtitle: netBalance.abs() < 0.01
          ? '$subtitle · tout est réglé'
          : netBalance > 0
              ? '$subtitle · on te doit'
              : '$subtitle · tu dois',
      variant: ExpressiveTonalVariant.violet,
      accentIcon: Symbols.account_balance_wallet_rounded,
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 12),
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
            isEmpty ? 'Bienvenue 👋' : 'Tes groupes',
            style: context.tabbyType.displayEditorial,
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty
                ? 'Appuie sur Nouveau groupe pour commencer'
                : 'Appuie sur un groupe pour voir les détails',
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
              color: cs.primaryContainer.withValues(alpha: 0.5),
              elevation: 0,
              shape: context.tabbyShapes.circle(),
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Symbols.group_rounded,
                size: 48,
                color: cs.primary,
                fill: 1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Aucun groupe pour l\'instant',
              style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Utilise Nouveau groupe ci-dessous\npour créer ou rejoindre un groupe !',
            style:
                tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
