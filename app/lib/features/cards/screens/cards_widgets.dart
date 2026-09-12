part of 'cards_screen.dart';
// ─── Full-screen card display ─────────────────────────────────────────────────

class _CardFullScreen extends StatelessWidget {
  const _CardFullScreen({required this.card});
  final LoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = context.tabbyColors;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text(card.brandName),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(color: cs.surface),
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
                TabbyListCard(
                  color: cs.surfaceContainerLowest,
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
                  card.isBarcode ? context.l10n.barcode : context.l10n.qrCode,
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

bool _isLoyaltyQr(BarcodeFormat format) {
  return switch (format) {
    BarcodeFormat.qrCode ||
    BarcodeFormat.dataMatrix ||
    BarcodeFormat.aztec ||
    BarcodeFormat.pdf417 =>
      true,
    _ => false,
  };
}

class _ScannerView extends StatefulWidget {
  const _ScannerView({
    required this.onDetected,
    required this.onCancel,
    required this.onImportScreenshot,
  });

  final ValueChanged<LoyaltyScanPayload> onDetected;
  final VoidCallback onCancel;
  final VoidCallback onImportScreenshot;

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
                        isQrCode: _isLoyaltyQr(barcode!.format),
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
                              context.l10n.cameraDenied,
                              style: tt.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                await _ctrl.stop();
                                await _ctrl.start();
                              },
                              child: Text(context.l10n.retry),
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
                              color: cs.onPrimary,
                              width: 2,
                            ),
                            borderRadius: context.tabbyShapes.radiusMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.centerCode,
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
          onPressed: widget.onImportScreenshot,
          icon: const Icon(Symbols.image_rounded, size: 16),
          label: Text(context.l10n.scanFromScreenshot),
        ),
        TextButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Symbols.close_rounded, size: 16),
          label: Text(context.l10n.cancelScan),
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
    return LoyaltyBrand.catalog.where((b) => b.matchesQuery(q)).toList();
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
    final semantic = context.tabbySemantic;
    final tt = Theme.of(context).textTheme;
    final shapes = context.tabbyShapes;
    final palette = semantic.categoryPalette;

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
              title: context.l10n.newCard,
              subtitle: _codeValue.isEmpty
                  ? context.l10n.newCardScanHint
                  : context.l10n.newCardCheckHint,
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
                      onImportScreenshot: _importScreenshot,
                    )
                  else if (_codeValue.isEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Symbols.photo_camera_rounded),
                        label: Text(context.l10n.scanMyCard),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _importScreenshot,
                        icon: const Icon(Symbols.image_rounded, size: 18),
                        label: Text(context.l10n.scanFromScreenshot),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => _showManualInput(context),
                        child: Text(context.l10n.enterCodeManually),
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
                                      ? context.l10n.barcode
                                      : context.l10n.qrCode,
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
                          child: FilledButton.tonalIcon(
                            onPressed: _startScan,
                            icon: const Icon(Symbols.photo_camera_rounded),
                            label: Text(context.l10n.rescan),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _showManualInput(context),
                            icon: const Icon(Symbols.edit_rounded),
                            label: Text(context.l10n.edit),
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
                        label: context.l10n.detectedBrand,
                        child: _DetectedBrandBanner(
                          brand: LoyaltyBrand.byId(_brandId)!,
                          onChange: () =>
                              setState(() => _showBrandPicker = true),
                        ),
                      ),
                    ] else ...[
                      ExpressiveSheetSection(
                        label: _brandAutoDetected
                            ? context.l10n.brand
                            : context.l10n.unknownBrand,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.l10n.unknownBrandHint,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _brandSearchCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: context.l10n.brandHint,
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
                                      label: context.l10n.other,
                                      monogram: '+',
                                      color: cs.outlineVariant,
                                      onColor: cs.onSurface,
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
                                    onColor: brand.onPrimary,
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
                                decoration: InputDecoration(
                                  hintText: context.l10n.brandNameHint,
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
                        label: context.l10n.color,
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
                                          color: semantic.onFor(color, cs),
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
                        label: context.l10n.preview,
                        child: LoyaltyCardFace(
                          card: LoyaltyCard(
                            id: 'preview',
                            brandName: _nameCtrl.text.trim().isEmpty
                                ? context.l10n.myCard
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
                    label: context.l10n.addTheCard,
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

  Future<void> _importScreenshot() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final controller = MobileScannerController();
    try {
      final capture = await controller.analyzeImage(picked.path);
      final barcode = capture?.barcodes.firstOrNull;
      final value = barcode?.rawValue;
      if (!mounted) return;
      if (value == null || value.isEmpty) {
        showTabbySnack(context, context.l10n.noCodeInImage);
        return;
      }
      _applyScan(LoyaltyScanPayload(
        value: value,
        isQrCode: _isLoyaltyQr(barcode!.format),
      ));
    } finally {
      controller.dispose();
    }
  }

  void _showManualInput(BuildContext context) {
    final ctrl = TextEditingController(text: _codeValue);
    showTabbyFormDialog<void>(
      context: context,
      builder: (ctx) => TabbyFormDialog(
        title: ctx.l10n.enterCode,
        submitLabel: ctx.l10n.ok,
        cancelLabel: ctx.l10n.cancel,
        onSubmit: () {
          final v = ctrl.text.trim();
          if (v.isNotEmpty) _applyManualCode(v);
          Navigator.pop(ctx);
        },
        child: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: ctx.l10n.codeExample,
          ),
        ),
      ),
    ).whenComplete(ctrl.dispose);
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
              color: brand.logoBackground,
              shape: BoxShape.circle,
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
                  context.l10n.recognizedAuto,
                  style: tt.bodySmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(foregroundColor: fg),
            child: Text(context.l10n.edit),
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
    required this.onColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String monogram;
  final Color color;
  final Color onColor;
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
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
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
                  color: onColor,
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
