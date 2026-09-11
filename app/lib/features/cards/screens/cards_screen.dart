import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/loyalty_brand.dart';
import '../../../shared/models/loyalty_card.dart';
import '../../../shared/models/loyalty_prefix_store.dart';
import '../../../shared/models/loyalty_scan.dart';
import '../../../shared/widgets/expressive/expressive.dart';
import '../../../shared/widgets/loyalty/loyalty_card_face.dart';
import '../../../shared/widgets/loyalty/loyalty_wallet_stack.dart';
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
                                        .brand
                                        .onPrimary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
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
  final index = cards.indexWhere((c) => c.id == card.id);
  showModalBottomSheet(
    context: context,
    shape: context.tabbyShapes.modalTopShape,
    builder: (ctx) => BlocProvider.value(
      value: context.read<CardsCubit>(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          final cubit = context.read<CardsCubit>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
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
                  _openFullScreen(context, card);
                },
              ),
              if (index > 0)
                ListTile(
                  leading: const Icon(Symbols.arrow_upward_rounded),
                  title: const Text('Monter'),
                  shape: context.tabbyShapes.fieldShape,
                  onTap: () {
                    Navigator.pop(ctx);
                    final list = List<LoyaltyCard>.from(cards);
                    final item = list.removeAt(index);
                    list.insert(index - 1, item);
                    cubit.reorder(list);
                  },
                ),
              if (index >= 0 && index < cards.length - 1)
                ListTile(
                  leading: const Icon(Symbols.arrow_downward_rounded),
                  title: const Text('Descendre'),
                  shape: context.tabbyShapes.fieldShape,
                  onTap: () {
                    Navigator.pop(ctx);
                    final list = List<LoyaltyCard>.from(cards);
                    final item = list.removeAt(index);
                    list.insert(index + 1, item);
                    cubit.reorder(list);
                  },
                ),
              ListTile(
                leading: Icon(Symbols.delete_rounded, color: cs.error),
                title: Text('Supprimer', style: TextStyle(color: cs.error)),
                shape: context.tabbyShapes.fieldShape,
                onTap: () async {
                  Navigator.pop(ctx);
                  await cubit.deleteCard(card.id);
                },
              ),
            ],
          );
        }),
      ),
    ),
  );
}

// ─── Full-screen card display ─────────────────────────────────────────────────

