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
  String get homeTitle => '일본 여행, 딱 좋은 위치를 찾아줄게요.';

  @override
  String get homeSubtitle => '가고 싶은 관광지를 입력하면 호텔 위치와 맛집을 추천합니다.';

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
  String get quickPlanDesc => '탭하면 바로 최적의 호텔 지역을 찾아줍니다';

  @override
  String get quickPlanCta => '호텔 찾기';

  @override
  String get staySearchTitle => '숙박 지역 찾기';

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

  @override
  String get meetupTitle => '모임 장소 찾기';

  @override
  String get meetupSearchButton => '만남역 검색';

  @override
  String get stationPlaceholder => '역 이름 입력...';

  @override
  String get addStations => '출발역 추가 (2~5명)';

  @override
  String get searchMode => '검색 모드';

  @override
  String get category => '장르 (선택)';

  @override
  String get budget => '예산 (선택)';

  @override
  String get options => '옵션';

  @override
  String get dates => '일정';

  @override
  String get addLandmarks => '가고 싶은 관광지를 모두 입력';

  @override
  String get results => '검색 결과';

  @override
  String get noResults => '결과를 찾을 수 없습니다';

  @override
  String get recommendedHotels => '추천 호텔';

  @override
  String get nearbyVenues => '주변 맛집';

  @override
  String get route => '경로';

  @override
  String avgTime(int minutes) {
    return '평균 $minutes분';
  }

  @override
  String get splitStay => '분할 숙박';

  @override
  String get singleStay => '통합';

  @override
  String get newTrip => '새 여행';

  @override
  String get tripName => '여행 이름 입력';

  @override
  String get create => '생성';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get rename => '이름변경';

  @override
  String deleteConfirm(String name) {
    return '\"$name\"을 삭제하시겠습니까?';
  }

  @override
  String spots(int count) {
    return '$count개 관광지';
  }

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get about => '앱 정보';

  @override
  String get website => '웹사이트';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get termsOfService => '이용약관';

  @override
  String get active => '활성';

  @override
  String get noTripsYet => '아직 여행이 없습니다';

  @override
  String get tapToCreate => '+ 버튼으로 새 여행 생성';
}
