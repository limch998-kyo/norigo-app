// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Norigo';

  @override
  String get homeTitle => 'Vous visitez le Japon ? On trouve le spot idéal.';

  @override
  String get homeSubtitle =>
      'Entrez quelques lieux à visiter — on trouve le meilleur quartier d\'hôtel et les restaurants.';

  @override
  String get searchPlaceholder => 'Rechercher des sites...';

  @override
  String get searchButton => 'Rechercher des hôtels';

  @override
  String get tokyoTitle => 'Tokyo / Kanto';

  @override
  String get osakaTitle => 'Osaka / Kansai';

  @override
  String get seoulTitle => 'Séoul';

  @override
  String get busanTitle => 'Busan';

  @override
  String get quickPlanTitle => 'Plans de voyage populaires';

  @override
  String get quickPlanDesc =>
      'Appuyez pour trouver le meilleur quartier d\'hôtel';

  @override
  String get quickPlanCta => 'Trouver des hôtels';

  @override
  String get staySearchTitle => 'Trouver un quartier d\'hôtel';

  @override
  String get tripTitle => 'Mon voyage';

  @override
  String get guidesTitle => 'Guides de voyage';

  @override
  String get addToTrip => 'Ajouter au voyage';

  @override
  String get addToSearch => 'Ajouter à la recherche';

  @override
  String get findHotels => 'Trouver des hôtels';

  @override
  String minutesAway(int minutes) {
    return '$minutes min';
  }

  @override
  String get perNight => '/ nuit';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get popularSpots => 'Sites populaires';

  @override
  String get moreInfo => 'Plus d\'infos';

  @override
  String get bookNow => 'Réserver';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabSearch => 'Recherche';

  @override
  String get tabTrip => 'Voyage';

  @override
  String get tabGuide => 'Guide';

  @override
  String get meetupTitle => 'Trouver un point de rencontre';

  @override
  String get meetupSearchButton => 'Trouver la station';

  @override
  String get stationPlaceholder => 'Nom de la gare...';

  @override
  String get addStations => 'Ajouter les gares de départ (2-5)';

  @override
  String get searchMode => 'Mode de recherche';

  @override
  String get category => 'Catégorie (facultatif)';

  @override
  String get budget => 'Budget (facultatif)';

  @override
  String get options => 'Options';

  @override
  String get dates => 'Dates';

  @override
  String get addLandmarks => 'Entrez tous les lieux à visiter';

  @override
  String get results => 'Résultats';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get recommendedHotels => 'Hôtels recommandés';

  @override
  String get nearbyVenues => 'Restaurants à proximité';

  @override
  String get route => 'Itinéraire';

  @override
  String avgTime(int minutes) {
    return 'Moy. $minutes min';
  }

  @override
  String get splitStay => 'Séjour divisé';

  @override
  String get singleStay => 'Séjour unique';

  @override
  String get newTrip => 'Nouveau voyage';

  @override
  String get tripName => 'Nom du voyage';

  @override
  String get create => 'Créer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String deleteConfirm(String name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String spots(int count) {
    return '$count sites';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get about => 'À propos';

  @override
  String get website => 'Site web';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get active => 'Actif';

  @override
  String get noTripsYet => 'Aucun voyage';

  @override
  String get tapToCreate => 'Appuyez sur + pour créer un voyage';
}
