import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/station.dart';
import '../../providers/app_providers.dart';
import '../../providers/meetup_provider.dart';
import '../../widgets/search_input.dart';
import '../../widgets/chip_list.dart';
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
          locale == 'ja'
              ? '集合駅を探す'
              : locale == 'ko'
                  ? '만남역 찾기'
                  : 'Find Meetup Station',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Region (Japan only)
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
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(label, textAlign: TextAlign.center),
                      ),
                      selected: isSelected,
                      onSelected: (_) => notifier.setRegion(region),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Station search
            Text(
              locale == 'ja'
                  ? '出発駅を追加 (2〜5人)'
                  : locale == 'ko'
                      ? '출발역 추가 (2~5명)'
                      : 'Add departure stations (2-5)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SearchInput<Station>(
              hintText: locale == 'ja'
                  ? '駅名を入力...'
                  : locale == 'ko'
                      ? '역 이름 입력...'
                      : 'Enter station name...',
              onSearch: (q) => api.searchStations(q, region: state.region),
              displayText: (s) => s.name,
              onSelect: (s) => notifier.addStation(s),
              itemBuilder: (station) => ListTile(
                dense: true,
                leading: const Icon(Icons.train, size: 20),
                title: Text(station.name, style: const TextStyle(fontSize: 14)),
                subtitle: station.lines.isNotEmpty
                    ? Text(
                        station.lines.take(3).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),

            // Selected stations
            ChipList(
              items: state.stations.map((s) => s.name).toList(),
              onRemove: (i) => notifier.removeStation(state.stations[i].id),
            ),
            const SizedBox(height: 20),

            // Mode
            Text(
              locale == 'ja'
                  ? '検索モード'
                  : locale == 'ko'
                      ? '검색 모드'
                      : 'Search mode',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModeSelector(
              selected: state.mode,
              onChanged: (m) => notifier.setMode(m),
              locale: locale,
            ),
            const SizedBox(height: 20),

            // Category filter
            Text(
              locale == 'ja'
                  ? 'ジャンル（任意）'
                  : locale == 'ko'
                      ? '장르 (선택)'
                      : 'Category (optional)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.categories.entries.map((entry) {
                final isSelected = state.category == entry.key;
                return ChoiceChip(
                  label: Text(
                    entry.value[locale] ?? entry.value['en']!,
                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    notifier.setCategory(selected ? entry.key : null);
                  },
                  selectedColor: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Budget filter
            Text(
              locale == 'ja'
                  ? '予算（任意）'
                  : locale == 'ko'
                      ? '예산 (선택)'
                      : 'Budget (optional)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.budgets.entries.map((entry) {
                final isSelected = state.budget == entry.key;
                return ChoiceChip(
                  label: Text(
                    entry.value[locale] ?? entry.value['en']!,
                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    notifier.setBudget(selected ? entry.key : null);
                  },
                  selectedColor: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Options
            Text(
              locale == 'ja'
                  ? 'オプション'
                  : locale == 'ko'
                      ? '옵션'
                      : 'Options',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.filterOptions.entries.map((entry) {
                final isSelected = state.options.contains(entry.key);
                return FilterChip(
                  label: Text(
                    entry.value[locale] ?? entry.value['en']!,
                    style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null),
                  ),
                  selected: isSelected,
                  onSelected: (_) => notifier.toggleOption(entry.key),
                  selectedColor: theme.colorScheme.primary,
                  checkmarkColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Search button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: state.stations.length < 2 || state.isLoading
                    ? null
                    : () => notifier.search(),
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        locale == 'ja'
                            ? '集合駅を検索'
                            : locale == 'ko'
                                ? '만남역 검색'
                                : 'Find Meetup Station',
                      ),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
