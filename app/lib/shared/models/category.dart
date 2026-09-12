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
  /// Identifiant Material Symbols (ex. 'home') ou ancien emoji.
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

  /// Hex DB, ou gris si le code est invalide.
  Color get resolvedColor {
    try {
      return flutterColor;
    } catch (_) {
      return const Color(0xFF888888);
    }
  }

  Color get onResolvedColor =>
      resolvedColor.computeLuminance() > 0.55
          ? const Color(0xFF1C1B1F)
          : const Color(0xFFFFFFFF);

  IconData get flutterIcon => CategoryIcons.resolve(icon);

  Widget iconWidget({double size = 20, Color? color, double fill = 0}) {
    return Icon(flutterIcon, size: size, color: color, fill: fill);
  }

  @override
  List<Object?> get props => [id, name, icon, color, isDefault, sortOrder];
}

/// Catalogue d'icônes Material Symbols pour les catégories.
abstract final class CategoryIcons {
  static const List<(String id, IconData icon)> all = [
    ('home', Symbols.home_rounded),
    ('apartment', Symbols.apartment_rounded),
    ('shopping_cart', Symbols.shopping_cart_rounded),
    ('shopping_bag', Symbols.shopping_bag_rounded),
    ('storefront', Symbols.storefront_rounded),
    ('restaurant', Symbols.restaurant_rounded),
    ('local_cafe', Symbols.local_cafe_rounded),
    ('liquor', Symbols.liquor_rounded),
    ('bakery_dining', Symbols.bakery_dining_rounded),
    ('directions_car', Symbols.directions_car_rounded),
    ('directions_bus', Symbols.directions_bus_rounded),
    ('directions_bike', Symbols.directions_bike_rounded),
    ('flight', Symbols.flight_rounded),
    ('local_gas_station', Symbols.local_gas_station_rounded),
    ('sports_esports', Symbols.sports_esports_rounded),
    ('sports_soccer', Symbols.sports_soccer_rounded),
    ('movie', Symbols.movie_rounded),
    ('music_note', Symbols.music_note_rounded),
    ('theater_comedy', Symbols.theater_comedy_rounded),
    ('subscriptions', Symbols.subscriptions_rounded),
    ('live_tv', Symbols.live_tv_rounded),
    ('local_hospital', Symbols.local_hospital_rounded),
    ('vaccines', Symbols.vaccines_rounded),
    ('fitness_center', Symbols.fitness_center_rounded),
    ('spa', Symbols.spa_rounded),
    ('school', Symbols.school_rounded),
    ('work', Symbols.work_rounded),
    ('pets', Symbols.pets_rounded),
    ('child_care', Symbols.child_care_rounded),
    ('phone', Symbols.phone_rounded),
    ('wifi', Symbols.wifi_rounded),
    ('bolt', Symbols.bolt_rounded),
    ('water_drop', Symbols.water_drop_rounded),
    ('local_laundry_service', Symbols.local_laundry_service_rounded),
    ('cleaning_services', Symbols.cleaning_services_rounded),
    ('hotel', Symbols.hotel_rounded),
    ('beach_access', Symbols.beach_access_rounded),
    ('card_giftcard', Symbols.card_giftcard_rounded),
    ('cake', Symbols.cake_rounded),
    ('payments', Symbols.payments_rounded),
    ('account_balance', Symbols.account_balance_rounded),
    ('savings', Symbols.savings_rounded),
    ('category', Symbols.category_rounded),
  ];

  static const Map<String, String> _emojiToId = {
    '🏠': 'home',
    '🛒': 'shopping_cart',
    '🍽️': 'restaurant',
    '🍕': 'restaurant',
    '🍔': 'restaurant',
    '🍜': 'restaurant',
    '🍣': 'restaurant',
    '☕': 'local_cafe',
    '🍺': 'liquor',
    '🚗': 'directions_car',
    '✈️': 'flight',
    '🚲': 'directions_bike',
    '⛽': 'local_gas_station',
    '🎮': 'sports_esports',
    '🎬': 'movie',
    '🎵': 'music_note',
    '📺': 'live_tv',
    '🏥': 'local_hospital',
    '💊': 'vaccines',
    '🏋️': 'fitness_center',
    '🎓': 'school',
    '🐾': 'pets',
    '🐶': 'pets',
    '🐱': 'pets',
    '📞': 'phone',
    '💡': 'bolt',
    '🚿': 'water_drop',
    '🧹': 'cleaning_services',
    '🏨': 'hotel',
    '🏖️': 'beach_access',
    '🎁': 'card_giftcard',
    '💰': 'payments',
    '📦': 'category',
  };

  static final Map<String, IconData> _byId = {
    for (final e in all) e.$1: e.$2,
  };

  static IconData resolve(String raw) {
    final id = _byId.containsKey(raw) ? raw : (_emojiToId[raw] ?? 'category');
    return _byId[id] ?? Symbols.category_rounded;
  }
}
