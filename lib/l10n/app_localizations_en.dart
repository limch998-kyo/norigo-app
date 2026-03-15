// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Norigo';

  @override
  String get homeTitle => 'Find the best hotel for your trip';

  @override
  String get homeSubtitle =>
      'Enter tourist spots and we find the optimal hotel area';

  @override
  String get searchPlaceholder => 'Search landmarks...';

  @override
  String get searchButton => 'Search Hotels';

  @override
  String get tokyoTitle => 'Tokyo / Kanto';

  @override
  String get osakaTitle => 'Osaka / Kansai';

  @override
  String get seoulTitle => 'Seoul';

  @override
  String get busanTitle => 'Busan';

  @override
  String get quickPlanTitle => 'Popular Travel Plans';

  @override
  String get quickPlanDesc => 'Start your trip with one tap';

  @override
  String get quickPlanCta => 'Search';

  @override
  String get staySearchTitle => 'Hotel Search';

  @override
  String get tripTitle => 'My Trip';

  @override
  String get guidesTitle => 'Travel Guides';

  @override
  String get addToTrip => 'Add to trip';

  @override
  String get addToSearch => 'Add to search';

  @override
  String get findHotels => 'Find Hotels';

  @override
  String minutesAway(int minutes) {
    return '$minutes min';
  }

  @override
  String get perNight => '/ night';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get popularSpots => 'Popular Spots';

  @override
  String get moreInfo => 'More info';

  @override
  String get bookNow => 'Book Now';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabTrip => 'Trip';

  @override
  String get tabGuide => 'Guide';
}
