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
