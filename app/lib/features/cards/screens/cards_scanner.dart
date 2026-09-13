part of 'cards_screen.dart';

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
                    final payload =
                        _payloadFromBarcode(capture.barcodes.firstOrNull);
                    if (payload != null) {
                      _detected = true;
                      widget.onDetected(payload);
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