class _CardFullScreen extends StatelessWidget {
  const _CardFullScreen({required this.card});
  final LoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final brand = card.brand;
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: brand.onPrimary,
        title: Text(card.brandName),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              brand.primary.withValues(alpha: 0.35),
              cs.surfaceContainerLow,
              cs.surfaceContainerLow,
            ],
            stops: const [0, 0.35, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              LoyaltyCardLayout.screenHorizontalInset,
              8,
              LoyaltyCardLayout.screenHorizontalInset,
              32,
            ),
            child: Column(
              children: [
                LoyaltyCardFace(
                  card: card,
                  enableHero: true,
                ),
                const SizedBox(height: 28),
                Card(
                  color: cs.surface,
                  elevation: 2,
                  shadowColor: brand.primary.withValues(alpha: 0.2),
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
                            style:
                                tt.bodyMedium?.copyWith(color: cs.onSurface),
                          )
                        : bw.BarcodeWidget(
                            barcode: bw.Barcode.qrCode(),
                            data: card.codeValue,
                            width: 220,
                            height: 220,
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 380.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 160.ms,
                      duration: 380.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 20),
                Text(
                  card.codeValue,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    letterSpacing: 1.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 320.ms),
                const SizedBox(height: 6),
                Text(
                  card.isBarcode ? 'Code-barres' : 'QR Code',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 280.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Scanner widget ───────────────────────────────────────────────────────────

class _ScannerView extends StatefulWidget {
  const _ScannerView({required this.onDetected, required this.onCancel});

  final ValueChanged<LoyaltyScanPayload> onDetected;
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
                    final barcode = capture.barcodes.firstOrNull;
                    final value = barcode?.rawValue;
                    if (value != null && value.isNotEmpty) {
                      _detected = true;
                      widget.onDetected(LoyaltyScanPayload(
                        value: value,
                        isQrCode: _isQrFormat(barcode!.format),
                      ));
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

  bool _isQrFormat(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.qrCode ||
      BarcodeFormat.dataMatrix ||
      BarcodeFormat.aztec ||
      BarcodeFormat.pdf417 =>
        true,
      _ => false,
    };
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
  final _brandSearchCtrl = TextEditingController();
  String _codeValue = '';
  String _codeType = 'barcode'; // 'barcode' | 'qrcode'
  late Color _selectedColor;
  String? _brandId;
  bool _customBrand = false;
  bool _scanning = true;
  bool _brandAutoDetected = false;
  bool _showBrandPicker = false;
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
  void initState() {
    super.initState();
    LoyaltyPrefixStore.load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandSearchCtrl.dispose();
    super.dispose();
  }

  List<LoyaltyBrand> get _filteredBrands {
    final q = _brandSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return LoyaltyBrand.catalog;
    return LoyaltyBrand.catalog.where((b) {
      if (b.name.toLowerCase().contains(q)) return true;
      if (b.id.contains(q)) return true;
      for (final h in b.qrHints) {
        if (h.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  String _colorToHex(Color c) =>
      '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
      '${c.g.round().toRadixString(16).padLeft(2, '0')}'
      '${c.b.round().toRadixString(16).padLeft(2, '0')}';

  Future<void> _selectBrand(LoyaltyBrand brand) async {
    if (_codeValue.isNotEmpty && _codeType == 'barcode') {
      await LoyaltyPrefixStore.learn(_codeValue, brand.id);
    }
    if (!mounted) return;
    setState(() {
      _customBrand = false;
      _brandId = brand.id;
      _nameCtrl.text = brand.name;
      _selectedColor = brand.primary;
      _brandAutoDetected = _codeValue.isNotEmpty;
      _showBrandPicker = false;
      _brandSearchCtrl.clear();
    });
  }

  void _selectCustomBrand() {
    setState(() {
      _customBrand = true;
      _brandId = null;
      _brandAutoDetected = false;
      _nameCtrl.clear();
      _showBrandPicker = true;
    });
  }

  void _applyScan(LoyaltyScanPayload scan) {
    final brand = LoyaltyBrandDetector.identify(scan);
    setState(() {
      _codeValue = scan.value;
      _codeType = scan.isQrCode ? 'qrcode' : 'barcode';
      _scanning = false;
      if (brand != null) {
        _customBrand = false;
        _brandId = brand.id;
        _nameCtrl.text = brand.name;
        _selectedColor = brand.primary;
        _brandAutoDetected = true;
        _showBrandPicker = false;
      } else {
        _customBrand = false;
        _brandId = null;
        _brandAutoDetected = false;
        _nameCtrl.clear();
        _brandSearchCtrl.clear();
        _showBrandPicker = true;
      }
    });
  }

  void _applyManualCode(String value) {
    final isQr = value.startsWith('http') || value.startsWith('{');
    _applyScan(LoyaltyScanPayload(value: value, isQrCode: isQr));
  }

  bool get _canSubmit {
    if (_codeValue.isEmpty) return false;
    if (_customBrand) return _nameCtrl.text.trim().isNotEmpty;
    return _brandId != null;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _codeValue.isEmpty) return;
    setState(() => _loading = true);
    final ok = await context.read<CardsCubit>().addCard(
          brandName: name,
          codeType: _codeType,
          codeValue: _codeValue,
          color: _colorToHex(_selectedColor),
          brandId: _brandId,
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
              subtitle: _codeValue.isEmpty
                  ? 'Scanne le code-barres ou QR de ta carte'
                  : 'Vérifie l\'enseigne détectée',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Scan en premier ──────────────────────────────────
                  if (_scanning)
                    _ScannerView(
                      onDetected: _applyScan,
                      onCancel: () => setState(() => _scanning = false),
                    )
                  else if (_codeValue.isEmpty) ...[
                    ExpressiveCtaButton(
                      icon: Symbols.photo_camera_rounded,
                      label: 'Scanner ma carte',
                      expanded: true,
                      onPressed: _startScan,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => _showManualInput(context),
                        child: const Text('Saisir le code manuellement'),
                      ),
                    ),
                  ] else ...[
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _codeValue,
                                  style: tt.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _codeType == 'barcode'
                                      ? 'Code-barres'
                                      : 'QR Code',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ExpressiveCtaButton(
                            icon: Symbols.photo_camera_rounded,
                            label: 'Rescanner',
                            variant: ExpressiveCtaVariant.tonal,
                            expanded: true,
                            onPressed: _startScan,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ExpressiveCtaButton(
                            icon: Symbols.edit_rounded,
                            label: 'Modifier',
                            variant: ExpressiveCtaVariant.tonal,
                            expanded: true,
                            onPressed: () => _showManualInput(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // ── 2. Enseigne (auto ou manuelle) ───────────────────────
                  if (_codeValue.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    if (_brandAutoDetected && !_showBrandPicker) ...[
                      ExpressiveSheetSection(
                        label: 'Enseigne détectée',
                        child: _DetectedBrandBanner(
                          brand: LoyaltyBrand.byId(_brandId)!,
                          onChange: () =>
                              setState(() => _showBrandPicker = true),
                        ),
                      ),
                    ] else ...[
                      ExpressiveSheetSection(
                        label: _brandAutoDetected
                            ? 'Enseigne'
                            : 'Enseigne non reconnue',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Le code-barres ne contient pas le nom du magasin. '
                              'Cherche l\'enseigne ci-dessous — on retiendra ce code '
                              'pour les prochains scans.',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _brandSearchCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Ex. Animalis, Picard…',
                                prefixIcon: Icon(
                                  Symbols.search_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 96,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filteredBrands.length + 1,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, i) {
                                  if (i == _filteredBrands.length) {
                                    return _BrandPickerTile(
                                      label: 'Autre',
                                      monogram: '+',
                                      color: cs.outlineVariant,
                                      selected: _customBrand,
                                      onTap: _selectCustomBrand,
                                    );
                                  }
                                  final brand = _filteredBrands[i];
                                  return _BrandPickerTile(
                                    label: brand.name,
                                    monogram: brand.monogram.isEmpty
                                        ? brand.name[0]
                                        : brand.monogram,
                                    color: brand.primary,
                                    selected: !_customBrand &&
                                        _brandId == brand.id,
                                    onTap: () => _selectBrand(brand),
                                  );
                                },
                              ),
                            ),
                            if (_customBrand) ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Nom de l\'enseigne',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (_customBrand) ...[
                      const SizedBox(height: 24),
                      ExpressiveSheetSection(
                        label: 'Couleur',
                        child: Wrap(
                          spacing: 10,
                          children: palette.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
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
                    ],
                    if (_canSubmit) ...[
                      const SizedBox(height: 24),
                      ExpressiveSheetSection(
                        label: 'Aperçu',
                        child: LoyaltyCardFace(
                          card: LoyaltyCard(
                            id: 'preview',
                            brandName: _nameCtrl.text.trim().isEmpty
                                ? 'Ma carte'
                                : _nameCtrl.text.trim(),
                            codeType: _codeType,
                            codeValue: _codeValue,
                            color: _colorToHex(_selectedColor),
                            sortOrder: 0,
                            brandId: _brandId,
                          ),
                          height: 140,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  ExpressiveSheetSubmit(
                    label: 'Ajouter la carte',
                    loading: _loading,
                    onPressed: _canSubmit ? _submit : null,
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
              if (v.isNotEmpty) _applyManualCode(v);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _DetectedBrandBanner extends StatelessWidget {
  const _DetectedBrandBanner({
    required this.brand,
    required this.onChange,
  });

  final LoyaltyBrand brand;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final fg = brand.onPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: brand.gradient,
        borderRadius: context.tabbyShapes.radiusLarge,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: fg.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Text(
              brand.monogram.isEmpty ? brand.name[0] : brand.monogram,
              style: tt.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: tt.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Reconnue automatiquement',
                  style: tt.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(foregroundColor: fg),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
}

class _BrandPickerTile extends StatelessWidget {
  const _BrandPickerTile({
    required this.label,
    required this.monogram,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String monogram;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: shapes.radiusMedium,
      child: Ink(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: shapes.radiusMedium,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.35)
              : cs.surfaceContainerLow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                monogram,
                style: tt.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
