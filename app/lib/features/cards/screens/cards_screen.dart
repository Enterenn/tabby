import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/loyalty_card.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../../../shared/widgets/tabby_sheet.dart';
import '../cubit/cards_cubit.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mes cartes')),
          body: switch (state) {
            CardsInitial() || CardsLoading() =>
              const Center(child: CircularProgressIndicator()),
            CardsError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => context.read<CardsCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            CardsLoaded(:final cards) when cards.isEmpty => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.credit_card_rounded,
                          size: 56, color: cs.outlineVariant),
                      const SizedBox(height: 16),
                      Text('Aucune carte', style: tt.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoute ta première carte de fidélité\navec le bouton ci-dessous',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ExpressiveCtaButton(
                        label: 'Ajouter une carte',
                        onPressed: () => _showAddSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
            CardsLoaded(:final cards) => Column(
                children: [
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: cards.length,
                      onReorderItem: (oldIndex, newIndex) {
                        final list = List<LoyaltyCard>.from(cards);
                        final item = list.removeAt(oldIndex);
                        list.insert(newIndex, item);
                        context.read<CardsCubit>().reorder(list);
                      },
                      itemBuilder: (context, i) => _LoyaltyCardTile(
                        key: ValueKey(cards[i].id),
                        card: cards[i],
                      ),
                    ),
                  ),
                  Center(
                    child: ExpressiveCtaButton(
                      label: 'Ajouter une carte',
                      onPressed: () => _showAddSheet(context),
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

// ─── Loyalty card tile ────────────────────────────────────────────────────────

class _LoyaltyCardTile extends StatelessWidget {
  const _LoyaltyCardTile({super.key, required this.card});
  final LoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final cardColor = card.flutterColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFullScreen(context),
        onLongPress: () => _showActions(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bande colorée
            Container(
              height: 6,
              color: cardColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  // Avatar lettrine
                  ExpressiveAvatar(
                    label: card.brandName,
                    size: 44,
                    color: cardColor.withValues(alpha: 0.15),
                    textColor: cardColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.brandName, style: tt.titleMedium),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              card.isBarcode
                                  ? Symbols.barcode_rounded
                                  : Symbols.qr_code_rounded,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              card.isBarcode ? 'Code-barres' : 'QR Code',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: 0,
                    child: Icon(Symbols.drag_indicator_rounded,
                        color: cs.outlineVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CardFullScreen(card: card),
    ));
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: context.tabbyShapes.modalTopShape,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CardsCubit>(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: context.tabbyShapes.radiusExtraSmall,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Symbols.fullscreen_rounded),
                title: const Text('Afficher la carte'),
                shape: context.tabbyShapes.fieldShape,
                onTap: () {
                  Navigator.pop(ctx);
                  _openFullScreen(context);
                },
              ),
              ListTile(
                leading:
                    Icon(Symbols.delete_rounded, color: cs.error),
                title: Text('Supprimer', style: TextStyle(color: cs.error)),
                shape: context.tabbyShapes.fieldShape,
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<CardsCubit>().deleteCard(card.id);
                },
              ),
            ],
          );
          }),
        ),
      ),
    );
  }
}

// ─── Full-screen card display ─────────────────────────────────────────────────

