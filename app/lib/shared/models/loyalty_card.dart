import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import 'loyalty_brand.dart';

class LoyaltyCard extends Equatable {
  const LoyaltyCard({
    required this.id,
    required this.brandName,
    required this.codeType,
    required this.codeValue,
    required this.color,
    required this.sortOrder,
    this.brandId,
  });

  final String id;
  final String brandName;
  final String codeType; // 'barcode' | 'qrcode'
  final String codeValue;
  final String? color; // hex
  final int sortOrder;
  final String? brandId;

  bool get isBarcode => codeType == 'barcode';

  Color flutterColor({Color? fallback}) {
    final resolved = fallback ?? AppColors.seed;
    if (color == null) return resolved;
    try {
      final hex = color!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return resolved;
    }
  }

  LoyaltyBrand brandFor(Color fallback) {
    final known =
        LoyaltyBrand.byId(brandId) ?? LoyaltyBrand.byName(brandName);
    if (known != null) return known;
    return LoyaltyBrand.custom(
      name: brandName,
      color: flutterColor(fallback: fallback),
    );
  }

  LoyaltyBrand get brand => brandFor(AppColors.seed);

  String get heroTag => 'loyalty-card-$id';

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
        id: json['id'] as String,
        brandName: json['brand_name'] as String,
        codeType: json['code_type'] as String,
        codeValue: json['code_value'] as String,
        color: json['color'] as String?,
        sortOrder: json['sort_order'] as int,
        brandId: json['brand_id'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, brandName, codeType, codeValue, color, sortOrder, brandId];
}
