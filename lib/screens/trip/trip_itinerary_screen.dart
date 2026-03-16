import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../models/landmark.dart';
import '../../services/api_client.dart';

class TripItineraryScreen extends ConsumerStatefulWidget {
  final List<Landmark> landmarks;
  final String region;
  final String? checkIn;
  final String? checkOut;
  final String? maxBudget;

  const TripItineraryScreen({
    super.key,
    required this.landmarks,
    required this.region,
    this.checkIn,
    this.checkOut,
    this.maxBudget,
  });

  @override
  ConsumerState<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends ConsumerState<TripItineraryScreen> {
  Map<String, dynamic>? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _optimize();
  }

  Future<void> _optimize() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiClientProvider);
      final result = await api.optimizeTrip(
        landmarks: widget.landmarks.map((l) => {
          'slug': l.slug,
          'name': l.name,
          'lat': l.lat,
          'lng': l.lng,
        }).toList(),
        region: widget.region,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
      );
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ja' ? '日程最適化' : locale == 'ko' ? '일정 최적화' : 'Itinerary'),
      ),
      body: _loading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Optimizing itinerary...'),
            ]))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _optimize, child: const Text('Retry')),
                  ],
                )))
              : _buildResult(locale, theme),
    );
  }

  Widget _buildResult(String locale, ThemeData theme) {
    if (_result == null) return const Center(child: Text('No result'));

    final clusters = _result!['clusters'] as List<dynamic>? ?? [];
    final isSplit = _result!['split'] as bool? ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.auto_awesome, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              locale == 'ja' ? '最適化された旅行プラン'
                : locale == 'ko' ? '최적화된 여행 플랜'
                : 'Optimized Itinerary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            )),
          ]),
        ),
        if (isSplit) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text(
                locale == 'ja' ? '距離が離れているため、2つのエリアに分割しました'
                  : locale == 'ko' ? '거리가 멀어 2개 지역으로 나눴습니다'
                  : 'Split into 2 areas due to distance',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
              )),
            ]),
          ),
        ],
        const SizedBox(height: 16),

        // Clusters with days
        ...clusters.asMap().entries.map((ce) {
          final cluster = ce.value as Map<String, dynamic>;
          final days = cluster['days'] as List<dynamic>? ?? [];
          final hotel = cluster['hotel'] as Map<String, dynamic>?;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (clusters.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ce.key == 0 ? AppTheme.primaryBg : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: ce.key == 0 ? AppTheme.primary : AppTheme.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${ce.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${locale == 'ja' ? 'エリア' : locale == 'ko' ? '지역' : 'Area'} ${ce.key + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
            // Hotel recommendation
            if (hotel != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(Icons.hotel, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        locale == 'ja' ? '推薦ホテルエリア' : locale == 'ko' ? '추천 숙박 지역' : 'Recommended Hotel Area',
                        style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                      ),
                      Text(
                        hotel['station']?['name'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ])),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Days
            ...days.asMap().entries.map((de) {
              final day = de.value as Map<String, dynamic>;
              final date = day['date'] as String? ?? '';
              final dayLandmarks = day['landmarks'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'Day ${de.key + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(date, style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                    ]),
                    const SizedBox(height: 10),
                    ...dayLandmarks.asMap().entries.map((le) {
                      final lm = le.value;
                      final name = lm is Map ? (lm['name'] as String? ?? '') : lm.toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryBg,
                            child: Text('${le.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
                        ]),
                      );
                    }),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
          ]);
        }),
      ],
    );
  }
}
