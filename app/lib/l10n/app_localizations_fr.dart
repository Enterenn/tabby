// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Tabby';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get close => 'Fermer';

  @override
  String get delete => 'Supprimer';

  @override
  String get create => 'Créer';

  @override
  String get edit => 'Modifier';

  @override
  String get requiredField => 'Champ requis';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get minPassword =>
      '8 caractères, une majuscule, un chiffre et un symbole';

  @override
  String get passwordPolicy =>
      '8 caractères min., une majuscule, un chiffre et un symbole';

  @override
  String get me => 'Moi';

  @override
  String get you => 'Vous';

  @override
  String get admin => 'Admin';

  @override
  String get ok => 'OK';

  @override
  String get errorGeneric => 'Erreur';

  @override
  String get errorNetwork => 'Erreur réseau';

  @override
  String get errorUnexpected => 'Erreur inattendue';

  @override
  String get errorRegister => 'Erreur lors de l\'inscription';

  @override
  String get errorInvalidCredentials => 'Email ou mot de passe incorrect';

  @override
  String get errorEmailTaken => 'Cet email est déjà utilisé';

  @override
  String get errorInvalidInvite => 'Code invalide';

  @override
  String get errorInviteUsed => 'Ce code a déjà été utilisé';

  @override
  String get errorInviteExpired => 'Ce code a expiré';

  @override
  String get errorAlreadyMember => 'Tu es déjà membre de ce groupe';

  @override
  String get errorMemberNotFound => 'Membre introuvable';

  @override
  String get errorGroupNotFound => 'Groupe introuvable';

  @override
  String get errorBalanceNotZero =>
      'Solde non nul. Réglez vos dettes avant de quitter.';

  @override
  String get errorDelete => 'Erreur lors de la suppression';

  @override
  String get errorUpdate => 'Erreur lors de la mise à jour';

  @override
  String get errorCreate => 'Erreur lors de la création';

  @override
  String get errorUnauthorized => 'Session expirée, reconnecte-toi';

  @override
  String get errorForbidden => 'Action non autorisée';

  @override
  String get errorConflict =>
      'Cette action entre en conflit avec l\'état actuel';

  @override
  String get errorValidation => 'Données invalides';

  @override
  String get offlineBanner => 'Pas de connexion réseau';

  @override
  String get navHome => 'Accueil';

  @override
  String get navBudget => 'Budget';

  @override
  String get navCards => 'Cartes';

  @override
  String get navProfile => 'Profil';

  @override
  String get navAddExpense => 'Ajouter une dépense';

  @override
  String get fabClose => 'Fermer';

  @override
  String get fabActions => 'Actions';

  @override
  String get loginHello => 'Bonjour 👋';

  @override
  String get loginSubtitle => 'Connecte-toi pour accéder à tes groupes';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get loginNoAccount => 'Pas encore de compte ? S\'inscrire';

  @override
  String get biometricSetting => 'Connexion par biométrie';

  @override
  String get biometricSettingHint =>
      'Déverrouille Tabby au lancement, sans retaper le mot de passe.';

  @override
  String get biometricEnableTitle => 'Activer la connexion biométrique ?';

  @override
  String get biometricEnableBody =>
      'Utilise ton empreinte ou Face ID pour ouvrir Tabby. Le jeton reste chiffré sur l\'appareil.';

  @override
  String get biometricEnableConfirm => 'Activer';

  @override
  String get biometricNotNow => 'Plus tard';

  @override
  String get biometricLockReason => 'Déverrouille Tabby';

  @override
  String get biometricUnlock => 'Déverrouiller';

  @override
  String get biometricFailed => 'Authentification biométrique échouée';

  @override
  String get biometricUnavailable =>
      'Aucune biométrie n\'est configurée sur cet appareil';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get registerSubtitle => 'Rejoins Tabby pour partager tes dépenses';

  @override
  String get registerName => 'Prénom';

  @override
  String get registerSubmit => 'S\'inscrire';

  @override
  String get registerHasAccount => 'Déjà un compte ? Se connecter';

  @override
  String get yourGroups => 'Tes groupes';

  @override
  String get newGroup => 'Nouveau groupe';

  @override
  String get globalBalance => 'Solde global';

  @override
  String activeGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groupes actifs',
      one: '1 groupe actif',
    );
    return '$_temp0';
  }

  @override
  String get welcome => 'Bienvenue 👋';

  @override
  String get homeEmptyHint => 'Appuie sur Nouveau groupe pour commencer';

  @override
  String get homeGroupsHint => 'Appuie sur un groupe pour voir les détails';

  @override
  String get homeEmptyTitle => 'Aucun groupe pour l\'instant';

  @override
  String get homeEmptyBody =>
      'Utilise Nouveau groupe ci-dessous\npour créer ou rejoindre un groupe !';

  @override
  String get newGroupSheetSubtitle =>
      'Crée un groupe ou rejoins-en un avec un code d\'invitation.';

  @override
  String get createGroup => 'Créer un groupe';

  @override
  String get createGroupSubtitle => 'Lance un groupe et invite tes proches';

  @override
  String get joinGroup => 'Rejoindre un groupe';

  @override
  String get joinGroupSubtitle => 'Entre le code partagé par un ami';

  @override
  String get createGroupHeadline => 'Donne un nom à ton groupe';

  @override
  String get createGroupHint => 'Ex. Couple, Vacances été, Coloc…';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get createGroupSubmit => 'Créer le groupe';

  @override
  String get joinGroupHeadline => 'Entrer le code d\'invitation';

  @override
  String get joinGroupHint =>
      'Demande le code d\'invitation à 8 caractères à la personne qui a créé le groupe.';

  @override
  String get inviteCodeLabel => 'Code à 8 caractères';

  @override
  String get inviteCodeRequired => 'Code à 8 caractères requis';

  @override
  String get joinSubmit => 'Rejoindre';

  @override
  String get joinedGroup => 'Tu as rejoint le groupe !';

  @override
  String get pinGroup => 'Épingler sur l\'accueil';

  @override
  String get unpinGroup => 'Désépingler de l\'accueil';

  @override
  String get editName => 'Modifier le nom';

  @override
  String get leaveGroup => 'Quitter le groupe';

  @override
  String get leaveGroupBody =>
      'Vous ne pourrez plus accéder à ce groupe. Cette action est irréversible.';

  @override
  String get leave => 'Quitter';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String get deleteGroupBody =>
      'Toutes les dépenses seront supprimées. Cette action est irréversible.';

  @override
  String get groupOptions => 'Options du groupe';

  @override
  String get toSettle => 'À régler';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get inviteSomeone => 'Inviter quelqu\'un';

  @override
  String get settle => 'Régler';

  @override
  String get confirmSettle => 'Confirmer le remboursement';

  @override
  String settleBody(String from, String amount, String to) {
    return '$from rembourse $amount € à $to.';
  }

  @override
  String get settleSaved => 'Remboursement enregistré ✓';

  @override
  String get settlePending => 'En attente de confirmation';

  @override
  String get repaymentPending => 'En attente';

  @override
  String get confirmRepayment => 'Confirmer le remboursement';

  @override
  String get repaymentConfirmed => 'Remboursement confirmé ✓';

  @override
  String get errorSettlePending =>
      'Un remboursement est déjà en attente de confirmation.';

  @override
  String get settled => 'Soldé';

  @override
  String joinedOn(String date) {
    return 'Rejoint le $date';
  }

  @override
  String get expenses => 'Dépenses';

  @override
  String expensesCount(int count) {
    return 'Dépenses ($count)';
  }

  @override
  String get noExpensesInGroup => 'Aucune dépense pour ce groupe.';

  @override
  String membersCount(int count) {
    return 'Membres ($count)';
  }

  @override
  String get editExpense => 'Modifier la dépense';

  @override
  String get totalExpenses => 'Total du groupe';

  @override
  String get yourShare => 'Tes dépenses';

  @override
  String yourShareAmount(String amount) {
    return 'Toi : $amount €';
  }

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses',
      one: '1 dépense',
    );
    return '$_temp0';
  }

  @override
  String get description => 'Description';

  @override
  String get expenseNameHint => 'Courses, resto…';

  @override
  String get amount => 'Montant';

  @override
  String get paidBy => 'Payé par';

  @override
  String paidByPerson(String name) {
    return 'Payé par $name';
  }

  @override
  String get participants => 'Participants';

  @override
  String get date => 'Date';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get daysAgoOne => 'Il y a 1 jour';

  @override
  String daysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String get inviteMember => 'Inviter un membre';

  @override
  String get inviteCodeTitle => 'Code d\'invitation';

  @override
  String get inviteCodeShare =>
      'Partage ce code avec la personne à inviter. Il est valable 24h.';

  @override
  String get inviteCodeShareShort =>
      'Partage ce code avec la personne à inviter.';

  @override
  String get codeCopied => 'Code copié !';

  @override
  String get tapToCopy => 'Tap pour copier';

  @override
  String get generateNewCode => 'Générer un nouveau code';

  @override
  String get backHome => 'Retour à l\'accueil';

  @override
  String get inviteValid24h => 'Valable 24h';

  @override
  String get inviteGenerateFailed => 'Impossible de générer un code.';

  @override
  String get profile => 'Profil';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get themeHint =>
      'Clair / sombre au choix. Les couleurs suivent la palette Tabby.';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSaveFailed => 'Impossible d\'enregistrer le thème.';

  @override
  String get themeAppearanceSystem => 'Apparence système';

  @override
  String get themeAppearanceLight => 'Apparence claire';

  @override
  String get themeAppearanceDark => 'Apparence sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageHint => 'Par défaut, celle du téléphone.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Langue de l\'appareil';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get scanFromScreenshot => 'Importer un screenshot';

  @override
  String get noCodeInImage => 'Aucun code-barres ou QR trouvé sur cette image';

  @override
  String get personalization => 'Personnalisation';

  @override
  String get recurringExpenses => 'Dépenses récurrentes';

  @override
  String get myCategories => 'Mes catégories';

  @override
  String get account => 'Compte';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirm => 'Se déconnecter ?';

  @override
  String get logoutAction => 'Déconnecter';

  @override
  String get categoriesTitle => 'Mes catégories';

  @override
  String get deleteCategoryTitle => 'Supprimer la catégorie ?';

  @override
  String deleteCategoryBody(String name) {
    return 'La catégorie \"$name\" sera supprimée. Les dépenses associées conserveront leur catégorie.';
  }

  @override
  String get noCustomCategories => 'Aucune catégorie personnalisée';

  @override
  String get noCustomCategoriesHint =>
      'Crée des catégories depuis l\'écran\nNouvelle dépense';

  @override
  String get recurringTitle => 'Dépenses récurrentes';

  @override
  String get noRecurring => 'Aucune dépense récurrente';

  @override
  String get noRecurringHint =>
      'Active « Répéter chaque mois » en ajoutant\nune dépense partagée ou Pour moi.';

  @override
  String get deleteRecurringTitle => 'Supprimer la récurrence ?';

  @override
  String get deleteRecurringBody =>
      'Les dépenses déjà créées ne sont pas supprimées.';

  @override
  String get recurringMonthly => 'Mensuelle';

  @override
  String get recurringYearly => 'Annuelle';

  @override
  String get recurringFirstOfMonth => '1er du mois';

  @override
  String recurringNthOfMonth(int day) {
    return '${day}e du mois';
  }

  @override
  String get budget => 'Budget';

  @override
  String get monthTotal => 'Ta part ce mois-ci';

  @override
  String get yourShareLegend => 'Uniquement ta part des dépenses partagées.';

  @override
  String get shareLegendAll => 'Ta part des groupes et tes dépenses pour toi.';

  @override
  String get shareLegendGroups => 'Uniquement ta part des dépenses partagées.';

  @override
  String get shareLegendPersonal => 'Uniquement tes dépenses pour toi.';

  @override
  String get scopeAll => 'Tout';

  @override
  String get scopeGroups => 'Groupes';

  @override
  String get scopePersonal => 'Pour moi';

  @override
  String get personalPurchases => 'Tes achats';

  @override
  String get noPersonalPurchases => 'Aucun achat Pour moi ce mois';

  @override
  String get noPersonalPurchasesHint => 'Le + au milieu, puis Pour moi.';

  @override
  String get deletePersonalTitle => 'Supprimer cet achat ?';

  @override
  String deletePersonalBody(String name) {
    return '« $name » sera retiré de ton budget.';
  }

  @override
  String get expenseShared => 'Partagée';

  @override
  String get expenseForMe => 'Pour moi';

  @override
  String get categoryNamePrivacyHint =>
      'Le nom est à toi. S’il est utilisé sur une dépense partagée, les membres du groupe le verront — pas tes achats Pour moi.';

  @override
  String get monthBudgets => 'Budgets du mois';

  @override
  String get noBudgetThisMonth =>
      'Aucun budget ce mois — fixe un plafond par catégorie.';

  @override
  String get noBudgetTitle => 'Aucun budget';

  @override
  String get noBudgetBody =>
      'Fixe un plafond par catégorie pour suivre tes dépenses du mois.';

  @override
  String get budgetThresholdHint =>
      'Attention dès 75 % du plafond, dépassé à 100 %.';

  @override
  String get budgetActions => 'Options du budget';

  @override
  String get newBudget => 'Nouveau budget';

  @override
  String get allGroups => 'Tous';

  @override
  String get allGroupsMenu => 'Tous les groupes';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get myExpenses => 'Mes dépenses';

  @override
  String get noPersonalPurchasesYet => 'Aucun achat Pour moi';

  @override
  String get noSpendThisMonth => 'Aucune dépense ce mois';

  @override
  String get allExpenses => 'Toutes les dépenses';

  @override
  String totalAmount(String amount) {
    return 'Total $amount €';
  }

  @override
  String percentOfTotal(String percent) {
    return '$percent % du total';
  }

  @override
  String budgetPerMonth(String amount) {
    return 'Budget $amount/mois';
  }

  @override
  String get overBudget => 'Dépassé';

  @override
  String get warning => 'Attention';

  @override
  String spentAmount(String amount) {
    return '$amount dépensés';
  }

  @override
  String remainingAmount(String amount) {
    return '$amount restants';
  }

  @override
  String overspendAmount(String amount) {
    return '$amount de dépassement';
  }

  @override
  String get editLimit => 'Modifier le plafond';

  @override
  String get deleteBudgetTitle => 'Supprimer ce budget ?';

  @override
  String deleteBudgetBody(String name) {
    return 'Le budget \"$name\" sera supprimé.';
  }

  @override
  String get editBudget => 'Modifier le budget';

  @override
  String get monthlyLimit => 'Plafond mensuel';

  @override
  String get group => 'Groupe';

  @override
  String get category => 'Catégorie';

  @override
  String get chooseGroup => 'Choisir un groupe';

  @override
  String get chooseCategory => 'Choisir une catégorie';

  @override
  String get newExpense => 'Nouvelle dépense';

  @override
  String get newExpenseSubtitle =>
      'Saisis le montant et les détails ci-dessous';

  @override
  String get editExpenseSubtitle =>
      'Modifie le montant et les détails ci-dessous';

  @override
  String get chooseAGroup => 'Choisis un groupe';

  @override
  String get chooseACategory => 'Choisis une catégorie';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get splitsMustMatch =>
      'La somme des parts doit égaler le montant total';

  @override
  String get createGroupFirst =>
      'Crée d\'abord un groupe pour ajouter une dépense.';

  @override
  String get newFeminine => 'Nouvelle';

  @override
  String get optional => 'Facultatif';

  @override
  String get split => 'Répartition';

  @override
  String get splitEqual => 'Égale';

  @override
  String get splitShares => 'Parts';

  @override
  String get splitCustom => 'Montants';

  @override
  String get scheduleRecurrence => 'Programmer la récurrence';

  @override
  String get splitTotal => 'Total réparti';

  @override
  String get splitSelectAll => 'Tout cocher';

  @override
  String get splitSelectNone => 'Tout décocher';

  @override
  String get splitNeedSomeone => 'Coche au moins une personne';

  @override
  String get repeatMonthly => 'Répéter chaque mois';

  @override
  String repeatOnDay(int day) {
    return 'Le $day de chaque mois';
  }

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String get newCategorySubtitle => 'Personnalise l\'icône et la couleur';

  @override
  String get name => 'Nom';

  @override
  String get icon => 'Icône';

  @override
  String get color => 'Couleur';

  @override
  String get createCategory => 'Créer la catégorie';

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get defaultCategoryHousing => 'Logement';

  @override
  String get defaultCategoryGroceries => 'Courses';

  @override
  String get defaultCategoryRestaurant => 'Restaurant';

  @override
  String get defaultCategoryTransport => 'Transport';

  @override
  String get defaultCategoryLeisure => 'Loisirs';

  @override
  String get defaultCategorySubscriptions => 'Abonnements';

  @override
  String get defaultCategoryHealth => 'Santé';

  @override
  String get defaultCategoryOther => 'Autre';

  @override
  String get defaultCategoryRepayment => 'Remboursement';

  @override
  String get invalid => 'Invalide';

  @override
  String get required => 'Requis';

  @override
  String get myCards => 'Mes cartes';

  @override
  String get noCards => 'Aucune carte';

  @override
  String get noCardsHint =>
      'Ajoute ta première carte de fidélité\navec le bouton ci-dessous';

  @override
  String get addCard => 'Ajouter une carte';

  @override
  String get showCard => 'Afficher la carte';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get loyaltyCard => 'Carte de fidélité';

  @override
  String get barcode => 'Code-barres';

  @override
  String get qrCode => 'QR Code';

  @override
  String get cameraDenied => 'Accès à la caméra refusé';

  @override
  String get centerCode => 'Centrez le code dans le cadre';

  @override
  String get cancelScan => 'Annuler le scan';

  @override
  String get newCard => 'Nouvelle carte';

  @override
  String get newCardScanHint => 'Scanne le code-barres ou QR de ta carte';

  @override
  String get newCardCheckHint => 'Vérifie l\'enseigne détectée';

  @override
  String get scanMyCard => 'Scanner ma carte';

  @override
  String get enterCodeManually => 'Saisir le code manuellement';

  @override
  String get rescan => 'Rescanner';

  @override
  String get detectedBrand => 'Enseigne détectée';

  @override
  String get brand => 'Enseigne';

  @override
  String get unknownBrand => 'Enseigne non reconnue';

  @override
  String get unknownBrandHint =>
      'Cherche l\'enseigne — tes cartes et les codes du même type sont en premier. On s\'en souvient pour la suite.';

  @override
  String get brandHint => 'Ex. Animalis, Picard…';

  @override
  String get other => 'Autre';

  @override
  String get brandNameHint => 'Nom de l\'enseigne';

  @override
  String get preview => 'Aperçu';

  @override
  String get myCard => 'Ma carte';

  @override
  String get addTheCard => 'Ajouter la carte';

  @override
  String get editCard => 'Modifier la carte';

  @override
  String get editCardHint => 'Change le nom ou mets à jour le code';

  @override
  String get enterCode => 'Saisir le code';

  @override
  String get codeExample => 'Ex: 8DD C9Y D9L';

  @override
  String get recognizedAuto => 'Reconnue automatiquement';

  @override
  String get walletHint =>
      'Tape une carte pour la mettre devant · swipe pour parcourir';

  @override
  String get cardsViewTooltip => 'Changer l\'affichage';

  @override
  String get cardsViewWallet => 'Pile';

  @override
  String get cardsViewGrid => 'Grille';

  @override
  String get cardsViewCompact => 'Liste';

  @override
  String get cardsCategoryFrequent => 'Souvent';

  @override
  String get cardsCategoryAll => 'Tout';

  @override
  String get cardsCategoryGroceries => 'Courses';

  @override
  String get cardsCategoryPets => 'Animalerie';

  @override
  String get cardsCategoryFashion => 'Mode';

  @override
  String get cardsCategoryHome => 'Maison';

  @override
  String get cardsCategoryFood => 'Restos';

  @override
  String get cardsCategoryTech => 'High-tech';

  @override
  String get cardsCategorySport => 'Sport';

  @override
  String get cardsCategoryOther => 'Autre';

  @override
  String get owedToYou => 'On te doit';

  @override
  String get youOwe => 'Tu dois';

  @override
  String get settledBadge => 'Réglé ✓';

  @override
  String get owesTo => ' doit à ';

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get personalInfoHint => 'Nom, e-mail et mot de passe';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get nameLabel => 'Nom';

  @override
  String get nameTooShort => '2 caractères minimum';

  @override
  String get nameTooLong => '50 caractères maximum';

  @override
  String get passwordSection => 'Mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordMin8 =>
      '8 caractères min., une majuscule, un chiffre et un symbole';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get profileSaved => 'Profil mis à jour';

  @override
  String get passwordChanged => 'Mot de passe modifié';

  @override
  String get changeAvatar => 'Changer la photo';

  @override
  String get pickGallery => 'Galerie';

  @override
  String get pickCamera => 'Appareil photo';

  @override
  String get avatarInvalidType => 'Utilise un fichier JPG, PNG ou WebP';

  @override
  String get avatarTooLarge => 'L\'image ne doit pas dépasser 20 Mo';

  @override
  String get avatarTooSmall => 'L\'image doit faire au moins 128×128 pixels';

  @override
  String get avatarTooBig => 'L\'image ne doit pas dépasser 1024×1024 pixels';

  @override
  String get avatarUploadFailed => 'Impossible d\'envoyer la photo';

  @override
  String get errorWrongPassword => 'Mot de passe actuel incorrect';

  @override
  String get errorNameLength => 'Le nom doit faire entre 2 et 50 caractères';

  @override
  String get errorPasswordLength =>
      'Le mot de passe doit faire au moins 8 caractères, avec une majuscule, un chiffre et un symbole';
}
