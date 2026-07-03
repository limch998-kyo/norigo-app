import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/cached_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../services/api_client.dart';
import '../../utils/tr.dart';

class VoteScreen extends ConsumerStatefulWidget {
  final String pollId;

  const VoteScreen({super.key, required this.pollId});

  @override
  ConsumerState<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends ConsumerState<VoteScreen> {
  Map<String, dynamic>? _poll;
  Map<String, int> _voteCounts = {};
  int _totalVoters = 0;
  Set<String> _myVotes = {};
  List<String> _meetingSpotOptions = [];
  bool _loading = true;
  String? _error;
  String _voterId = '';
  Timer? _pollTimer;

  /// Collaborative plan (schedule + confirmed venue), read from poll.meta.
  Map<String, dynamic> get _meta =>
      (_poll?['meta'] as Map<String, dynamic>?) ?? const {};

  @override
  void initState() {
    super.initState();
    _initVoterId();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initVoterId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('norigo_voter_id');
    if (id == null) {
      id = DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
          (DateTime.now().microsecond).toRadixString(36);
      await prefs.setString('norigo_voter_id', id);
    }
    _voterId = id;
    await _fetchPoll();
    // Auto-refresh every 5 seconds (matching web)
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchPoll());
  }

  Future<void> _fetchPoll() async {
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getVotePoll(widget.pollId, voterId: _voterId);
      if (!mounted) return;
      setState(() {
        _poll = data['poll'] as Map<String, dynamic>?;
        _voteCounts = (data['voteCounts'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {};
        _totalVoters = (data['totalVoters'] as num?)?.toInt() ?? 0;
        _myVotes = ((data['myVenueIds'] as List<dynamic>?) ?? [])
            .map((e) => e.toString()).toSet();
        // Server returns curated options as localized objects {ja, ko, en}
        // (no 'name' key). Localize by the current locale; zh-TW → zh → en.
        final loc = ref.read(localeProvider);
        _meetingSpotOptions = ((data['meetingSpotOptions'] as List<dynamic>?) ?? [])
            .map((e) => e is Map
                ? ((e[loc] ??
                            (loc == 'zh-TW' ? e['zh'] : null) ??
                            e['en'] ??
                            e['ja'] ??
                            '')
                        .toString())
                : e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleVote(String venueId) async {
    // Optimistic update
    setState(() {
      if (_myVotes.contains(venueId)) {
        _myVotes.remove(venueId);
        _voteCounts[venueId] = (_voteCounts[venueId] ?? 1) - 1;
      } else {
        _myVotes.add(venueId);
        _voteCounts[venueId] = (_voteCounts[venueId] ?? 0) + 1;
      }
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.toggleVote(
        pollId: widget.pollId,
        venueId: venueId,
        voterId: _voterId,
      );
    } catch (_) {
      // Revert on error
      await _fetchPoll();
    }
  }

  // ── Collaborative plan (schedule + confirmed venue) ──────────────────

  Future<void> _patchPlan({
    String? eventDate,
    String? eventTime,
    String? meetingSpot,
    String? confirmedVenueId,
  }) async {
    final meta = await ref.read(apiClientProvider).updateVotePlan(
          widget.pollId,
          eventDate: eventDate,
          eventTime: eventTime,
          meetingSpot: meetingSpot,
          confirmedVenueId: confirmedVenueId,
        );
    if (!mounted) return;
    if (meta != null) {
      setState(() => _poll = {...?_poll, 'meta': meta});
      // Restart the refresh timer so the next poll is issued AFTER this write
      // persisted — otherwise an already-in-flight (pre-write) snapshot could
      // land and briefly revert the just-applied plan edit.
      _pollTimer?.cancel();
      _pollTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => _fetchPoll());
    } else {
      await _fetchPoll(); // fall back to canonical state
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      final d =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _patchPlan(eventDate: d);
    }
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final t =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _patchPlan(eventTime: t);
    }
  }

  Future<void> _pickMeetingSpot(String locale) async {
    final controller =
        TextEditingController(text: _meta['meetingSpot'] as String? ?? '');
    try {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(locale,
            ja: '集合場所', ko: '만남 장소', en: 'Meeting spot', zh: '集合地点', fr: 'Point de rencontre')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final opt in _meetingSpotOptions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined, size: 18),
                title: Text(opt, style: const TextStyle(fontSize: 13)),
                onTap: () => Navigator.pop(ctx, opt),
              ),
            if (_meetingSpotOptions.isNotEmpty) const Divider(),
            TextField(
              controller: controller,
              maxLength: 80,
              decoration: InputDecoration(
                hintText: tr(locale,
                    ja: '自由入力', ko: '직접 입력', en: 'Custom', zh: '自定义', fr: 'Personnalisé'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(locale,
                ja: 'キャンセル', ko: '취소', en: 'Cancel', zh: '取消', fr: 'Annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
                tr(locale, ja: '決定', ko: '확정', en: 'Set', zh: '确定', fr: 'OK')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _patchPlan(meetingSpot: result);
    }
    } finally {
      controller.dispose();
    }
  }

  Widget _buildPlanCard(String locale, List<Map<String, dynamic>> venues) {
    final date = _meta['eventDate'] as String?;
    final time = _meta['eventTime'] as String?;
    final spot = _meta['meetingSpot'] as String?;
    final confirmedId = _meta['confirmedVenueId'] as String?;
    final confirmedVenue = (confirmedId == null)
        ? null
        : venues
            .where((v) => (v['id']?.toString() ?? '') == confirmedId)
            .map((v) => v['name'] as String? ?? '')
            .firstOrNull;
    final unset =
        tr(locale, ja: '未定', ko: '미정', en: 'TBD', zh: '待定', fr: 'À définir');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(locale,
                ja: '待ち合わせ', ko: '약속 정하기', en: 'Meeting plan', zh: '约定', fr: 'Rendez-vous'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          _planRow(Icons.calendar_today, date ?? unset, _pickDate),
          _planRow(Icons.access_time, time ?? unset, _pickTime),
          _planRow(Icons.place, spot ?? unset, () => _pickMeetingSpot(locale)),
          if (confirmedVenue != null && confirmedVenue.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: AppTheme.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr(locale,
                        ja: '決定: $confirmedVenue',
                        ko: '확정: $confirmedVenue',
                        en: 'Confirmed: $confirmedVenue',
                        zh: '已定: $confirmedVenue',
                        fr: 'Confirmé : $confirmedVenue'),
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.green,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _planRow(IconData icon, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.mutedForeground),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
            Icon(Icons.edit, size: 13, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }

  void _sharePoll(String locale) {
    final url = 'https://norigo.app/$locale/vote/${widget.pollId}';
    SharePlus.instance.share(ShareParams(
      text: tr(locale, ja: 'お店の投票に参加してください！', ko: '맛집 투표에 참여해주세요!',
        en: 'Vote for restaurants!', zh: '来投票选餐厅！', fr: 'Votez pour les restaurants !') + '\n$url',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(locale, ja: '投票', ko: '투표', en: 'Vote', zh: '投票', fr: 'Vote'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _poll == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(locale, ja: '投票', ko: '투표', en: 'Vote', zh: '投票', fr: 'Vote'))),
        body: Center(child: Text(_error ?? tr(locale, ja: '投票が見つかりません', ko: '투표를 찾을 수 없습니다', en: 'Poll not found', zh: '找不到投票', fr: 'Sondage introuvable'))),
      );
    }

    final stationName = _poll!['stationName'] as String? ?? '';
    final venues = (_poll!['venues'] as List<dynamic>?) ?? [];

    // Sort by vote count (descending)
    final sorted = List<Map<String, dynamic>>.from(
      venues.map((v) => v as Map<String, dynamic>),
    )..sort((a, b) {
      final aCount = _voteCounts[a['id']?.toString() ?? ''] ?? 0;
      final bCount = _voteCounts[b['id']?.toString() ?? ''] ?? 0;
      return bCount.compareTo(aCount);
    });

    final maxVotes = _voteCounts.values.fold(0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(locale, ja: '$stationName駅 お店投票', ko: '$stationName역 맛집 투표',
          en: '$stationName Vote', zh: '$stationName站 投票', fr: 'Vote $stationName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _sharePoll(locale),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people, size: 18, color: AppTheme.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  tr(locale, ja: '$_totalVoters人が投票', ko: '$_totalVoters명 투표',
                    en: '$_totalVoters voters', zh: '$_totalVoters人投票', fr: '$_totalVoters votants'),
                  style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    final url = 'https://norigo.app/$locale/vote/${widget.pollId}';
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr(locale, ja: 'リンクをコピーしました', ko: '링크를 복사했습니다',
                        en: 'Link copied', zh: '已复制链接', fr: 'Lien copié')),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: Text(tr(locale, ja: 'リンクコピー', ko: '링크 복사', en: 'Copy link', zh: '复制链接', fr: 'Copier le lien'),
                    style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          _buildPlanCard(locale, sorted),

          // Venue list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final venue = sorted[index];
                final venueId = venue['id']?.toString() ?? '';
                final name = venue['name'] as String? ?? '';
                final genre = venue['genre'] as String? ?? '';
                final budget = venue['budget'] as String? ?? venue['budgetAverage'] as String? ?? '';
                final photoUrl = venue['photoUrl'] as String? ?? '';
                final voteCount = _voteCounts[venueId] ?? 0;
                final isMyVote = _myVotes.contains(venueId);
                final progress = maxVotes > 0 ? voteCount / maxVotes : 0.0;
                final venueUrl = venue['url'] as String? ?? '';
                final couponUrl = venue['couponUrl'] as String? ?? '';
                final catchText = venue['catch'] as String? ?? '';
                final confirmedId = _meta['confirmedVenueId'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isMyVote
                      ? BorderSide(color: AppTheme.primary, width: 2)
                      : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo
                            if (photoUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedImage(photoUrl, width: 70, height: 70, fit: BoxFit.cover),
                              ),
                            if (photoUrl.isNotEmpty) const SizedBox(width: 12),

                            // Info
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                if (genre.isNotEmpty)
                                  Text(genre, style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
                                if (budget.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(budget, style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
                                  ),
                                if (catchText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(catchText, maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
                                  ),
                              ],
                            )),
                            // Confirm-this-venue toggle (collaborative plan)
                            IconButton(
                              icon: Icon(
                                confirmedId == venueId ? Icons.flag : Icons.outlined_flag,
                                size: 18,
                                color: confirmedId == venueId ? AppTheme.green : AppTheme.mutedForeground,
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: tr(locale, ja: 'この店に決定', ko: '이 가게로 확정',
                                en: 'Confirm this venue', zh: '选定这家', fr: 'Confirmer ce lieu'),
                              onPressed: () => _patchPlan(confirmedVenueId: venueId),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Vote progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.muted,
                            color: isMyVote ? AppTheme.primary : AppTheme.mutedForeground.withValues(alpha: 0.4),
                            minHeight: 6,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Vote button + reserve link
                        Row(
                          children: [
                            // Vote button
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: isMyVote
                                  ? ElevatedButton(
                                      onPressed: () => _toggleVote(venueId),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        const Icon(Icons.check, size: 16),
                                        const SizedBox(width: 8),
                                        Text('$voteCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        Text(tr(locale, ja: '票', ko: '표', en: ' votes', zh: '票', fr: ' votes'),
                                          style: const TextStyle(fontSize: 11)),
                                      ]),
                                    )
                                  : OutlinedButton(
                                      onPressed: () => _toggleVote(venueId),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        const Icon(Icons.how_to_vote_outlined, size: 16),
                                        const SizedBox(width: 8),
                                        Text('$voteCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        Text(tr(locale, ja: '票', ko: '표', en: ' votes', zh: '票', fr: ' votes'),
                                          style: const TextStyle(fontSize: 11)),
                                      ]),
                                    ),
                              ),
                            ),

                            // Reserve button
                            if (venueUrl.isNotEmpty || couponUrl.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: () {
                                    final url = couponUrl.isNotEmpty ? couponUrl : venueUrl;
                                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  child: Text(
                                    couponUrl.isNotEmpty
                                      ? tr(locale, ja: 'クーポン', ko: '쿠폰', en: 'Coupon', zh: '优惠券', fr: 'Coupon')
                                      : tr(locale, ja: '予約', ko: '예약', en: 'Reserve', zh: '预约', fr: 'Réserver'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
