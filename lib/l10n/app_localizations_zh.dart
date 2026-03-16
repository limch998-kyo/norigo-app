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
  String get homeTitle => '日本旅行？帮你找到完美位置。';

  @override
  String get homeSubtitle => '输入想去的景点，自动推荐住宿区域和美食。';

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
  String get quickPlanDesc => '点击即可找到最佳酒店区域';

  @override
  String get quickPlanCta => '搜索酒店';

  @override
  String get staySearchTitle => '查找住宿区域';

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

  @override
  String get meetupTitle => '查找聚会地点';

  @override
  String get meetupSearchButton => '搜索集合站';

  @override
  String get stationPlaceholder => '输入车站名...';

  @override
  String get addStations => '添加出发站 (2-5人)';

  @override
  String get searchMode => '搜索模式';

  @override
  String get category => '分类（可选）';

  @override
  String get budget => '预算（可选）';

  @override
  String get options => '选项';

  @override
  String get dates => '日期';

  @override
  String get addLandmarks => '输入所有想去的景点';

  @override
  String get results => '搜索结果';

  @override
  String get noResults => '未找到结果';

  @override
  String get recommendedHotels => '推荐酒店';

  @override
  String get nearbyVenues => '附近餐厅';

  @override
  String get route => '路线';

  @override
  String avgTime(int minutes) {
    return '平均 $minutes分钟';
  }

  @override
  String get splitStay => '分住';

  @override
  String get singleStay => '单住';

  @override
  String get newTrip => '新行程';

  @override
  String get tripName => '输入行程名称';

  @override
  String get create => '创建';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get rename => '重命名';

  @override
  String deleteConfirm(String name) {
    return '删除「$name」？';
  }

  @override
  String spots(int count) {
    return '$count个景点';
  }

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get about => '关于';

  @override
  String get website => '网站';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String get active => '活跃';

  @override
  String get noTripsYet => '还没有行程';

  @override
  String get tapToCreate => '点击+创建新行程';
}
