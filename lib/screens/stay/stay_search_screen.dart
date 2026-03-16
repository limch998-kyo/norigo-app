import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/landmark.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../widgets/search_input.dart';
import '../../widgets/chip_list.dart';
import '../../widgets/mode_selector.dart';
import '../../config/constants.dart';

class StaySearchScreen extends ConsumerStatefulWidget {
  const StaySearchScreen({super.key});

  @override
  ConsumerState<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends ConsumerState<StaySearchScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkIn ?? now.add(const Duration(days: 7)))
          : (_checkOut ?? (_checkIn ?? now).add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut != null && _checkOut!.isBefore(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });

    final notifier = ref.read(staySearchProvider.notifier);
    notifier.setDates(
      _checkIn?.toIso8601String().substring(0, 10),
      _checkOut?.toIso8601String().substring(0, 10),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final state = ref.watch(staySearchProvider);
    final notifier = ref.read(staySearchProvider.notifier);
    final api = ref.read(apiClientProvider);
    final theme = Theme.of(context);

    final isKorea = AppConstants.koreaRegions.contains(state.region);
    final budgets = isKorea
        ? AppConstants.hotelBudgetsKorea
        : AppConstants.hotelBudgetsJapan;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staySearchTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Region selector
            _RegionSelector(
              selected: state.region,
              onChanged: (r) => notifier.setRegion(r),
              locale: locale,
            ),
            const SizedBox(height: 16),

            // Landmark search
            Text(
              locale == 'ja'
                  ? '観光スポットを追加'
                  : locale == 'ko'
                      ? '관광지 추가'
                      : 'Add landmarks',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SearchInput<Landmark>(
              hintText: l10n.searchPlaceholder,
              onSearch: (q) => api.searchLandmarks(q, region: state.region),
              displayText: (l) => l.name,
              onSelect: (l) => notifier.addLandmark(l),
              itemBuilder: (landmark) => ListTile(
                dense: true,
                leading: const Icon(Icons.place, size: 20),
                title: Text(landmark.name, style: const TextStyle(fontSize: 14)),
                subtitle: landmark.nameEn != null
                    ? Text(landmark.nameEn!, style: const TextStyle(fontSize: 12))
                    : null,
              ),
            ),
            const SizedBox(height: 8),

            // Selected landmarks
            ChipList(
              items: state.landmarks.map((l) => l.name).toList(),
              onRemove: (i) => notifier.removeLandmark(state.landmarks[i].slug),
            ),
            const SizedBox(height: 20),

            // Mode selector
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

            // Date selection
            Text(
              locale == 'ja'
                  ? '日程'
                  : locale == 'ko'
                      ? '일정'
                      : 'Dates',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _checkIn != null
                          ? _formatDate(_checkIn)
                          : 'Check-in',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _checkOut != null
                          ? _formatDate(_checkOut)
                          : 'Check-out',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Budget selector
            Text(
              locale == 'ja'
                  ? '予算'
                  : locale == 'ko'
                      ? '예산'
                      : 'Budget',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: budgets.entries.map((entry) {
                final isSelected = state.maxBudget == entry.key;
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
            const SizedBox(height: 32),

            // Search button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: state.landmarks.isEmpty || state.isLoading
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
                    : Text(l10n.searchButton),
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

class _RegionSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final String locale;

  const _RegionSelector({
    required this.selected,
    required this.onChanged,
    required this.locale,
  });

  static const _regionLabels = {
    'kanto': {'ja': '東京・関東', 'en': 'Tokyo / Kanto', 'ko': '도쿄 / 간토', 'zh': '东京 / 关东'},
    'kansai': {'ja': '大阪・関西', 'en': 'Osaka / Kansai', 'ko': '오사카 / 간사이', 'zh': '大阪 / 关西'},
    'seoul': {'ja': 'ソウル', 'en': 'Seoul', 'ko': '서울', 'zh': '首尔'},
    'busan': {'ja': '釜山', 'en': 'Busan', 'ko': '부산', 'zh': '釜山'},
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppConstants.allRegions.map((region) {
          final isSelected = selected == region;
          final label = _regionLabels[region]?[locale] ??
              _regionLabels[region]?['en'] ??
              region;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(region),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
