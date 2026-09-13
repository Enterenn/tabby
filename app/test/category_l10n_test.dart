import 'package:flutter_test/flutter_test.dart';
import 'package:tabby/l10n/app_localizations_en.dart';
import 'package:tabby/l10n/app_localizations_fr.dart';
import 'package:tabby/l10n/l10n.dart';
import 'package:tabby/shared/models/category.dart';

Category _cat({
  required String name,
  required bool isDefault,
  String icon = 'category',
}) =>
    Category(
      id: 'id',
      name: name,
      icon: icon,
      color: '#000000',
      isDefault: isDefault,
      sortOrder: 0,
    );

void main() {
  final en = AppLocalizationsEn();
  final fr = AppLocalizationsFr();

  test('default categories are translated in English', () {
    expect(_cat(name: 'Courses', isDefault: true).localizedName(en), 'Groceries');
    expect(_cat(name: 'Logement', isDefault: true).localizedName(en), 'Housing');
    expect(_cat(name: 'Loyer', isDefault: true).localizedName(en), 'Housing');
    expect(_cat(name: 'Santé', isDefault: true).localizedName(en), 'Health');
    expect(_cat(name: 'Loisirs', isDefault: true).localizedName(en), 'Leisure');
    expect(
      _cat(name: 'Abonnements', isDefault: true).localizedName(en),
      'Subscriptions',
    );
    expect(_cat(name: 'Autre', isDefault: true).localizedName(en), 'Other');
  });

  test('default categories stay French in French', () {
    expect(_cat(name: 'Courses', isDefault: true).localizedName(fr), 'Courses');
    expect(_cat(name: 'Logement', isDefault: true).localizedName(fr), 'Logement');
  });

  test('custom categories keep their stored name', () {
    expect(
      _cat(name: 'Courses', isDefault: false).localizedName(en),
      'Courses',
    );
    expect(
      _cat(name: 'Vet clinic', isDefault: false).localizedName(fr),
      'Vet clinic',
    );
  });

  test('unknown default name falls back to icon', () {
    expect(
      _cat(name: 'Unknown', isDefault: true, icon: 'shopping_cart')
          .localizedName(en),
      'Groceries',
    );
  });
}
