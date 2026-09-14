import 'package:flutter/widgets.dart';

import '../core/auth/password_policy.dart';
import '../shared/models/category.dart';
import '../shared/models/expense.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension TabbyL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String l10nError(String? raw) => localizeApiError(l10n, raw);

  /// Nom affiché : traduit pour les catégories par défaut, brut pour les custom.
  String categoryName(Category category) => category.localizedName(l10n);

  String expenseName(Expense expense) => expense.localizedName(l10n);
}

extension CategoryL10n on Category {
  String localizedName(AppLocalizations l10n) {
    if (!isDefault) return name;
    return switch (name) {
      'Logement' || 'Loyer' => l10n.defaultCategoryHousing,
      'Courses' => l10n.defaultCategoryGroceries,
      'Restaurant' => l10n.defaultCategoryRestaurant,
      'Transport' => l10n.defaultCategoryTransport,
      'Loisirs' => l10n.defaultCategoryLeisure,
      'Abonnements' => l10n.defaultCategorySubscriptions,
      'Santé' => l10n.defaultCategoryHealth,
      'Autre' => l10n.defaultCategoryOther,
      'Remboursement' => l10n.defaultCategoryRepayment,
      _ => switch (icon) {
          'home' => l10n.defaultCategoryHousing,
          'shopping_cart' => l10n.defaultCategoryGroceries,
          'restaurant' => l10n.defaultCategoryRestaurant,
          'directions_car' => l10n.defaultCategoryTransport,
          'sports_esports' => l10n.defaultCategoryLeisure,
          'subscriptions' => l10n.defaultCategorySubscriptions,
          'local_hospital' => l10n.defaultCategoryHealth,
          'category' => l10n.defaultCategoryOther,
          'payments' => l10n.defaultCategoryRepayment,
          _ => name,
        },
    };
  }
}

extension ExpenseNameL10n on Expense {
  String localizedName(AppLocalizations l10n) {
    if (name == 'Remboursement' ||
        (category.isDefault && category.name == 'Remboursement')) {
      return l10n.defaultCategoryRepayment;
    }
    return name;
  }
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
    'errorUnauthorized' => l10n.errorUnauthorized,
    'errorForbidden' => l10n.errorForbidden,
    'errorConflict' => l10n.errorConflict,
    'A repayment is already waiting for confirmation' =>
      l10n.errorSettlePending,
    'Only the reimbursed member can confirm' => l10n.errorForbidden,
    'errorValidation' => l10n.errorValidation,
    'Invalid email or password' => l10n.errorInvalidCredentials,
    'expenseGroupRequired' => l10n.expenseGroupRequired,
    'expenseNameRequired' => l10n.expenseNameRequired,
    'expenseAmountInvalid' => l10n.expenseAmountInvalid,
    'expenseCategoryRequired' => l10n.expenseCategoryRequired,
    'expensePayerRequired' => l10n.expensePayerRequired,
    'expenseSplitsRequired' => l10n.expenseSplitsRequired,
    'expenseSplitsDuplicate' => l10n.expenseSplitsDuplicate,
    'expenseSplitsMismatch' => l10n.expenseSplitsMismatch,
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
