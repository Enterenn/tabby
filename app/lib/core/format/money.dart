import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatMoney(
  BuildContext context,
  num amount, {
  int decimalDigits = 2,
}) {
  return NumberFormat.currency(
    locale: Localizations.localeOf(context).toString(),
    symbol: '€',
    decimalDigits: decimalDigits,
  ).format(amount);
}

/// Solde signé — `+12,34 €` / `-12,34 €` / `0,00 €`.
String formatSignedMoney(
  BuildContext context,
  num amount, {
  int decimalDigits = 2,
}) {
  final formatted = formatMoney(
    context,
    amount.abs(),
    decimalDigits: decimalDigits,
  );
  if (amount.abs() < 0.01) return formatted;
  return amount > 0 ? '+$formatted' : '-$formatted';
}