class _CardFullScreen extends StatelessWidget {
  const _CardFullScreen({required this.card});
  final LoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cardColor = card.flutterColor;

    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(title: Text(card.brandName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.brandName,
                style: tt.headlineMedium?.copyWith(color: cardColor),
              ),
              const SizedBox(height: 40),
              Card(
                color: cs.surfaceContainerHighest,
                elevation: 0,
                shape: shapes.cardShape,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: card.isBarcode
                      ? bw.BarcodeWidget(
                          barcode: bw.Barcode.code128(),
                          data: card.codeValue,
                          width: double.infinity,
                          height: 100,
                          drawText: true,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                        )
                      : bw.BarcodeWidget(
                          barcode: bw.Barcode.qrCode(),
                          data: card.codeValue,
                          width: 200,
                          height: 200,
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                card.codeValue,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.isBarcode ? 'Code-barres' : 'QR Code',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scanner widget ───────────────────────────────────────────────────────────

class _ScannerView extends StatefulWidget {
  const _ScannerView({required this.onDetected, required this.onCancel});

  final ValueChanged<String> onDetected;
  final VoidCallback onCancel;

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  late final MobileScannerController _ctrl;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: context.tabbyShapes.radiusLarge,
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _ctrl,
                  onDetect: (capture) {
                    if (_detected) return;
                    final value = capture.barcodes.firstOrNull?.rawValue;
                    if (value != null && value.isNotEmpty) {
                      _detected = true;
                      widget.onDetected(value);
                    }
                  },
                  errorBuilder: (context, error) {
                    // Permission refusée ou caméra indisponible
                    return Container(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.photo_camera_rounded,
                                size: 40, color: cs.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Accès à la caméra refusé',
                              style: tt.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                await _ctrl.stop();
                                await _ctrl.start();
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Viseur central
                IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 110,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              width: 2,
                            ),
                            borderRadius: context.tabbyShapes.radiusMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Centrez le code dans le cadre',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Symbols.close_rounded, size: 16),
          label: const Text('Annuler le scan'),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Add card bottom sheet ────────────────────────────────────────────────────

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _nameCtrl = TextEditingController();
  String _codeValue = '';
  String _codeType = 'barcode'; // 'barcode' | 'qrcode'
  late Color _selectedColor;
  bool _scanning = false;
  bool _loading = false;
  bool _colorInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_colorInitialized) {
      _selectedColor = context.tabbySemantic.categoryPalette[4];
      _colorInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
      '${c.g.round().toRadixString(16).padLeft(2, '0')}'
      '${c.b.round().toRadixString(16).padLeft(2, '0')}';

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _codeValue.isEmpty) return;
    setState(() => _loading = true);
    final ok = await context.read<CardsCubit>().addCard(
          brandName: name,
          codeType: _codeType,
          codeValue: _codeValue,
          color: _colorToHex(_selectedColor),
        );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;
    final palette = context.tabbySemantic.categoryPalette;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpressiveSheetHeader(
              title: 'Nouvelle carte',
              subtitle: 'Scanne ou saisis ta carte de fidélité',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExpressiveSheetSection(
                    label: 'Marque',
                    child: TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex. Carrefour, Sephora…',
                      ),
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ExpressiveSheetSection(
                    label: 'Type de code',
                    child: ExpressiveButtonGroup<String>(
                      value: _codeType,
                      onChanged: (v) => setState(() => _codeType = v),
                      segments: const [
                        ExpressiveButtonGroupSegment(
                          value: 'barcode',
                          label: 'Code-barres',
                        ),
                        ExpressiveButtonGroupSegment(
                          value: 'qrcode',
                          label: 'QR Code',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ExpressiveSheetSection(
                    label: 'Code',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        if (_scanning)
                          _ScannerView(
                            onDetected: (value) => setState(() {
                              _codeValue = value;
                              _scanning = false;
                            }),
                            onCancel: () => setState(() => _scanning = false),
                          )
                        else ...[
                          if (_codeValue.isNotEmpty) ...[
                            ExpressiveTonalCard(
                              variant: ExpressiveTonalVariant.neutral,
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    _codeType == 'barcode'
                                        ? Symbols.barcode_rounded
                                        : Symbols.qr_code_rounded,
                                    size: 20,
                                    color: cs.onSurfaceVariant,
                                    fill: 1,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _codeValue,
                                      style: tt.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Symbols.close_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _codeValue = ''),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: ExpressiveCtaButton(
                                  icon: Symbols.photo_camera_rounded,
                                  label: _codeValue.isEmpty
                                      ? 'Scanner'
                                      : 'Rescanner',
                                  variant: ExpressiveCtaVariant.tonal,
                                  expanded: true,
                                  onPressed: _startScan,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ExpressiveCtaButton(
                                  icon: Symbols.edit_rounded,
                                  label: 'Saisir',
                                  variant: ExpressiveCtaVariant.tonal,
                                  expanded: true,
                                  onPressed: () =>
                                      _showManualInput(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ExpressiveSheetSection(
                    label: 'Couleur',
                    child: Wrap(
                      spacing: 10,
                      children: palette.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Material(
                            color: color,
                            shape: shapes.circle(),
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: isSelected
                                  ? Icon(
                                      Symbols.check_rounded,
                                      color: cs.onPrimary,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ExpressiveSheetSubmit(
                    label: 'Ajouter la carte',
                    loading: _loading,
                    onPressed: (_nameCtrl.text.trim().isEmpty ||
                            _codeValue.isEmpty)
                        ? null
                        : _submit,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startScan() => setState(() => _scanning = true);

  void _showManualInput(BuildContext context) {
    final ctrl = TextEditingController(text: _codeValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saisir le code'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: 1234567890123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                setState(() => _codeValue = v);
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
