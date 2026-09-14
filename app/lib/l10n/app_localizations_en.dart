// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tabby';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get minPassword =>
      '8 characters, an uppercase letter, a number and a symbol';

  @override
  String get passwordPolicy =>
      'At least 8 characters, an uppercase letter, a number and a symbol';

  @override
  String get me => 'Me';

  @override
  String get you => 'You';

  @override
  String get admin => 'Admin';

  @override
  String get ok => 'OK';

  @override
  String get errorGeneric => 'Error';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorUnexpected => 'Unexpected error';

  @override
  String get errorRegister => 'Could not create account';

  @override
  String get errorInvalidCredentials => 'Invalid email or password';

  @override
  String get errorEmailTaken => 'This email is already registered';

  @override
  String get errorInvalidInvite => 'Invalid code';

  @override
  String get errorInviteUsed => 'This code has already been used';

  @override
  String get errorInviteExpired => 'This code has expired';

  @override
  String get errorAlreadyMember => 'You\'re already a member of this group';

  @override
  String get errorMemberNotFound => 'Member not found';

  @override
  String get errorGroupNotFound => 'Group not found';

  @override
  String get errorBalanceNotZero =>
      'Balance is not zero. Settle your debts before leaving.';

  @override
  String get errorDelete => 'Could not delete';

  @override
  String get errorUpdate => 'Could not update';

  @override
  String get errorCreate => 'Could not create';

  @override
  String get errorUnauthorized => 'Session expired, please sign in again';

  @override
  String get errorForbidden => 'You are not allowed to do this';

  @override
  String get errorConflict => 'This action conflicts with the current state';

  @override
  String get errorValidation => 'Invalid data';

  @override
  String get offlineBanner => 'No network connection';

  @override
  String get offlineRetry =>
      'Connection unavailable. Check your network and try again.';

  @override
  String get expenseGroupRequired => 'Choose a group.';

  @override
  String get expenseNameRequired => 'Add a description.';

  @override
  String get expenseAmountInvalid => 'Enter a positive amount.';

  @override
  String get expenseCategoryRequired => 'Choose a category.';

  @override
  String get expensePayerRequired => 'Choose who paid.';

  @override
  String get expenseSplitsRequired => 'Add at least one participant.';

  @override
  String get expenseSplitsDuplicate => 'Each participant can only appear once.';

  @override
  String get expenseSplitsMismatch => 'Split amounts must equal the total.';

  @override
  String get navHome => 'Home';

  @override
  String get navBudget => 'Budget';

  @override
  String get navCards => 'Cards';

  @override
  String get navProfile => 'Profile';

  @override
  String get navAddExpense => 'Add expense';

  @override
  String get fabClose => 'Close';

  @override
  String get fabActions => 'Actions';

  @override
  String get loginHello => 'Hello 👋';

  @override
  String get loginSubtitle => 'Sign in to access your groups';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginNoAccount => 'No account yet? Sign up';

  @override
  String get biometricSetting => 'Sign in with biometrics';

  @override
  String get biometricSettingHint =>
      'Unlock Tabby on launch without typing your password.';

  @override
  String get biometricEnableTitle => 'Turn on biometric sign-in?';

  @override
  String get biometricEnableBody =>
      'Use your fingerprint or Face ID to open Tabby. Your token stays encrypted on this device.';

  @override
  String get biometricEnableConfirm => 'Turn on';

  @override
  String get biometricNotNow => 'Not now';

  @override
  String get biometricLockReason => 'Unlock Tabby';

  @override
  String get biometricUnlock => 'Unlock';

  @override
  String get biometricFailed => 'Biometric authentication failed';

  @override
  String get biometricUnavailable => 'No biometrics are set up on this device';

  @override
  String get registerTitle => 'Create an account';

  @override
  String get registerSubtitle => 'Join Tabby to share your expenses';

  @override
  String get registerName => 'First name';

  @override
  String get registerSubmit => 'Sign up';

  @override
  String get registerHasAccount => 'Already have an account? Sign in';

  @override
  String get yourGroups => 'Your groups';

  @override
  String get newGroup => 'New group';

  @override
  String get globalBalance => 'Overall balance';

  @override
  String activeGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active groups',
      one: '1 active group',
    );
    return '$_temp0';
  }

  @override
  String get welcome => 'Welcome 👋';

  @override
  String get homeEmptyHint => 'Tap New group to get started';

  @override
  String get homeGroupsHint => 'Tap a group to see details';

  @override
  String get homeEmptyTitle => 'No groups yet';

  @override
  String get homeEmptyBody => 'Use New group below\nto create or join a group!';

  @override
  String get newGroupSheetSubtitle =>
      'Create a group or join one with an invite code.';

  @override
  String get createGroup => 'Create a group';

  @override
  String get createGroupSubtitle => 'Start a group and invite people';

  @override
  String get joinGroup => 'Join a group';

  @override
  String get joinGroupSubtitle => 'Enter the code shared by a friend';

  @override
  String get createGroupHeadline => 'Name your group';

  @override
  String get createGroupHint => 'e.g. Couple, Summer trip, Flatshare…';

  @override
  String get groupName => 'Group name';

  @override
  String get createGroupSubmit => 'Create group';

  @override
  String get joinGroupHeadline => 'Enter the invite code';

  @override
  String get joinGroupHint =>
      'Ask the person who created the group for the 8-character invite code.';

  @override
  String get inviteCodeLabel => '8-character code';

  @override
  String get inviteCodeRequired => 'An 8-character code is required';

  @override
  String get joinSubmit => 'Join';

  @override
  String get joinedGroup => 'You\'ve joined the group!';

  @override
  String get pinGroup => 'Pin to home';

  @override
  String get unpinGroup => 'Unpin from home';

  @override
  String get editName => 'Rename';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get leaveGroupBody =>
      'You will no longer have access to this group. This cannot be undone.';

  @override
  String get leave => 'Leave';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteGroupBody =>
      'All expenses will be deleted. This cannot be undone.';

  @override
  String get groupOptions => 'Group options';

  @override
  String get toSettle => 'To settle';

  @override
  String get addExpense => 'Add expense';

  @override
  String get inviteSomeone => 'Invite someone';

  @override
  String get settle => 'Settle';

  @override
  String get confirmSettle => 'Confirm repayment';

  @override
  String settleBody(String from, String to) {
    return '$from pays $to back.';
  }

  @override
  String settleMaxAmount(String amount) {
    return 'Maximum $amount';
  }

  @override
  String get settleAmountExceeds => 'Amount cannot exceed the debt.';

  @override
  String get settleSaved => 'Repayment saved ✓';

  @override
  String get settlePending => 'Waiting for confirmation';

  @override
  String get repaymentPending => 'Pending';

  @override
  String get confirmRepayment => 'Confirm repayment';

  @override
  String get repaymentConfirmed => 'Repayment confirmed ✓';

  @override
  String get rejectRepayment => 'Reject repayment';

  @override
  String get rejectRepaymentTitle => 'Reject this repayment?';

  @override
  String rejectRepaymentBody(String name) {
    return 'The request “$name” will be deleted. No repayment will be confirmed.';
  }

  @override
  String get errorSettlePending =>
      'A repayment is already waiting for confirmation.';

  @override
  String get settled => 'Settled';

  @override
  String joinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String get expenses => 'Expenses';

  @override
  String expensesCount(int count) {
    return 'Expenses ($count)';
  }

  @override
  String get noExpensesInGroup => 'No expenses in this group.';

  @override
  String membersCount(int count) {
    return 'Members ($count)';
  }

  @override
  String get editExpense => 'Edit expense';

  @override
  String get deleteExpenseTitle => 'Delete this expense?';

  @override
  String deleteExpenseBody(String name) {
    return '“$name” will be deleted from the group. This cannot be undone.';
  }

  @override
  String get totalExpenses => 'Group total';

  @override
  String get yourShare => 'Your expenses';

  @override
  String yourShareAmount(String amount) {
    return 'You: $amount €';
  }

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get description => 'Description';

  @override
  String get expenseNameHint => 'Groceries, dinner…';

  @override
  String get amount => 'Amount';

  @override
  String get paidBy => 'Paid by';

  @override
  String paidByPerson(String name) {
    return 'Paid by $name';
  }

  @override
  String get participants => 'Participants';

  @override
  String get date => 'Date';

  @override
  String get today => 'Today';

  @override
  String get daysAgoOne => '1 day ago';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get inviteMember => 'Invite a member';

  @override
  String get inviteCodeTitle => 'Invite code';

  @override
  String get inviteCodeShare =>
      'Share this code with the person you want to invite. It is valid for 24 hours.';

  @override
  String get inviteCodeShareShort =>
      'Share this code with the person you want to invite.';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get generateNewCode => 'Generate a new code';

  @override
  String get backHome => 'Back to home';

  @override
  String get inviteValid24h => 'Valid for 24 hours';

  @override
  String get inviteGenerateFailed => 'Could not generate a code.';

  @override
  String get profile => 'Profile';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeHint => 'Light or dark — colors follow the Tabby palette.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSaveFailed => 'Couldn\'t save the theme.';

  @override
  String get themeAppearanceSystem => 'System appearance';

  @override
  String get themeAppearanceLight => 'Light appearance';

  @override
  String get themeAppearanceDark => 'Dark appearance';

  @override
  String get language => 'Language';

  @override
  String get languageHint => 'Defaults to your phone language.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Using device language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get scanFromScreenshot => 'Import a screenshot';

  @override
  String get noCodeInImage => 'No barcode or QR code found in this image';

  @override
  String get personalization => 'Personalization';

  @override
  String get recurringExpenses => 'Recurring expenses';

  @override
  String get myCategories => 'My categories';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out?';

  @override
  String get logoutAction => 'Sign out';

  @override
  String get categoriesTitle => 'My categories';

  @override
  String get deleteCategoryTitle => 'Delete this category?';

  @override
  String deleteCategoryBody(String name) {
    return 'The category \"$name\" will be deleted. Existing expenses will keep their category.';
  }

  @override
  String get noCustomCategories => 'No custom categories';

  @override
  String get noCustomCategoriesHint =>
      'Create categories from the\nNew expense screen';

  @override
  String get recurringTitle => 'Recurring expenses';

  @override
  String get noRecurring => 'No recurring expenses';

  @override
  String get noRecurringHint =>
      'Turn on “Repeat every month” when adding\na shared or For me expense.';

  @override
  String get deleteRecurringTitle => 'Delete this recurrence?';

  @override
  String get deleteRecurringBody =>
      'Expenses already created will not be deleted.';

  @override
  String get recurringMonthly => 'Monthly';

  @override
  String get recurringYearly => 'Yearly';

  @override
  String get recurringFirstOfMonth => '1st of the month';

  @override
  String recurringNthOfMonth(int day) {
    return 'Day $day of the month';
  }

  @override
  String get editRecurring => 'Edit recurrence';

  @override
  String get editRecurringSubtitle =>
      'Expenses already created will not be updated.';

  @override
  String get recurringDayOfMonth => 'Day of the month';

  @override
  String get budget => 'Budget';

  @override
  String get monthTotal => 'Your share this month';

  @override
  String get yourShareLegend => 'Only your share of shared expenses.';

  @override
  String get shareLegendAll =>
      'Your share of groups plus your personal spending.';

  @override
  String get shareLegendGroups => 'Only your share of shared expenses.';

  @override
  String get shareLegendPersonal => 'Only your personal expenses.';

  @override
  String get scopeAll => 'All';

  @override
  String get scopeGroups => 'Groups';

  @override
  String get scopePersonal => 'For me';

  @override
  String get personalPurchases => 'Your purchases';

  @override
  String get noPersonalPurchases => 'No For me purchases this month';

  @override
  String get noPersonalPurchasesHint => 'Tap + in the bar, then For me.';

  @override
  String get deletePersonalTitle => 'Delete this purchase?';

  @override
  String deletePersonalBody(String name) {
    return '“$name” will be removed from your budget.';
  }

  @override
  String get expenseShared => 'Shared';

  @override
  String get expenseForMe => 'For me';

  @override
  String get categoryNamePrivacyHint =>
      'The name is yours. If you use it on a shared expense, group members will see that name — not your For me purchases.';

  @override
  String get monthBudgets => 'Monthly budgets';

  @override
  String get noBudgetThisMonth =>
      'No budget this month — set a cap per category.';

  @override
  String get noBudgetTitle => 'No budgets yet';

  @override
  String get noBudgetBody =>
      'Set a monthly cap per category to track this month\'s spending.';

  @override
  String get budgetThresholdHint => 'Watch from 75% of the cap, over at 100%.';

  @override
  String get budgetActions => 'Budget options';

  @override
  String get moreOptions => 'More options';

  @override
  String get newBudget => 'New budget';

  @override
  String get allGroups => 'All';

  @override
  String get allGroupsMenu => 'All groups';

  @override
  String get thisMonth => 'This month';

  @override
  String get myExpenses => 'My expenses';

  @override
  String get noPersonalPurchasesYet => 'No For me purchases yet';

  @override
  String get noSpendThisMonth => 'No spending this month';

  @override
  String get allExpenses => 'All expenses';

  @override
  String totalAmount(String amount) {
    return 'Total $amount €';
  }

  @override
  String percentOfTotal(String percent) {
    return '$percent% of total';
  }

  @override
  String budgetPerMonth(String amount) {
    return 'Budget $amount/month';
  }

  @override
  String get overBudget => 'Over';

  @override
  String get warning => 'Watch';

  @override
  String spentAmount(String amount) {
    return '$amount spent';
  }

  @override
  String remainingAmount(String amount) {
    return '$amount left';
  }

  @override
  String overspendAmount(String amount) {
    return '$amount over';
  }

  @override
  String get editLimit => 'Edit limit';

  @override
  String get deleteBudgetTitle => 'Delete this budget?';

  @override
  String deleteBudgetBody(String name) {
    return 'The budget for \"$name\" will be deleted.';
  }

  @override
  String get editBudget => 'Edit budget';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get group => 'Group';

  @override
  String get category => 'Category';

  @override
  String get chooseGroup => 'Choose a group';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get newExpense => 'New expense';

  @override
  String get newExpenseSubtitle => 'Enter the amount and details below';

  @override
  String get editExpenseSubtitle => 'Update the amount and details below';

  @override
  String get chooseAGroup => 'Choose a group';

  @override
  String get chooseACategory => 'Choose a category';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get splitsMustMatch => 'The shares must add up to the total';

  @override
  String get createGroupFirst => 'Create a group first to add an expense.';

  @override
  String get newFeminine => 'New';

  @override
  String get optional => 'Optional';

  @override
  String get split => 'Split';

  @override
  String get splitEqual => 'Equal';

  @override
  String get splitShares => 'Shares';

  @override
  String get splitCustom => 'Amounts';

  @override
  String get scheduleRecurrence => 'Schedule recurrence';

  @override
  String get splitTotal => 'Allocated total';

  @override
  String get splitSelectAll => 'Select all';

  @override
  String get splitSelectNone => 'Select none';

  @override
  String get splitNeedSomeone => 'Select at least one person';

  @override
  String get repeatMonthly => 'Repeat every month';

  @override
  String repeatOnDay(int day) {
    return 'On the $day of each month';
  }

  @override
  String get newCategory => 'New category';

  @override
  String get newCategorySubtitle => 'Customize the icon and color';

  @override
  String get name => 'Name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get createCategory => 'Create category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get defaultCategoryHousing => 'Housing';

  @override
  String get defaultCategoryGroceries => 'Groceries';

  @override
  String get defaultCategoryRestaurant => 'Restaurant';

  @override
  String get defaultCategoryTransport => 'Transport';

  @override
  String get defaultCategoryLeisure => 'Leisure';

  @override
  String get defaultCategorySubscriptions => 'Subscriptions';

  @override
  String get defaultCategoryHealth => 'Health';

  @override
  String get defaultCategoryOther => 'Other';

  @override
  String get defaultCategoryRepayment => 'Repayment';

  @override
  String get invalid => 'Invalid';

  @override
  String get required => 'Required';

  @override
  String get myCards => 'My cards';

  @override
  String get noCards => 'No cards';

  @override
  String get noCardsHint =>
      'Add your first loyalty card\nwith the button below';

  @override
  String get addCard => 'Add a card';

  @override
  String get showCard => 'Show card';

  @override
  String get deleteLoyaltyCardTitle => 'Delete this card?';

  @override
  String deleteLoyaltyCardBody(String name) {
    return 'The “$name” card will be removed from your wallet.';
  }

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get loyaltyCard => 'Loyalty card';

  @override
  String get barcode => 'Barcode';

  @override
  String get qrCode => 'QR Code';

  @override
  String get cameraDenied => 'Camera access denied';

  @override
  String get centerCode => 'Center the code in the frame';

  @override
  String get cancelScan => 'Cancel scan';

  @override
  String get newCard => 'New card';

  @override
  String get newCardScanHint => 'Scan the barcode or QR on your card';

  @override
  String get newCardCheckHint => 'Check the detected brand';

  @override
  String get scanMyCard => 'Scan my card';

  @override
  String get enterCodeManually => 'Enter the code manually';

  @override
  String get rescan => 'Scan again';

  @override
  String get detectedBrand => 'Detected brand';

  @override
  String get brand => 'Brand';

  @override
  String get unknownBrand => 'Unrecognized brand';

  @override
  String get unknownBrandHint =>
      'Search for the brand — your cards and similar codes come first. We\'ll remember this for next time.';

  @override
  String get brandHint => 'e.g. Animalis, Picard…';

  @override
  String get other => 'Other';

  @override
  String get brandNameHint => 'Brand name';

  @override
  String get preview => 'Preview';

  @override
  String get myCard => 'My card';

  @override
  String get addTheCard => 'Add card';

  @override
  String get editCard => 'Edit card';

  @override
  String get editCardHint => 'Change the name or update the code';

  @override
  String get enterCode => 'Enter the code';

  @override
  String get codeExample => 'e.g. 8DD C9Y D9L';

  @override
  String get recognizedAuto => 'Recognized automatically';

  @override
  String get walletHint => 'Tap a card to bring it forward · swipe to browse';

  @override
  String get cardsViewTooltip => 'Change layout';

  @override
  String get cardsViewWallet => 'Stack';

  @override
  String get cardsViewGrid => 'Grid';

  @override
  String get cardsViewCompact => 'List';

  @override
  String get cardsCategoryFrequent => 'Often';

  @override
  String get cardsCategoryAll => 'All';

  @override
  String get cardsCategoryGroceries => 'Groceries';

  @override
  String get cardsCategoryPets => 'Pets';

  @override
  String get cardsCategoryFashion => 'Fashion';

  @override
  String get cardsCategoryHome => 'Home';

  @override
  String get cardsCategoryFood => 'Food';

  @override
  String get cardsCategoryTech => 'Tech';

  @override
  String get cardsCategorySport => 'Sport';

  @override
  String get cardsCategoryOther => 'Other';

  @override
  String get owedToYou => 'You\'re owed';

  @override
  String get youOwe => 'You owe';

  @override
  String get settledBadge => 'Settled ✓';

  @override
  String get owesTo => ' owes ';

  @override
  String get personalInfo => 'Personal information';

  @override
  String get personalInfoHint => 'Name, email and password';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameTooShort => 'At least 2 characters';

  @override
  String get nameTooLong => '50 characters maximum';

  @override
  String get passwordSection => 'Password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMin8 =>
      'At least 8 characters, an uppercase letter, a number and a symbol';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get changePassword => 'Change password';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get changeAvatar => 'Change photo';

  @override
  String get pickGallery => 'Gallery';

  @override
  String get pickCamera => 'Camera';

  @override
  String get avatarInvalidType => 'Use a JPG, PNG or WebP file';

  @override
  String get avatarTooLarge => 'The image must be 20 MB or smaller';

  @override
  String get avatarTooSmall => 'The image must be at least 128×128 pixels';

  @override
  String get avatarTooBig => 'The image must be at most 1024×1024 pixels';

  @override
  String get avatarUploadFailed => 'Could not upload the photo';

  @override
  String get errorWrongPassword => 'Current password is incorrect';

  @override
  String get errorNameLength => 'Name must be 2-50 characters';

  @override
  String get errorPasswordLength =>
      'Password must be at least 8 characters and include an uppercase letter, a number and a symbol';
}
