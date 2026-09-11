import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Wordmark Tabby — SVG monochrome teinté par le [ColorScheme].
///
/// Par défaut [ColorScheme.primary] (Dynamic Color / seed).
class TabbyLogo extends StatelessWidget {
  const TabbyLogo({
    super.key,
    this.height = 28,
    this.color,
  });

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/tabby_color.svg',
      height: height,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );
  }
}
