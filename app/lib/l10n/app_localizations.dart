import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tabby'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @minPassword.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères, une majuscule, un chiffre et un symbole'**
  String get minPassword;

  /// No description provided for @passwordPolicy.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères min., une majuscule, un chiffre et un symbole'**
  String get passwordPolicy;

  /// No description provided for @me.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get me;

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get you;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau'**
  String get errorNetwork;

  /// No description provided for @errorUnexpected.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue'**
  String get errorUnexpected;

  /// No description provided for @errorRegister.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'inscription'**
  String get errorRegister;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cet email est déjà utilisé'**
  String get errorEmailTaken;

  /// No description provided for @errorInvalidInvite.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get errorInvalidInvite;

  /// No description provided for @errorInviteUsed.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a déjà été utilisé'**
  String get errorInviteUsed;

  /// No description provided for @errorInviteExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré'**
  String get errorInviteExpired;

  /// No description provided for @errorAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Tu es déjà membre de ce groupe'**
  String get errorAlreadyMember;

  /// No description provided for @errorMemberNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Membre introuvable'**
  String get errorMemberNotFound;

  /// No description provided for @errorGroupNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Groupe introuvable'**
  String get errorGroupNotFound;

  /// No description provided for @errorBalanceNotZero.
  ///
  /// In fr, this message translates to:
  /// **'Solde non nul. Réglez vos dettes avant de quitter.'**
  String get errorBalanceNotZero;

  /// No description provided for @errorDelete.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression'**
  String get errorDelete;

  /// No description provided for @errorUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour'**
  String get errorUpdate;

  /// No description provided for @errorCreate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création'**
  String get errorCreate;

  /// No description provided for @errorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée, reconnecte-toi'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Action non autorisée'**
  String get errorForbidden;

  /// No description provided for @errorConflict.
  ///
  /// In fr, this message translates to:
  /// **'Cette action entre en conflit avec l\'état actuel'**
  String get errorConflict;

  /// No description provided for @errorValidation.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides'**
  String get errorValidation;

  /// No description provided for @offlineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion réseau'**
  String get offlineBanner;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @navCards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes'**
  String get navCards;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navAddExpense.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get navAddExpense;

  /// No description provided for @fabClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get fabClose;

  /// No description provided for @fabActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get fabActions;

  /// No description provided for @loginHello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour 👋'**
  String get loginHello;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour accéder à tes groupes'**
  String get loginSubtitle;

  /// No description provided for @loginEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmit;

  /// No description provided for @loginNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? S\'inscrire'**
  String get loginNoAccount;

  /// No description provided for @biometricSetting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par biométrie'**
  String get biometricSetting;

  /// No description provided for @biometricSettingHint.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouille Tabby au lancement, sans retaper le mot de passe.'**
  String get biometricSettingHint;

  /// No description provided for @biometricEnableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la connexion biométrique ?'**
  String get biometricEnableTitle;

  /// No description provided for @biometricEnableBody.
  ///
  /// In fr, this message translates to:
  /// **'Utilise ton empreinte ou Face ID pour ouvrir Tabby. Le jeton reste chiffré sur l\'appareil.'**
  String get biometricEnableBody;

  /// No description provided for @biometricEnableConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get biometricEnableConfirm;

  /// No description provided for @biometricNotNow.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get biometricNotNow;

  /// No description provided for @biometricLockReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouille Tabby'**
  String get biometricLockReason;

  /// No description provided for @biometricUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get biometricUnlock;

  /// No description provided for @biometricFailed.
  ///
  /// In fr, this message translates to:
  /// **'Authentification biométrique échouée'**
  String get biometricFailed;

  /// No description provided for @biometricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune biométrie n\'est configurée sur cet appareil'**
  String get biometricUnavailable;

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins Tabby pour partager tes dépenses'**
  String get registerSubtitle;

  /// No description provided for @registerName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get registerName;

  /// No description provided for @registerSubmit.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get registerSubmit;

  /// No description provided for @registerHasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get registerHasAccount;

  /// No description provided for @yourGroups.
  ///
  /// In fr, this message translates to:
  /// **'Tes groupes'**
  String get yourGroups;

  /// No description provided for @newGroup.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe'**
  String get newGroup;

  /// No description provided for @globalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde global'**
  String get globalBalance;

  /// No description provided for @activeGroups.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 groupe actif} other{{count} groupes actifs}}'**
  String activeGroups(int count);

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue 👋'**
  String get welcome;

  /// No description provided for @homeEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur Nouveau groupe pour commencer'**
  String get homeEmptyHint;

  /// No description provided for @homeGroupsHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur un groupe pour voir les détails'**
  String get homeGroupsHint;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe pour l\'instant'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Utilise Nouveau groupe ci-dessous\npour créer ou rejoindre un groupe !'**
  String get homeEmptyBody;

  /// No description provided for @newGroupSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée un groupe ou rejoins-en un avec un code d\'invitation.'**
  String get newGroupSheetSubtitle;

  /// No description provided for @createGroup.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get createGroup;

  /// No description provided for @createGroupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Lance un groupe et invite tes proches'**
  String get createGroupSubtitle;

  /// No description provided for @joinGroup.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un groupe'**
  String get joinGroup;

  /// No description provided for @joinGroupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entre le code partagé par un ami'**
  String get joinGroupSubtitle;

  /// No description provided for @createGroupHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à ton groupe'**
  String get createGroupHeadline;

  /// No description provided for @createGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Couple, Vacances été, Coloc…'**
  String get createGroupHint;

  /// No description provided for @groupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupName;

  /// No description provided for @createGroupSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer le groupe'**
  String get createGroupSubmit;

  /// No description provided for @joinGroupHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Entrer le code d\'invitation'**
  String get joinGroupHeadline;

  /// No description provided for @joinGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Demande le code d\'invitation à 8 caractères à la personne qui a créé le groupe.'**
  String get joinGroupHint;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code à 8 caractères'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Code à 8 caractères requis'**
  String get inviteCodeRequired;

  /// No description provided for @joinSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinSubmit;

  /// No description provided for @joinedGroup.
  ///
  /// In fr, this message translates to:
  /// **'Tu as rejoint le groupe !'**
  String get joinedGroup;

  /// No description provided for @pinGroup.
  ///
  /// In fr, this message translates to:
  /// **'Épingler sur l\'accueil'**
  String get pinGroup;

  /// No description provided for @unpinGroup.
  ///
  /// In fr, this message translates to:
  /// **'Désépingler de l\'accueil'**
  String get unpinGroup;

  /// No description provided for @editName.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom'**
  String get editName;

  /// No description provided for @leaveGroup.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le groupe'**
  String get leaveGroup;

  /// No description provided for @leaveGroupBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pourrez plus accéder à ce groupe. Cette action est irréversible.'**
  String get leaveGroupBody;

  /// No description provided for @leave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get leave;

  /// No description provided for @deleteGroup.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le groupe'**
  String get deleteGroup;

  /// No description provided for @deleteGroupBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les dépenses seront supprimées. Cette action est irréversible.'**
  String get deleteGroupBody;

  /// No description provided for @groupOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options du groupe'**
  String get groupOptions;

  /// No description provided for @toSettle.
  ///
  /// In fr, this message translates to:
  /// **'À régler'**
  String get toSettle;

  /// No description provided for @addExpense.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get addExpense;

  /// No description provided for @inviteSomeone.
  ///
  /// In fr, this message translates to:
  /// **'Inviter quelqu\'un'**
  String get inviteSomeone;

  /// No description provided for @settle.
  ///
  /// In fr, this message translates to:
  /// **'Régler'**
  String get settle;

  /// No description provided for @confirmSettle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le remboursement'**
  String get confirmSettle;

  /// No description provided for @settleBody.
  ///
  /// In fr, this message translates to:
  /// **'{from} rembourse {amount} € à {to}.'**
  String settleBody(String from, String amount, String to);

  /// No description provided for @settleSaved.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement enregistré ✓'**
  String get settleSaved;

  /// No description provided for @settled.
  ///
  /// In fr, this message translates to:
  /// **'Soldé'**
  String get settled;

  /// No description provided for @joinedOn.
  ///
  /// In fr, this message translates to:
  /// **'Rejoint le {date}'**
  String joinedOn(String date);

  /// No description provided for @expenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get expenses;

  /// No description provided for @expensesCount.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses ({count})'**
  String expensesCount(int count);

  /// No description provided for @noExpensesInGroup.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense pour ce groupe.'**
  String get noExpensesInGroup;

  /// No description provided for @membersCount.
  ///
  /// In fr, this message translates to:
  /// **'Membres ({count})'**
  String membersCount(int count);

  /// No description provided for @editExpense.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense'**
  String get editExpense;

  /// No description provided for @totalExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Total dépenses'**
  String get totalExpenses;

  /// No description provided for @expenseCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 dépense} other{{count} dépenses}}'**
  String expenseCount(int count);

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @expenseNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Courses, resto…'**
  String get expenseNameHint;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @paidBy.
  ///
  /// In fr, this message translates to:
  /// **'Payé par'**
  String get paidBy;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @daysAgoOne.
  ///
  /// In fr, this message translates to:
  /// **'Il y a 1 jour'**
  String get daysAgoOne;

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {days} jours'**
  String daysAgo(int days);

  /// No description provided for @inviteMember.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un membre'**
  String get inviteMember;

  /// No description provided for @inviteCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCodeShare.
  ///
  /// In fr, this message translates to:
  /// **'Partage ce code avec la personne à inviter. Il est valable 24h.'**
  String get inviteCodeShare;

  /// No description provided for @inviteCodeShareShort.
  ///
  /// In fr, this message translates to:
  /// **'Partage ce code avec la personne à inviter.'**
  String get inviteCodeShareShort;

  /// No description provided for @codeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié !'**
  String get codeCopied;

  /// No description provided for @tapToCopy.
  ///
  /// In fr, this message translates to:
  /// **'Tap pour copier'**
  String get tapToCopy;

  /// No description provided for @generateNewCode.
  ///
  /// In fr, this message translates to:
  /// **'Générer un nouveau code'**
  String get generateNewCode;

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backHome;

  /// No description provided for @inviteValid24h.
  ///
  /// In fr, this message translates to:
  /// **'Valable 24h'**
  String get inviteValid24h;

  /// No description provided for @inviteGenerateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer un code.'**
  String get inviteGenerateFailed;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeHint.
  ///
  /// In fr, this message translates to:
  /// **'Clair / sombre au choix. Les couleurs suivent la palette Tabby.'**
  String get themeHint;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer le thème.'**
  String get themeSaveFailed;

  /// No description provided for @themeAppearanceSystem.
  ///
  /// In fr, this message translates to:
  /// **'Apparence système'**
  String get themeAppearanceSystem;

  /// No description provided for @themeAppearanceLight.
  ///
  /// In fr, this message translates to:
  /// **'Apparence claire'**
  String get themeAppearanceLight;

  /// No description provided for @themeAppearanceDark.
  ///
  /// In fr, this message translates to:
  /// **'Apparence sombre'**
  String get themeAppearanceDark;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageHint.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut, celle du téléphone.'**
  String get languageHint;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'appareil'**
  String get languageSystem;

  /// No description provided for @chooseLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get chooseLanguage;

  /// No description provided for @scanFromScreenshot.
  ///
  /// In fr, this message translates to:
  /// **'Importer un screenshot'**
  String get scanFromScreenshot;

  /// No description provided for @noCodeInImage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code-barres ou QR trouvé sur cette image'**
  String get noCodeInImage;

  /// No description provided for @personalization.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation'**
  String get personalization;

  /// No description provided for @recurringExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses récurrentes'**
  String get recurringExpenses;

  /// No description provided for @myCategories.
  ///
  /// In fr, this message translates to:
  /// **'Mes catégories'**
  String get myCategories;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @logoutAction.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get logoutAction;

  /// No description provided for @categoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes catégories'**
  String get categoriesTitle;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie ?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryBody.
  ///
  /// In fr, this message translates to:
  /// **'La catégorie \"{name}\" sera supprimée. Les dépenses associées conserveront leur catégorie.'**
  String deleteCategoryBody(String name);

  /// No description provided for @noCustomCategories.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie personnalisée'**
  String get noCustomCategories;

  /// No description provided for @noCustomCategoriesHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée des catégories depuis l\'écran\nNouvelle dépense'**
  String get noCustomCategoriesHint;

  /// No description provided for @recurringTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses récurrentes'**
  String get recurringTitle;

  /// No description provided for @noRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense récurrente'**
  String get noRecurring;

  /// No description provided for @noRecurringHint.
  ///
  /// In fr, this message translates to:
  /// **'Active « Répéter chaque mois » lors de\nl\'ajout d\'une dépense'**
  String get noRecurringHint;

  /// No description provided for @deleteRecurringTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la récurrence ?'**
  String get deleteRecurringTitle;

  /// No description provided for @deleteRecurringBody.
  ///
  /// In fr, this message translates to:
  /// **'Les dépenses déjà créées ne sont pas supprimées.'**
  String get deleteRecurringBody;

  /// No description provided for @recurringMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuelle'**
  String get recurringMonthly;

  /// No description provided for @recurringYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuelle'**
  String get recurringYearly;

  /// No description provided for @recurringFirstOfMonth.
  ///
  /// In fr, this message translates to:
  /// **'1er du mois'**
  String get recurringFirstOfMonth;

  /// No description provided for @recurringNthOfMonth.
  ///
  /// In fr, this message translates to:
  /// **'{day}e du mois'**
  String recurringNthOfMonth(int day);

  /// No description provided for @budget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @monthTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total du mois'**
  String get monthTotal;

  /// No description provided for @monthBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets du mois'**
  String get monthBudgets;

  /// No description provided for @noBudgetThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget ce mois — fixe un plafond par catégorie.'**
  String get noBudgetThisMonth;

  /// No description provided for @noBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget'**
  String get noBudgetTitle;

  /// No description provided for @noBudgetBody.
  ///
  /// In fr, this message translates to:
  /// **'Fixe un plafond par catégorie pour suivre tes dépenses du mois.'**
  String get noBudgetBody;

  /// No description provided for @budgetThresholdHint.
  ///
  /// In fr, this message translates to:
  /// **'Attention dès 75 % du plafond, dépassé à 100 %.'**
  String get budgetThresholdHint;

  /// No description provided for @budgetActions.
  ///
  /// In fr, this message translates to:
  /// **'Options du budget'**
  String get budgetActions;

  /// No description provided for @newBudget.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau budget'**
  String get newBudget;

  /// No description provided for @allGroups.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get allGroups;

  /// No description provided for @noSpendThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense ce mois'**
  String get noSpendThisMonth;

  /// No description provided for @allExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les dépenses'**
  String get allExpenses;

  /// No description provided for @totalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Total {amount} €'**
  String totalAmount(String amount);

  /// No description provided for @percentOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % du total'**
  String percentOfTotal(String percent);

  /// No description provided for @budgetPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'Budget {amount}/mois'**
  String budgetPerMonth(String amount);

  /// No description provided for @overBudget.
  ///
  /// In fr, this message translates to:
  /// **'Dépassé'**
  String get overBudget;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @spentAmount.
  ///
  /// In fr, this message translates to:
  /// **'{amount} dépensés'**
  String spentAmount(String amount);

  /// No description provided for @remainingAmount.
  ///
  /// In fr, this message translates to:
  /// **'{amount} restants'**
  String remainingAmount(String amount);

  /// No description provided for @overspendAmount.
  ///
  /// In fr, this message translates to:
  /// **'{amount} de dépassement'**
  String overspendAmount(String amount);

  /// No description provided for @editLimit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le plafond'**
  String get editLimit;

  /// No description provided for @deleteBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce budget ?'**
  String get deleteBudgetTitle;

  /// No description provided for @deleteBudgetBody.
  ///
  /// In fr, this message translates to:
  /// **'Le budget \"{name}\" sera supprimé.'**
  String deleteBudgetBody(String name);

  /// No description provided for @editBudget.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le budget'**
  String get editBudget;

  /// No description provided for @monthlyLimit.
  ///
  /// In fr, this message translates to:
  /// **'Plafond mensuel'**
  String get monthlyLimit;

  /// No description provided for @group.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get group;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @chooseGroup.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un groupe'**
  String get chooseGroup;

  /// No description provided for @chooseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une catégorie'**
  String get chooseCategory;

  /// No description provided for @newExpense.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get newExpense;

  /// No description provided for @newExpenseSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisis le montant et les détails ci-dessous'**
  String get newExpenseSubtitle;

  /// No description provided for @chooseAGroup.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un groupe'**
  String get chooseAGroup;

  /// No description provided for @chooseACategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une catégorie'**
  String get chooseACategory;

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get invalidAmount;

  /// No description provided for @splitsMustMatch.
  ///
  /// In fr, this message translates to:
  /// **'La somme des parts doit égaler le montant total'**
  String get splitsMustMatch;

  /// No description provided for @createGroupFirst.
  ///
  /// In fr, this message translates to:
  /// **'Crée d\'abord un groupe pour ajouter une dépense.'**
  String get createGroupFirst;

  /// No description provided for @newFeminine.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle'**
  String get newFeminine;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get optional;

  /// No description provided for @split.
  ///
  /// In fr, this message translates to:
  /// **'Répartition'**
  String get split;

  /// No description provided for @splitEqual.
  ///
  /// In fr, this message translates to:
  /// **'Égale'**
  String get splitEqual;

  /// No description provided for @splitCustom.
  ///
  /// In fr, this message translates to:
  /// **'Perso'**
  String get splitCustom;

  /// No description provided for @scheduleRecurrence.
  ///
  /// In fr, this message translates to:
  /// **'Programmer la récurrence'**
  String get scheduleRecurrence;

  /// No description provided for @splitTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total réparti'**
  String get splitTotal;

  /// No description provided for @repeatMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Répéter chaque mois'**
  String get repeatMonthly;

  /// No description provided for @repeatOnDay.
  ///
  /// In fr, this message translates to:
  /// **'Le {day} de chaque mois'**
  String repeatOnDay(int day);

  /// No description provided for @newCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get newCategory;

  /// No description provided for @newCategorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalise l\'icône et la couleur'**
  String get newCategorySubtitle;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @icon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// No description provided for @createCategory.
  ///
  /// In fr, this message translates to:
  /// **'Créer la catégorie'**
  String get createCategory;

  /// No description provided for @invalid.
  ///
  /// In fr, this message translates to:
  /// **'Invalide'**
  String get invalid;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @myCards.
  ///
  /// In fr, this message translates to:
  /// **'Mes cartes'**
  String get myCards;

  /// No description provided for @noCards.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte'**
  String get noCards;

  /// No description provided for @noCardsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ta première carte de fidélité\navec le bouton ci-dessous'**
  String get noCardsHint;

  /// No description provided for @addCard.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une carte'**
  String get addCard;

  /// No description provided for @showCard.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la carte'**
  String get showCard;

  /// No description provided for @moveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre'**
  String get moveDown;

  /// No description provided for @loyaltyCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte de fidélité'**
  String get loyaltyCard;

  /// No description provided for @barcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres'**
  String get barcode;

  /// No description provided for @qrCode.
  ///
  /// In fr, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @cameraDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la caméra refusé'**
  String get cameraDenied;

  /// No description provided for @centerCode.
  ///
  /// In fr, this message translates to:
  /// **'Centrez le code dans le cadre'**
  String get centerCode;

  /// No description provided for @cancelScan.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le scan'**
  String get cancelScan;

  /// No description provided for @newCard.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte'**
  String get newCard;

  /// No description provided for @newCardScanHint.
  ///
  /// In fr, this message translates to:
  /// **'Scanne le code-barres ou QR de ta carte'**
  String get newCardScanHint;

  /// No description provided for @newCardCheckHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie l\'enseigne détectée'**
  String get newCardCheckHint;

  /// No description provided for @scanMyCard.
  ///
  /// In fr, this message translates to:
  /// **'Scanner ma carte'**
  String get scanMyCard;

  /// No description provided for @enterCodeManually.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code manuellement'**
  String get enterCodeManually;

  /// No description provided for @rescan.
  ///
  /// In fr, this message translates to:
  /// **'Rescanner'**
  String get rescan;

  /// No description provided for @detectedBrand.
  ///
  /// In fr, this message translates to:
  /// **'Enseigne détectée'**
  String get detectedBrand;

  /// No description provided for @brand.
  ///
  /// In fr, this message translates to:
  /// **'Enseigne'**
  String get brand;

  /// No description provided for @unknownBrand.
  ///
  /// In fr, this message translates to:
  /// **'Enseigne non reconnue'**
  String get unknownBrand;

  /// No description provided for @unknownBrandHint.
  ///
  /// In fr, this message translates to:
  /// **'Le code-barres ne contient pas le nom du magasin. Cherche l\'enseigne ci-dessous — on retiendra ce code pour les prochains scans.'**
  String get unknownBrandHint;

  /// No description provided for @brandHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Animalis, Picard…'**
  String get brandHint;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @brandNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'enseigne'**
  String get brandNameHint;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @myCard.
  ///
  /// In fr, this message translates to:
  /// **'Ma carte'**
  String get myCard;

  /// No description provided for @addTheCard.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la carte'**
  String get addTheCard;

  /// No description provided for @editCard.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la carte'**
  String get editCard;

  /// No description provided for @editCardHint.
  ///
  /// In fr, this message translates to:
  /// **'Change le nom ou mets à jour le code'**
  String get editCardHint;

  /// No description provided for @enterCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code'**
  String get enterCode;

  /// No description provided for @codeExample.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 8DD C9Y D9L'**
  String get codeExample;

  /// No description provided for @recognizedAuto.
  ///
  /// In fr, this message translates to:
  /// **'Reconnue automatiquement'**
  String get recognizedAuto;

  /// No description provided for @walletHint.
  ///
  /// In fr, this message translates to:
  /// **'Tape une carte pour la mettre devant · swipe pour parcourir'**
  String get walletHint;

  /// No description provided for @owedToYou.
  ///
  /// In fr, this message translates to:
  /// **'On te doit'**
  String get owedToYou;

  /// No description provided for @youOwe.
  ///
  /// In fr, this message translates to:
  /// **'Tu dois'**
  String get youOwe;

  /// No description provided for @settledBadge.
  ///
  /// In fr, this message translates to:
  /// **'Réglé ✓'**
  String get settledBadge;

  /// No description provided for @owesTo.
  ///
  /// In fr, this message translates to:
  /// **' doit à '**
  String get owesTo;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @personalInfoHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, e-mail et mot de passe'**
  String get personalInfoHint;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @nameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nameLabel;

  /// No description provided for @nameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'2 caractères minimum'**
  String get nameTooShort;

  /// No description provided for @nameTooLong.
  ///
  /// In fr, this message translates to:
  /// **'50 caractères maximum'**
  String get nameTooLong;

  /// No description provided for @passwordSection.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordSection;

  /// No description provided for @currentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @passwordMin8.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères min., une majuscule, un chiffre et un symbole'**
  String get passwordMin8;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get profileSaved;

  /// No description provided for @passwordChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get passwordChanged;

  /// No description provided for @changeAvatar.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changeAvatar;

  /// No description provided for @pickGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get pickGallery;

  /// No description provided for @pickCamera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get pickCamera;

  /// No description provided for @avatarInvalidType.
  ///
  /// In fr, this message translates to:
  /// **'Utilise un fichier JPG, PNG ou WebP'**
  String get avatarInvalidType;

  /// No description provided for @avatarTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'L\'image ne doit pas dépasser 20 Mo'**
  String get avatarTooLarge;

  /// No description provided for @avatarTooSmall.
  ///
  /// In fr, this message translates to:
  /// **'L\'image doit faire au moins 128×128 pixels'**
  String get avatarTooSmall;

  /// No description provided for @avatarTooBig.
  ///
  /// In fr, this message translates to:
  /// **'L\'image ne doit pas dépasser 1024×1024 pixels'**
  String get avatarTooBig;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la photo'**
  String get avatarUploadFailed;

  /// No description provided for @errorWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect'**
  String get errorWrongPassword;

  /// No description provided for @errorNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit faire entre 2 et 50 caractères'**
  String get errorNameLength;

  /// No description provided for @errorPasswordLength.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit faire au moins 8 caractères, avec une majuscule, un chiffre et un symbole'**
  String get errorPasswordLength;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
