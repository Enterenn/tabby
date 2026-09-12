import 'package:flutter/widgets.dart';

import '../core/auth/password_policy.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension TabbyL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String l10nError(String? raw) => localizeApiError(l10n, raw);
}

String localizeApiError(AppLocalizations l10n, String? raw) {
  if (raw == null || raw.isEmpty) return l10n.errorGeneric;
  if (raw.startsWith('Erreur inattendue') ||
      raw.startsWith('Unexpected error')) {
    return l10n.errorUnexpected;
  }
  if (raw.startsWith('Solde non nul') || raw.startsWith('Balance is not zero')) {
    return l10n.errorBalanceNotZero;
  }
  return switch (raw) {
    'errorNetwork' || 'Erreur réseau' => l10n.errorNetwork,
    'errorGeneric' || 'Erreur' => l10n.errorGeneric,
    'errorRegister' || "Erreur lors de l'inscription" => l10n.errorRegister,
    'errorUnexpected' => l10n.errorUnexpected,
    'errorDelete' || 'Erreur lors de la suppression' => l10n.errorDelete,
    'errorUpdate' || 'Erreur lors de la mise à jour' => l10n.errorUpdate,
    'errorCreate' || 'Erreur lors de la création' => l10n.errorCreate,
    'Invalid email or password' => l10n.errorInvalidCredentials,
    'Email already registered' => l10n.errorEmailTaken,
    'Invalid invite code' => l10n.errorInvalidInvite,
    'Invite already used' => l10n.errorInviteUsed,
    'Invite expired' => l10n.errorInviteExpired,
    'Already a member' => l10n.errorAlreadyMember,
    'Member not found' => l10n.errorMemberNotFound,
    'Group not found' => l10n.errorGroupNotFound,
    'Current password is incorrect' => l10n.errorWrongPassword,
    'Name must be 2-50 characters' => l10n.errorNameLength,
    'File must be JPEG or PNG' ||
    'File must be JPEG, PNG or WebP' => l10n.avatarInvalidType,
    'File exceeds 5 MB' ||
    'File exceeds 20 MB' => l10n.avatarTooLarge,
    'Image must be at least 128x128' => l10n.avatarTooSmall,
    'Image must be at most 1024x1024' => l10n.avatarTooBig,
    'avatarUploadFailed' => l10n.avatarUploadFailed,
    passwordPolicyError ||
    'errorPasswordLength' => l10n.passwordPolicy,
    _ => raw,
  };
}
