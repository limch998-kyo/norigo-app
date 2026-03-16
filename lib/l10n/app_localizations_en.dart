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

  @override
  String get meetupTitle => 'Find Meetup Station';

  @override
  String get meetupSearchButton => 'Find Meetup Station';

  @override
  String get stationPlaceholder => 'Enter station name...';

  @override
  String get addStations => 'Add departure stations (2-5)';

  @override
  String get searchMode => 'Search mode';

  @override
  String get category => 'Category (optional)';

  @override
  String get budget => 'Budget (optional)';

  @override
  String get options => 'Options';

  @override
  String get dates => 'Dates';

  @override
  String get addLandmarks => 'Add landmarks';

  @override
  String get results => 'Results';

  @override
  String get noResults => 'No results found';

  @override
  String get recommendedHotels => 'Recommended Hotels';

  @override
  String get nearbyVenues => 'Nearby Venues';

  @override
  String get route => 'Route';

  @override
  String avgTime(int minutes) {
    return 'Avg $minutes min';
  }

  @override
  String get splitStay => 'Split Stay';

  @override
  String get singleStay => 'Single Stay';

  @override
  String get newTrip => 'New Trip';

  @override
  String get tripName => 'Enter trip name';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String deleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String spots(int count) {
    return '$count spots';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get about => 'About';

  @override
  String get website => 'Website';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get active => 'Active';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get tapToCreate => 'Tap + to create a new trip';
}
