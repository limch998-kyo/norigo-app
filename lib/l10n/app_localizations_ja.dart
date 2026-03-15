// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Norigo';

  @override
  String get homeTitle => '旅行に最適なホテルを見つけよう';

  @override
  String get homeSubtitle => '観光地を入力すると最適なホテルエリアを提案';

  @override
  String get searchPlaceholder => 'ランドマークを検索...';

  @override
  String get searchButton => 'ホテルを検索';

  @override
  String get tokyoTitle => '東京・関東';

  @override
  String get osakaTitle => '大阪・関西';

  @override
  String get seoulTitle => 'ソウル';

  @override
  String get busanTitle => '釜山';

  @override
  String get quickPlanTitle => '人気の旅行プラン';

  @override
  String get quickPlanDesc => 'ワンタップで旅行を始めよう';

  @override
  String get quickPlanCta => '検索';

  @override
  String get staySearchTitle => 'ホテル検索';

  @override
  String get tripTitle => '旅行プラン';

  @override
  String get guidesTitle => '旅行ガイド';

  @override
  String get addToTrip => '旅行に追加';

  @override
  String get addToSearch => '検索に追加';

  @override
  String get findHotels => 'ホテルを探す';

  @override
  String minutesAway(int minutes) {
    return '$minutes分';
  }

  @override
  String get perNight => '/ 泊';

  @override
  String get viewOnMap => '地図で見る';

  @override
  String get popularSpots => '人気スポット';

  @override
  String get moreInfo => '詳しく見る';

  @override
  String get bookNow => '予約する';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabSearch => '検索';

  @override
  String get tabTrip => '旅行';

  @override
  String get tabGuide => 'ガイド';
}
