import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../utils/tr.dart';
import '../../providers/trip_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _locales = {
    'ja': '日本語',
    'en': 'English',
    'ko': '한국어',
    'zh': '中文（简体）',
    'fr': 'Français',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(locale, ja: '設定', ko: '설정', en: 'Settings', zh: '设置', fr: 'Paramètres'),
        ),
      ),
      body: ListView(
        children: [
          // Language
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              tr(locale, ja: '言語', ko: '언어', en: 'Language', zh: '语言', fr: 'Langue'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ..._locales.entries.map((entry) {
            final isSelected = locale == entry.key;
            return ListTile(
              title: Text(entry.value),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).state = entry.key;
                // Instantly translate all names using bundled offline data
                ref.read(staySearchProvider.notifier).refreshLandmarkNames();
                ref.read(tripProvider.notifier).refreshNames();
              },
            );
          }),

          const Divider(height: 32),

          // Theme
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr(locale, ja: 'テーマ', ko: '테마', en: 'Theme', zh: '主题', fr: 'Thème'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...{
            ThemeMode.system: (Icons.brightness_auto, tr(locale, ja: 'システム設定', ko: '시스템 설정', en: 'System', zh: '跟随系统', fr: 'Système')),
            ThemeMode.light: (Icons.light_mode, tr(locale, ja: 'ライト', ko: '라이트', en: 'Light', zh: '浅色', fr: 'Clair')),
            ThemeMode.dark: (Icons.dark_mode, tr(locale, ja: 'ダーク', ko: '다크', en: 'Dark', zh: '深色', fr: 'Sombre')),
          }.entries.map((entry) {
            final isSelected = ref.watch(themeModeProvider) == entry.key;
            return ListTile(
              leading: Icon(entry.value.$1),
              title: Text(entry.value.$2),
              trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
              onTap: () => ref.read(themeModeProvider.notifier).state = entry.key,
            );
          }),

          const Divider(height: 32),

          // About
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr(locale, ja: 'アプリについて', ko: '앱 정보', en: 'About', zh: '关于', fr: 'À propos'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}' : '...';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Nori GO!'),
                subtitle: Text(version),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              tr(locale, ja: 'ウェブサイト', ko: '웹사이트', en: 'Website', zh: '网站', fr: 'Site web'),
            ),
            subtitle: const Text('norigo.app'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => launchUrl(Uri.parse('https://norigo.app/$locale'), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(
              tr(locale, ja: 'プライバシーポリシー', ko: '개인정보 처리방침', en: 'Privacy Policy', zh: '隐私政策', fr: 'Politique de confidentialité'),
            ),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => launchUrl(Uri.parse('https://norigo.app/$locale/privacy'), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(
              tr(locale, ja: '利用規約', ko: '이용약관', en: 'Terms of Service', zh: '服务条款', fr: 'Conditions d\'utilisation'),
            ),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => launchUrl(Uri.parse('https://norigo.app/$locale/terms'), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(
              tr(locale, ja: '画像の出典', ko: '이미지 출처', en: 'Image Credits', zh: '图片来源', fr: 'Crédits photo'),
            ),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => launchUrl(Uri.parse('https://norigo.app/$locale/credits'), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}
