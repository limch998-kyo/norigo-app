import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Norigo'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Visiting Japan? We\'ll find the perfect spot.'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a few places you want to visit — we\'ll find the best hotel area and restaurants.'**
  String get homeSubtitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search landmarks...'**
  String get searchPlaceholder;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search Hotels'**
  String get searchButton;

  /// No description provided for @tokyoTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokyo / Kanto'**
  String get tokyoTitle;

  /// No description provided for @osakaTitle.
  ///
  /// In en, this message translates to:
  /// **'Osaka / Kansai'**
  String get osakaTitle;

  /// No description provided for @seoulTitle.
  ///
  /// In en, this message translates to:
  /// **'Seoul'**
  String get seoulTitle;

  /// No description provided for @busanTitle.
  ///
  /// In en, this message translates to:
  /// **'Busan'**
  String get busanTitle;

  /// No description provided for @quickPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Travel Plans'**
  String get quickPlanTitle;

  /// No description provided for @quickPlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap to instantly find the best hotel area'**
  String get quickPlanDesc;

  /// No description provided for @quickPlanCta.
  ///
  /// In en, this message translates to:
  /// **'Find Hotels'**
  String get quickPlanCta;

  /// No description provided for @staySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Hotel Area'**
  String get staySearchTitle;

  /// No description provided for @tripTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trip'**
  String get tripTitle;

  /// No description provided for @guidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Guides'**
  String get guidesTitle;

  /// No description provided for @addToTrip.
  ///
  /// In en, this message translates to:
  /// **'Add to trip'**
  String get addToTrip;

  /// No description provided for @addToSearch.
  ///
  /// In en, this message translates to:
  /// **'Add to search'**
  String get addToSearch;

  /// No description provided for @findHotels.
  ///
  /// In en, this message translates to:
  /// **'Find Hotels'**
  String get findHotels;

  /// No description provided for @minutesAway.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesAway(int minutes);

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'/ night'**
  String get perNight;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @popularSpots.
  ///
  /// In en, this message translates to:
  /// **'Popular Spots'**
  String get popularSpots;

  /// No description provided for @moreInfo.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get moreInfo;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tabTrip;

  /// No description provided for @tabGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get tabGuide;

  /// No description provided for @meetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Meetup Spot'**
  String get meetupTitle;

  /// No description provided for @meetupSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Find Meetup Station'**
  String get meetupSearchButton;

  /// No description provided for @stationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter station name...'**
  String get stationPlaceholder;

  /// No description provided for @addStations.
  ///
  /// In en, this message translates to:
  /// **'Add departure stations (2-5)'**
  String get addStations;

  /// No description provided for @searchMode.
  ///
  /// In en, this message translates to:
  /// **'Search mode'**
  String get searchMode;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get category;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget (optional)'**
  String get budget;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @addLandmarks.
  ///
  /// In en, this message translates to:
  /// **'Enter all places you want to visit'**
  String get addLandmarks;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @recommendedHotels.
  ///
  /// In en, this message translates to:
  /// **'Recommended Hotels'**
  String get recommendedHotels;

  /// No description provided for @nearbyVenues.
  ///
  /// In en, this message translates to:
  /// **'Nearby Venues'**
  String get nearbyVenues;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @avgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg {minutes} min'**
  String avgTime(int minutes);

  /// No description provided for @splitStay.
  ///
  /// In en, this message translates to:
  /// **'Split Stay'**
  String get splitStay;

  /// No description provided for @singleStay.
  ///
  /// In en, this message translates to:
  /// **'Single Stay'**
  String get singleStay;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get newTrip;

  /// No description provided for @tripName.
  ///
  /// In en, this message translates to:
  /// **'Enter trip name'**
  String get tripName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteConfirm(String name);

  /// No description provided for @spots.
  ///
  /// In en, this message translates to:
  /// **'{count} spots'**
  String spots(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @tapToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new trip'**
  String get tapToCreate;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
