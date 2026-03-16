import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import 'widgets/quick_plan_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Hero
            Text(
              l10n.homeTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Service buttons
            Row(
              children: [
                Expanded(
                  child: _ServiceButton(
                    icon: Icons.hotel,
                    label: locale == 'ja'
                        ? 'ホテル検索'
                        : locale == 'ko'
                            ? '호텔 검색'
                            : 'Hotel Search',
                    onTap: () {
                      DefaultTabController.of(context).animateTo(1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceButton(
                    icon: Icons.groups,
                    label: locale == 'ja'
                        ? '集合駅'
                        : locale == 'ko'
                            ? '만남역'
                            : 'Meetup',
                    onTap: () {
                      DefaultTabController.of(context).animateTo(2);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Plans
            const QuickPlanCards(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
