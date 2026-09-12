import 'package:material_ui/material_ui.dart';

/// Spinner de page — centré, tokens M3 du thème.
class TabbyLoading extends StatelessWidget {
  const TabbyLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
