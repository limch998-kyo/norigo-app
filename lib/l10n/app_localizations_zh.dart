// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Norigo';

  @override
  String get homeTitle => '找到最适合你旅行的酒店';

  @override
  String get homeSubtitle => '输入景点，自动推荐最佳住宿区域';

  @override
  String get searchPlaceholder => '搜索景点...';

  @override
  String get searchButton => '搜索酒店';

  @override
  String get tokyoTitle => '东京 / 关东';

  @override
  String get osakaTitle => '大阪 / 关西';

  @override
  String get seoulTitle => '首尔';

  @override
  String get busanTitle => '釜山';

  @override
  String get quickPlanTitle => '热门旅行方案';

  @override
  String get quickPlanDesc => '一键开启旅行';

  @override
  String get quickPlanCta => '搜索';

  @override
  String get staySearchTitle => '酒店搜索';

  @override
  String get tripTitle => '我的行程';

  @override
  String get guidesTitle => '旅行指南';

  @override
  String get addToTrip => '添加到行程';

  @override
  String get addToSearch => '添加到搜索';

  @override
  String get findHotels => '查找酒店';

  @override
  String minutesAway(int minutes) {
    return '$minutes分钟';
  }

  @override
  String get perNight => '/ 晚';

  @override
  String get viewOnMap => '在地图上查看';

  @override
  String get popularSpots => '热门景点';

  @override
  String get moreInfo => '了解更多';

  @override
  String get bookNow => '立即预订';

  @override
  String get tabHome => '首页';

  @override
  String get tabSearch => '搜索';

  @override
  String get tabTrip => '行程';

  @override
  String get tabGuide => '指南';
}
