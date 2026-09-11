import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.sortOrder,
  });

  final String id;
  final String name;
  /// Emoji ou nom d'icône legacy (ex. '🏠' ou 'home').
  final String icon;
  /// Couleur hex (ex. '#E67E22').
  final String color;
  final bool isDefault;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        isDefault: json['is_default'] as bool,
        sortOrder: json['sort_order'] as int,
      );

  Color get flutterColor {
    final code = color.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  /// True si le champ icon contient un emoji (non-ASCII).
  bool get isEmoji => !_iconMap.containsKey(icon);

  IconData get flutterIcon => _iconMap[icon] ?? Symbols.category_rounded;

  /// Widget à afficher partout pour l'icône : emoji ou Material icon.
  Widget iconWidget({double size = 20, Color? color}) {
    if (isEmoji) {
      return Text(icon, style: TextStyle(fontSize: size * 1.1));
    }
    return Icon(flutterIcon, size: size, color: color);
  }

  static const _iconMap = <String, IconData>{
    'home': Symbols.home_rounded,
    'shopping_cart': Symbols.shopping_cart_rounded,
    'restaurant': Symbols.restaurant_rounded,
    'directions_car': Symbols.directions_car_rounded,
    'sports_esports': Symbols.sports_esports_rounded,
    'subscriptions': Symbols.subscriptions_rounded,
    'local_hospital': Symbols.local_hospital_rounded,
    'category': Symbols.category_rounded,
    'pets': Symbols.pets_rounded,
    'school': Symbols.school_rounded,
    'flight': Symbols.flight_rounded,
    'hotel': Symbols.hotel_rounded,
    'fitness_center': Symbols.fitness_center_rounded,
    'phone': Symbols.phone_rounded,
    'shopping_bag': Symbols.shopping_bag_rounded,
    'local_gas_station': Symbols.local_gas_station_rounded,
  };

  @override
  List<Object?> get props => [id, name, icon, color, isDefault, sortOrder];
}
