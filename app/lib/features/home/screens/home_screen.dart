import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/home_cubit.dart';
import '../widgets/group_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..loadGroups(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  FilledButton(
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (state.groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Column(
                        children: [
                          Icon(
                            Symbols.group_rounded,
                            size: 64,
                            color: cs.outlineVariant,
                            fill: 0,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pas encore de groupe',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crée un groupe pour commencer à partager tes dépenses',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.groups.map((g) => GroupCard(group: g)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/groups/create'),
                          icon: const Icon(Symbols.add_rounded, size: 18),
                          label: const Text('Créer'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/groups/join'),
                          icon: const Icon(Symbols.person_add_rounded, size: 18),
                          label: const Text('Rejoindre'),
                        ),
                      ),
                    ],
                  ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: switch (_status) {
              _Status.checking => Colors.orange,
              _Status.ok => AppColors.success,
              _Status.error => AppColors.danger,
            },
          ),
        ),
      ),
    );
  }
}

enum _Status { checking, ok, error }
