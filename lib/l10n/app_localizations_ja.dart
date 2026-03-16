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

  @override
  String get meetupTitle => '集合駅を探す';

  @override
  String get meetupSearchButton => '集合駅を検索';

  @override
  String get stationPlaceholder => '駅名を入力...';

  @override
  String get addStations => '出発駅を追加 (2〜5人)';

  @override
  String get searchMode => '検索モード';

  @override
  String get category => 'ジャンル（任意）';

  @override
  String get budget => '予算（任意）';

  @override
  String get options => 'オプション';

  @override
  String get dates => '日程';

  @override
  String get addLandmarks => '観光スポットを追加';

  @override
  String get results => '検索結果';

  @override
  String get noResults => '結果が見つかりませんでした';

  @override
  String get recommendedHotels => 'おすすめホテル';

  @override
  String get nearbyVenues => '周辺のお店';

  @override
  String get route => 'ルート';

  @override
  String avgTime(int minutes) {
    return '平均 $minutes分';
  }

  @override
  String get splitStay => '分泊';

  @override
  String get singleStay => '通常';

  @override
  String get newTrip => '新しい旅行';

  @override
  String get tripName => '旅行名を入力';

  @override
  String get create => '作成';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get rename => '名前変更';

  @override
  String deleteConfirm(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String spots(int count) {
    return '$count件のスポット';
  }

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get about => 'アプリについて';

  @override
  String get website => 'ウェブサイト';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get active => 'アクティブ';

  @override
  String get noTripsYet => 'まだ旅行がありません';

  @override
  String get tapToCreate => '＋ボタンから新しい旅行を作成';
}
