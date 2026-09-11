import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LoyaltyCard extends Equatable {
  const LoyaltyCard({
    required this.id,
    required this.brandName,
    required this.codeType,
    required this.codeValue,
    required this.color,
    required this.sortOrder,
  });

  final String id;
  final String brandName;
  final String codeType; // 'barcode' | 'qrcode'
  final String codeValue;
  final String? color; // hex
  final int sortOrder;

  bool get isBarcode => codeType == 'barcode';

  Color get flutterColor {
    if (color == null) return AppColors.expressiveViolet;
    try {
      final hex = color!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.expressiveViolet;
    }
  }

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
        id: json['id'] as String,
        brandName: json['brand_name'] as String,
        codeType: json['code_type'] as String,
        codeValue: json['code_value'] as String,
        color: json['color'] as String?,
        sortOrder: json['sort_order'] as int,
      );

  @override
  List<Object?> get props => [id, brandName, codeType, codeValue, color, sortOrder];
}
