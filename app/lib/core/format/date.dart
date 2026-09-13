import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

/// Date locale (`13/09/2026` en fr, `9/13/2026` en en).
String formatDisplayDate(BuildContext context, DateTime date) {
  return DateFormat.yMd(Localizations.localeOf(context).toString()).format(date);
}

/// Aujourd’hui / il y a 1 jour / il y a N jours.
String formatRelativeDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;

  if (days <= 0) return context.l10n.today;
  if (days == 1) return context.l10n.daysAgoOne;
  return context.l10n.daysAgo(days);
}
