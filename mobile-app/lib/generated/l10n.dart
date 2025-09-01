import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
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
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// Greeting message
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String hello(String name);

  String get dashboard;
  String get transactions;
  String get categories;
  String get reports;
  String get settings;
  String get profile;
  String get income;
  String get expense;
  String get balance;
  String get totalIncome;
  String get totalExpense;
  String get monthlyBalance;
  String get addTransaction;
  String get editTransaction;
  String get deleteTransaction;
  String get transactionAdded;
  String get transactionUpdated;
  String get transactionDeleted;
  String get amount;
  String get description;
  String get category;
  String get date;
  String get type;
  String get receipt;
  String get selectCategory;
  String get selectDate;
  String get selectType;
  String get enterAmount;
  String get enterDescription;
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get add;
  String get update;
  String get confirm;
  String get back;
  String get login;
  String get register;
  String get logout;
  String get email;
  String get password;
  String get confirmPassword;
  String get name;
  String get forgotPassword;
  String get loginSuccess;
  String get loginFailed;
  String get registerSuccess;
  String get registerFailed;
  String get logoutConfirmation;
  String get manageCategories;
  String get addCategory;
  String get editCategory;
  String get deleteCategory;
  String get categoryName;
  String get categoryIcon;
  String get categoryColor;
  String get reportsAndAnalytics;
  String get monthlyReport;
  String get weeklyReport;
  String get yearlyReport;
  String get exportPDF;
  String get exportCSV;
  String get selectMonth;
  String get noDataAvailable;
  String get incomeVsExpense;
  String get expenseByCategory;
  String get monthlyTrend;
  String get topCategories;
  String get notifications;
  String get notificationSettings;
  String get dailyReminders;
  String get weeklyReports;
  String get monthlyReports;
  String get budgetAlerts;
  String get pushNotifications;
  String get reminderTime;
  String get testNotification;
  String get theme;
  String get themeSettings;
  String get lightMode;
  String get darkMode;
  String get themeColor;
  String get blue;
  String get green;
  String get purple;
  String get orange;
  String get red;
  String get language;
  String get languageSettings;
  String get english;
  String get indonesian;
  String get recentTransactions;
  String get viewAll;
  String get noTransactions;
  String get noCategories;
  String get searchTransactions;
  String get filterByCategory;
  String get filterByType;
  String get filterByDate;
  String get clearFilters;
  String get thisMonth;
  String get lastMonth;
  String get thisYear;
  String get lastYear;
  String get custom;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'id': return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
