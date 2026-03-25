import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/app_providers.dart';
import '../providers/trip_provider.dart';
import '../providers/stay_provider.dart';
import '../models/landmark.dart';
import '../screens/trip/trip_screen.dart' show localizedTripName;
import '../utils/tr.dart';

/// Floating basket button + bottom sheet for managing trip items
class TripBasketButton extends ConsumerWidget {
  final void Function(int)? onSwitchTab;

  const TripBasketButton({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripProvider);
    final count = state.activeItems.length;

    if (count == 0) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 80,
      child: GestureDetector(
        onTap: () => _showBasketSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.luggage, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  void _showBasketSheet(BuildContext context, WidgetRef ref) {
    final locale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _BasketSheet(locale: locale, onSwitchTab: onSwitchTab),
    );
  }
}

class _BasketSheet extends ConsumerWidget {
  final String locale;
  final void Function(int)? onSwitchTab;

  const _BasketSheet({required this.locale, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripProvider);
    final notifier = ref.read(tripProvider.notifier);
    final items = state.activeItems;
    final trip = state.activeTrip;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Icon(Icons.luggage, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  trip != null ? localizedTripName(trip.name, locale) : tr(locale, ja: '旅行プラン', ko: '여행 플랜', en: 'Trip Plan', zh: '旅行计划', fr: 'Plan de voyage'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )),
                Text('${items.length} ${tr(locale, ja: 'スポット', ko: '관광지', en: 'spots', zh: '景点', fr: 'sites')}',
                  style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
              ]),
            ),
            const Divider(height: 24),

            // Items list
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(
                      tr(locale, ja: 'スポットを追加してください', ko: '관광지를 추가해주세요', en: 'Add some spots', zh: '请添加景点', fr: 'Ajoutez des sites'),
                      style: TextStyle(color: AppTheme.mutedForeground),
                    ))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryBg,
                            child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                          title: Text(item.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(item.region.toUpperCase(), style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                          trailing: IconButton(
                            icon: Icon(Icons.close, size: 16, color: AppTheme.mutedForeground),
                            onPressed: () => notifier.removeItem(item.slug, item.tripId),
                          ),
                        );
                      },
                    ),
            ),

            // Share to PC button
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Build shareable URL with landmarks
                      final params = items.map((i) => '${Uri.encodeComponent(i.name)},${i.lat},${i.lng}').join('|');
                      final region = items.first.region;
                      final url = 'https://norigo.app/$locale/stay/search?l=${Uri.encodeComponent(params)}&r=$region';
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(tr(locale, ja: 'PCで開けるリンクをコピーしました', ko: 'PC에서 열 수 있는 링크를 복사했습니다', en: 'Link copied for PC', zh: '已复制电脑端链接', fr: 'Lien copié pour PC')),
                      ));
                    },
                    icon: const Icon(Icons.computer, size: 16),
                    label: Text(
                      tr(locale, ja: 'PCに送る', ko: 'PC로 보내기', en: 'Send to PC', zh: '发送到电脑', fr: 'Envoyer au PC'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Search hotels button
            if (items.length >= 2)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Fill stay search with trip items
                        final stayNotifier = ref.read(staySearchProvider.notifier);
                        stayNotifier.reset();
                        if (items.isNotEmpty) stayNotifier.setRegion(items.first.region);
                        for (final item in items) {
                          stayNotifier.addLandmark(Landmark(
                            slug: item.slug,
                            name: item.name,
                            lat: item.lat,
                            lng: item.lng,
                            region: item.region,
                          ));
                        }
                        // Set defaults: budget + dates
                        final isKorea = items.any((i) => ['seoul', 'busan'].contains(i.region));
                        stayNotifier.setBudget(isKorea ? '25000-35000' : '10000-30000');
                        final checkIn = DateTime.now().add(const Duration(days: 30));
                        final checkOut = checkIn.add(const Duration(days: 3));
                        stayNotifier.setDates(
                          checkIn.toIso8601String().substring(0, 10),
                          checkOut.toIso8601String().substring(0, 10),
                        );
                        onSwitchTab?.call(1);
                      },
                      icon: const Icon(Icons.hotel, size: 18),
                      label: Text(
                        tr(locale, ja: 'この${items.length}スポットでホテルを検索', ko: '이 ${items.length}개 관광지로 호텔 검색', en: 'Search hotels for ${items.length} spots', zh: '为${items.length}个景点搜索酒店', fr: 'Chercher des hôtels pour ${items.length} sites'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
