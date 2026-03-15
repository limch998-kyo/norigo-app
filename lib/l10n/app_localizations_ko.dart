// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '노리고';

  @override
  String get homeTitle => '여행에 최적인 호텔을 찾아보세요';

  @override
  String get homeSubtitle => '가고 싶은 관광지를 입력하면 최적의 호텔을 추천';

  @override
  String get searchPlaceholder => '관광지 검색...';

  @override
  String get searchButton => '호텔 검색';

  @override
  String get tokyoTitle => '도쿄 / 간토';

  @override
  String get osakaTitle => '오사카 / 간사이';

  @override
  String get seoulTitle => '서울';

  @override
  String get busanTitle => '부산';

  @override
  String get quickPlanTitle => '인기 여행 플랜';

  @override
  String get quickPlanDesc => '원탭으로 여행을 시작하세요';

  @override
  String get quickPlanCta => '검색';

  @override
  String get staySearchTitle => '호텔 검색';

  @override
  String get tripTitle => '내 여행';

  @override
  String get guidesTitle => '여행 가이드';

  @override
  String get addToTrip => '여행에 추가';

  @override
  String get addToSearch => '검색에 추가';

  @override
  String get findHotels => '호텔 찾기';

  @override
  String minutesAway(int minutes) {
    return '$minutes분';
  }

  @override
  String get perNight => '/ 박';

  @override
  String get viewOnMap => '지도에서 보기';

  @override
  String get popularSpots => '인기 관광지';

  @override
  String get moreInfo => '자세히 보기';

  @override
  String get bookNow => '예약하기';

  @override
  String get tabHome => '홈';

  @override
  String get tabSearch => '검색';

  @override
  String get tabTrip => '여행';

  @override
  String get tabGuide => '가이드';
}
