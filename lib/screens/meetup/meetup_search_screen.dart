import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../providers/meetup_provider.dart';
import '../../widgets/station_input_list.dart';
import '../../widgets/mode_selector.dart';
import '../../config/constants.dart';

class MeetupSearchScreen extends ConsumerWidget {
  const MeetupSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final state = ref.watch(meetupSearchProvider);
    final notifier = ref.read(meetupSearchProvider.notifier);
    final api = ref.read(apiClientProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locale == 'ja' ? '集合場所を探す'
              : locale == 'ko' ? '만남역 찾기'
              : 'Find Meetup Station',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Region
            Row(
              children: ['kanto', 'kansai'].map((region) {
                final isSelected = state.region == region;
                final label = region == 'kanto'
                    ? (locale == 'ja' ? '関東' : locale == 'ko' ? '간토' : 'Kanto')
                    : (locale == 'ja' ? '関西' : locale == 'ko' ? '간사이' : 'Kansai');
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: region == 'kanto' ? 8 : 0),
                    child: ChoiceChip(
                      label: SizedBox(width: double.infinity, child: Text(label, textAlign: TextAlign.center)),
                      selected: isSelected,
                      onSelected: (_) => notifier.setRegion(region),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Station input
            Text(
              locale == 'ja' ? '出発駅を入力 (2〜10人)'
                  : locale == 'ko' ? '출발역 입력 (2~10명)'
                  : 'Enter departure stations (2-10)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            StationInputList(
              stations: state.slots,
              onSearch: (q) => api.searchStations(q, region: state.region),
              onSelect: (index, station) => notifier.setStation(index, station),
              onRemove: (index) => notifier.removeSlot(index),
              onAdd: () => notifier.addSlot(),
              locale: locale,
            ),
            // Cross-region warning
            Builder(builder: (ctx) {
              final filled = state.filledStations;
              if (filled.length < 2) return const SizedBox.shrink();
              final regions = filled.map((s) => s.region).toSet();
              if (regions.length <= 1) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber, size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    locale == 'ja' ? '異なる地域の駅は混在できません'
                      : locale == 'ko' ? '다른 지역의 역은 함께 검색할 수 없습니다'
                      : 'Cannot mix stations from different regions',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                  )),
                ]),
              );
            }),
            const SizedBox(height: 20),

            // Mode
            Text(
              locale == 'ja' ? '検索モード' : locale == 'ko' ? '검색 모드' : 'Search mode',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModeSelector(selected: state.mode, onChanged: notifier.setMode, locale: locale),
            const SizedBox(height: 20),

            // Category
            Text(
              locale == 'ja' ? 'ジャンル（任意）' : locale == 'ko' ? '장르 (선택)' : 'Category (optional)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.categories.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value[locale] ?? entry.value['en']!, style: const TextStyle(fontSize: 12)),
                  selected: state.category == entry.key,
                  onSelected: (s) => notifier.setCategory(s ? entry.key : null),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Budget
            Text(
              locale == 'ja' ? '予算（任意）' : locale == 'ko' ? '예산 (선택)' : 'Budget (optional)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.budgets.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value[locale] ?? entry.value['en']!, style: const TextStyle(fontSize: 12)),
                  selected: state.budget == entry.key,
                  onSelected: (s) => notifier.setBudget(s ? entry.key : null),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Options
            Text(
              locale == 'ja' ? 'オプション' : locale == 'ko' ? '옵션' : 'Options',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.filterOptions.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.value[locale] ?? entry.value['en']!, style: const TextStyle(fontSize: 12)),
                  selected: state.options.contains(entry.key),
                  onSelected: (_) => notifier.toggleOption(entry.key),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Search button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (state.filledStations.length < 2 || state.isLoading || state.filledStations.map((s) => s.region).toSet().length > 1)
                    ? null
                    : () => notifier.search(),
                child: state.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(locale == 'ja' ? '集合駅を検索' : locale == 'ko' ? '만남역 검색' : 'Find Meetup Station'),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(state.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
