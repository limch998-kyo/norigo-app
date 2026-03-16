import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../widgets/landmark_input_list.dart';
import '../../widgets/mode_selector.dart';
import '../../config/constants.dart';

class StaySearchScreen extends ConsumerStatefulWidget {
  const StaySearchScreen({super.key});

  @override
  ConsumerState<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends ConsumerState<StaySearchScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;

  @override
  void initState() {
    super.initState();
    // Default: 1 month from now, 3 nights
    _checkIn = DateTime.now().add(const Duration(days: 30));
    _checkOut = _checkIn.add(const Duration(days: 3));

    // Set dates in provider after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(staySearchProvider.notifier);
      final state = ref.read(staySearchProvider);
      if (state.checkIn == null) {
        notifier.setDates(
          _checkIn.toIso8601String().substring(0, 10),
          _checkOut.toIso8601String().substring(0, 10),
        );
      } else {
        _checkIn = DateTime.parse(state.checkIn!);
        _checkOut = DateTime.parse(state.checkOut!);
      }
    });
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });

    ref.read(staySearchProvider.notifier).setDates(
      _checkIn.toIso8601String().substring(0, 10),
      _checkOut.toIso8601String().substring(0, 10),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
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

    // ja locale: show Korea regions first (since ja users are tourists visiting Korea)
    // others: show Japan regions first
    final regionOrder = locale == 'ja'
        ? ['seoul', 'busan', 'kanto', 'kansai']
        : AppConstants.allRegions;

    final landmarkSlots = state.slots;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staySearchTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Region selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: regionOrder.map((region) {
                  final isSelected = state.region == region;
                  final label = _regionLabel(region, locale);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => notifier.setRegion(region),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Landmark input (2 empty fields by default)
            Text(
              l10n.addLandmarks,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            LandmarkInputList(
              landmarks: landmarkSlots,
              onSearch: (q) => api.searchLandmarks(q, region: state.region, locale: locale),
              onSelect: (index, landmark) => notifier.setLandmark(index, landmark),
              onRemove: (index) => notifier.removeSlot(index),
              onAdd: () => notifier.addSlot(),
              locale: locale,
            ),
            const SizedBox(height: 20),

            // Mode selector
            Text(
              locale == 'ja' ? '検索モード' : locale == 'ko' ? '검색 모드' : 'Search mode',
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
              locale == 'ja' ? '日程' : locale == 'ko' ? '일정' : 'Dates',
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
                      _formatDate(_checkIn),
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
                      _formatDate(_checkOut),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Budget selector
            Text(
              locale == 'ja' ? '予算' : locale == 'ko' ? '예산' : 'Budget',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: budgets.entries.map((entry) {
                final isSelected = state.maxBudget == entry.key;
                return ChoiceChip(
                  label: Text(entry.value[locale] ?? entry.value['en']!, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) => notifier.setBudget(selected ? entry.key : null),
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
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.searchButton),
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

  String _regionLabel(String region, String locale) {
    const labels = {
      'kanto': {'ja': '東京・関東', 'en': 'Tokyo / Kanto', 'ko': '도쿄 / 간토', 'zh': '东京 / 关东'},
      'kansai': {'ja': '大阪・関西', 'en': 'Osaka / Kansai', 'ko': '오사카 / 간사이', 'zh': '大阪 / 关西'},
      'seoul': {'ja': 'ソウル', 'en': 'Seoul', 'ko': '서울', 'zh': '首尔'},
      'busan': {'ja': '釜山', 'en': 'Busan', 'ko': '부산', 'zh': '釜山'},
    };
    return labels[region]?[locale] ?? labels[region]?['en'] ?? region;
  }
}
