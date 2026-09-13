part of 'cards_screen.dart';
// ─── Full-screen card display ─────────────────────────────────────────────────

class _CardFullScreen extends StatelessWidget {
  const _CardFullScreen({
    required this.card,
    this.onEdit,
    this.onDelete,
  });
  final LoyaltyCard card;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: context.l10n.edit,
              onPressed: onEdit,
              icon: const Icon(Symbols.edit_rounded),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: context.l10n.delete,
              onPressed: onDelete,
              icon: Icon(Symbols.delete_rounded, color: cs.error),
            ),
        ],
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
                  child: LoyaltyMachineCode(card: card),
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
                  card.renderedCode,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
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

LoyaltyScanPayload? _payloadFromBarcode(Barcode? barcode) {
  if (barcode == null) return null;
  final value = LoyaltyCodeValue.fromScan(
    rawValue: barcode.rawValue,
    displayValue: barcode.displayValue,
  );
  if (value.isEmpty) return null;
  return LoyaltyScanPayload(
    value: value,
    isQrCode: _isLoyaltyQr(barcode.format),
  );
}
