import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/loyalty_card.dart';
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Symbols.add_rounded, fill: 1),
            label: const Text('Ajouter'),
          ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.credit_card_rounded,
                        size: 56, color: cs.outlineVariant),
                    const SizedBox(height: 16),
                    Text('Aucune carte', style: tt.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Appuie sur + pour ajouter\nta première carte de fidélité',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            CardsLoaded(:final cards) => ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
    final cs = Theme.of(context).colorScheme;
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      card.brandName.isNotEmpty
                          ? card.brandName[0].toUpperCase()
                          : '?',
                      style: tt.titleLarge?.copyWith(
                        color: cardColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Symbols.fullscreen_rounded),
                title: const Text('Afficher la carte'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFullScreen(context);
                },
              ),
              ListTile(
                leading:
                    Icon(Symbols.delete_rounded, color: cs.error),
                title: Text('Supprimer',
                    style: TextStyle(color: cs.error)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(card.brandName,
            style: const TextStyle(color: Colors.black87)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Marque
              Text(
                card.brandName,
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 40),

              // Code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: card.isBarcode
                    ? bw.BarcodeWidget(
                        barcode: bw.Barcode.code128(),
                        data: card.codeValue,
                        width: double.infinity,
                        height: 100,
                        drawText: true,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      )
                    : bw.BarcodeWidget(
                        barcode: bw.Barcode.qrCode(),
                        data: card.codeValue,
                        width: 200,
                        height: 200,
                      ),
              ),

              const SizedBox(height: 32),
              Text(
                card.codeValue,
                style: tt.bodyMedium
                    ?.copyWith(color: Colors.black54, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                card.isBarcode ? 'Code-barres' : 'QR Code',
                style: tt.bodySmall?.copyWith(color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
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
  Color _selectedColor = AppColors.categoryPalette[4];
  bool _scanning = false;
  bool _loading = false;

  static const _colors = [
    Color(0xFF5C6BC0), Color(0xFFEC407A), Color(0xFF26A69A),
    Color(0xFFEF5350), Color(0xFFFF7043), Color(0xFF66BB6A),
    Color(0xFFAB47BC), Color(0xFF42A5F5), Color(0xFFFFCA28),
    Color(0xFF8D6E63),
  ];

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Nouvelle carte', style: tt.headlineSmall),
            const SizedBox(height: 20),

            // Nom de la marque
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: 'Nom de la marque'),
              autofocus: true,
            ),
            const SizedBox(height: 20),

            // Type de code
            Text('Type de code', style: tt.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'barcode',
                  icon: Icon(Symbols.barcode_rounded),
                  label: Text('Code-barres'),
                ),
                ButtonSegment(
                  value: 'qrcode',
                  icon: Icon(Symbols.qr_code_rounded),
                  label: Text('QR Code'),
                ),
              ],
              selected: {_codeType},
              onSelectionChanged: (s) =>
                  setState(() => _codeType = s.first),
            ),
            const SizedBox(height: 20),

            // Scanner ou saisie manuelle
            if (_scanning)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      final value = barcodes.first.rawValue;
                      if (value != null && value.isNotEmpty) {
                        setState(() {
                          _codeValue = value;
                          _scanning = false;
                        });
                      }
                    },
                  ),
                ),
              )
            else ...[
              if (_codeValue.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _codeType == 'barcode'
                            ? Symbols.barcode_rounded
                            : Symbols.qr_code_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
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
                        icon: const Icon(Symbols.close_rounded, size: 18),
                        onPressed: () =>
                            setState(() => _codeValue = ''),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _scanning = true),
                      icon: const Icon(Symbols.photo_camera_rounded),
                      label: Text(_codeValue.isEmpty
                          ? 'Scanner'
                          : 'Rescanner'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showManualInput(context),
                      icon: const Icon(Symbols.edit_rounded),
                      label: const Text('Saisir'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Couleur
            Text('Couleur', style: tt.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? cs.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Symbols.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            FilledButton(
              onPressed: (_loading ||
                      _nameCtrl.text.trim().isEmpty ||
                      _codeValue.isEmpty)
                  ? null
                  : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Ajouter la carte'),
            ),
          ],
        ),
      ),
    );
  }

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
