import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';

/// Avatar circulaire M3 Expressive.
class ExpressiveAvatar extends StatelessWidget {
  const ExpressiveAvatar({
    super.key,
    required this.label,
    this.size = 40,
    this.color,
    this.textColor,
    this.borderColor,
    this.imageUrl,
  });

  final String label;
  final double size;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final shapes = context.tabbyShapes;
    final bg = color ?? cs.primary;
    final fg = textColor ?? cs.onPrimary;
    final display = label.isNotEmpty ? label[0].toUpperCase() : '?';

    Widget initials() => Center(
          child: Text(
            display,
            style: TabbyTypographyTokens.flex(
              fontSize: size * 0.42,
              wght: 800,
              rond: 0,
              color: fg,
            ),
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: bg,
        elevation: 0,
        shape: shapes.circle(
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl == null
            ? initials()
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => initials(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.35,
                      height: size * 0.35,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Pile d'avatars circulaires avec chevauchement.
class ExpressiveAvatarStack extends StatelessWidget {
  const ExpressiveAvatarStack({
    super.key,
    required this.names,
    this.imageUrls,
    this.size = 36,
    this.overlap = 10,
    this.maxDisplayed = 4,
  });

  final List<String> names;
  final List<String?>? imageUrls;
  final double size;
  final double overlap;
  final int maxDisplayed;

  @override
  Widget build(BuildContext context) {
    final cs = context.tabbyColors;
    final palette = context.tabbySemantic.avatarPalette;
    final displayed = names.take(maxDisplayed).toList();
    final extra = names.length - displayed.length;
    final total = displayed.length + (extra > 0 ? 1 : 0);
    final width = size + (total - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          ...displayed.asMap().entries.map((e) {
            return Positioned(
              left: e.key * (size - overlap),
              child: ExpressiveAvatar(
                label: e.value,
                size: size,
                color: palette[e.key % palette.length],
                borderColor: cs.surfaceContainerHighest,
                imageUrl: imageUrls != null && e.key < imageUrls!.length
                    ? imageUrls![e.key]
                    : null,
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: displayed.length * (size - overlap),
              child: ExpressiveAvatar(
                label: '+$extra',
                size: size,
                color: cs.surfaceContainerHighest,
                textColor: cs.onSurfaceVariant,
                borderColor: cs.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}
