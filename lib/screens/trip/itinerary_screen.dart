import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/itinerary.dart';
import '../../models/stay_area.dart';
import '../../utils/tr.dart';

/// Optimized multi-day itinerary for a trip: TSP-ordered spots distributed
/// across days with a recommended hotel base per cluster. Fetches
/// POST /api/trip/optimize itself (thin client — the ordering/clustering is
/// all server-side).
class ItineraryScreen extends ConsumerStatefulWidget {
  final String tripId;
  const ItineraryScreen({super.key, required this.tripId});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  ItineraryResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _optimize();
  }

  Future<void> _optimize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tripState = ref.read(tripProvider);
      final trip =
          tripState.trips.where((t) => t.id == widget.tripId).firstOrNull;
      final landmarks =
          ref.read(tripProvider.notifier).getItemsAsLandmarks(widget.tripId);
      if (trip == null || landmarks.length < 2) {
        setState(() {
          _error = 'too_few';
          _loading = false;
        });
        return;
      }
      final region = landmarks.first.region;
      final locale = ref.read(localeProvider);
      final data = await ref.read(apiClientProvider).optimizeTrip(
            landmarks: landmarks
                .map((l) => {
                      'name': l.name,
                      'lat': l.lat,
                      'lng': l.lng,
                      'slug': l.slug,
                    })
                .toList(),
            region: region,
            checkIn: trip.checkIn,
            checkOut: trip.checkOut,
            locale: locale,
            maxBudget: (trip.maxBudget != null && trip.maxBudget != 'any')
                ? trip.maxBudget
                : null,
          );
      if (!mounted) return;
      setState(() {
        _result = ItineraryResult.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('SocketException') ||
                e.toString().contains('ConnectionTimeout')
            ? 'network'
            : 'error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(locale,
            ja: '旅程プラン', ko: '일정 플랜', en: 'Itinerary', zh: '行程规划', fr: 'Itinéraire')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(locale)
              : _buildContent(locale),
    );
  }

  Widget _buildError(String locale) {
    final msg = _error == 'too_few'
        ? tr(locale,
            ja: 'スポットを2つ以上追加してください',
            ko: '스팟을 2개 이상 추가해주세요',
            en: 'Add at least 2 spots',
            zh: '请添加至少2个景点',
            fr: 'Ajoutez au moins 2 lieux')
        : _error == 'network'
            ? tr(locale,
                ja: 'ネットワークエラー',
                ko: '네트워크 오류',
                en: 'Network error',
                zh: '网络错误',
                fr: 'Erreur réseau')
            : tr(locale,
                ja: 'プランを作成できませんでした',
                ko: '플랜을 만들지 못했습니다',
                en: 'Could not build the plan',
                zh: '无法生成规划',
                fr: 'Impossible de générer le plan');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 40, color: AppTheme.mutedForeground),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: AppTheme.mutedForeground)),
          if (_error != 'too_few') ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _optimize,
              child: Text(tr(locale,
                  ja: '再試行', ko: '다시 시도', en: 'Retry', zh: '重试', fr: 'Réessayer')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(String locale) {
    final result = _result!;
    if (result.clusters.isEmpty) return _buildError(locale);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Summary header
        Text(
          tr(locale,
              ja: '${result.totalDays}日間のおすすめ旅程',
              ko: '${result.totalDays}일 추천 일정',
              en: '${result.totalDays}-day plan',
              zh: '${result.totalDays}天推荐行程',
              fr: 'Plan de ${result.totalDays} jours'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (result.split) ...[
          const SizedBox(height: 4),
          Text(
            tr(locale,
                ja: 'エリアが離れているため、2つの拠点に分けました',
                ko: '지역이 떨어져 있어 2개 거점으로 나눴어요',
                en: 'Spots are far apart — split into 2 hotel bases',
                zh: '景点分散，已拆分为2个住宿据点',
                fr: 'Lieux éloignés — 2 bases hôtelières'),
            style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
          ),
        ],
        const SizedBox(height: 20),
        for (var i = 0; i < result.clusters.length; i++)
          _buildCluster(locale, result, result.clusters[i], i),
      ],
    );
  }

  Widget _buildCluster(
      String locale, ItineraryResult result, HotelCluster cluster, int index) {
    final base = cluster.hotelBase;
    final areaLetter = String.fromCharCode(65 + index); // A, B
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.split) ...[
          Text(
            tr(locale,
                ja: 'エリア $areaLetter',
                ko: '지역 $areaLetter',
                en: 'Area $areaLetter',
                zh: '区域 $areaLetter',
                fr: 'Zone $areaLetter'),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
        ],
        if (base != null) _buildHotelBase(locale, result, base),
        const SizedBox(height: 12),
        // Days
        for (final day in cluster.days) _buildDay(locale, day),
        // If the server returned no per-day split (e.g. no dates), show the
        // ordered landmarks as a single list so the plan is never empty.
        if (cluster.days.isEmpty && cluster.landmarks.isNotEmpty)
          _buildLandmarkList(cluster.landmarks),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHotelBase(String locale, ItineraryResult result, StayArea base) {
    final name =
        result.localNames[base.station.id] ?? base.station.localizedName(locale);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hotel, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tr(locale,
                      ja: '拠点: $name周辺',
                      ko: '거점: $name 주변',
                      en: 'Base: near $name',
                      zh: '据点: $name周边',
                      fr: 'Base : près de $name'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if ((base.areaDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              base.areaDescription!,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDay(String locale, ItineraryDay day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tr(locale,
                      ja: 'Day ${day.dayNumber}',
                      ko: 'Day ${day.dayNumber}',
                      en: 'Day ${day.dayNumber}',
                      zh: 'Day ${day.dayNumber}',
                      fr: 'Jour ${day.dayNumber}'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              if (day.date.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(day.date,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.mutedForeground)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          _buildLandmarkList(day.landmarks),
        ],
      ),
    );
  }

  Widget _buildLandmarkList(List<ItineraryLandmark> landmarks) {
    return Column(
      children: [
        for (var i = 0; i < landmarks.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.muted,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(landmarks[i].name,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
