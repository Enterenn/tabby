import '../../l10n/app_localizations.dart';

/// Same wording as the API `PASSWORD_POLICY_ERROR`.
const passwordPolicyError =
    'Password must be at least 8 characters and include a letter, a number and a symbol';

final _letter = RegExp(r'\p{L}', unicode: true);
final _digit = RegExp(r'\d');
final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

bool isPasswordValid(String password) {
  return password.length >= 8 &&
      _letter.hasMatch(password) &&
      _digit.hasMatch(password) &&
      _symbol.hasMatch(password);
}

String? validatePassword(String? value, AppLocalizations l10n) {
  if (value == null || !isPasswordValid(value)) {
    return l10n.passwordPolicy;
  }
  return null;
}
