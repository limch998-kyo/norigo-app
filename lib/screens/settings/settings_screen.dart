import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../providers/trip_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _locales = {
    'ja': '日本語',
    'en': 'English',
    'ko': '한국어',
    'zh': '中文（简体）',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locale == 'ja'
              ? '設定'
              : locale == 'ko'
                  ? '설정'
                  : 'Settings',
        ),
      ),
      body: ListView(
        children: [
          // Language
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              locale == 'ja'
                  ? '言語'
                  : locale == 'ko'
                      ? '언어'
                      : 'Language',
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
                // Re-resolve names in the new locale
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
              locale == 'ja'
                  ? 'テーマ'
                  : locale == 'ko'
                      ? '테마'
                      : 'Theme',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...{
            ThemeMode.system: locale == 'ja'
                ? 'システム'
                : locale == 'ko'
                    ? '시스템'
                    : 'System',
            ThemeMode.light: locale == 'ja'
                ? 'ライト'
                : locale == 'ko'
                    ? '라이트'
                    : 'Light',
            ThemeMode.dark: locale == 'ja'
                ? 'ダーク'
                : locale == 'ko'
                    ? '다크'
                    : 'Dark',
          }.entries.map((entry) {
            final currentMode = ref.watch(themeModeProvider);
            final isSelected = currentMode == entry.key;
            return ListTile(
              leading: Icon(
                entry.key == ThemeMode.system
                    ? Icons.brightness_auto
                    : entry.key == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.dark_mode,
              ),
              title: Text(entry.value),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).state = entry.key;
              },
            );
          }),

          const Divider(height: 32),

          // About
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              locale == 'ja'
                  ? 'アプリについて'
                  : locale == 'ko'
                      ? '앱 정보'
                      : 'About',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Norigo'),
            subtitle: const Text('v1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              locale == 'ja' ? 'ウェブサイト' : locale == 'ko' ? '웹사이트' : 'Website',
            ),
            subtitle: const Text('norigo.app'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(
              locale == 'ja'
                  ? 'プライバシーポリシー'
                  : locale == 'ko'
                      ? '개인정보 처리방침'
                      : 'Privacy Policy',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(
              locale == 'ja'
                  ? '利用規約'
                  : locale == 'ko'
                      ? '이용약관'
                      : 'Terms of Service',
            ),
          ),
        ],
      ),
    );
  }
}
