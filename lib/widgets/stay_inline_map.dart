import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../models/stay_area.dart';
import '../models/landmark.dart';
import '../models/hotel.dart';

/// Shared inline map widget showing stay recommendation:
/// landmarks (indigo), recommended station (orange), hotels (green), route polylines.
class StayInlineMap extends StatelessWidget {
  final StayArea area;
  final List<Landmark> landmarks;
  final String locale;
  final List<Hotel> hotels;
  final bool interactive;

  const StayInlineMap({super.key, required this.area, required this.landmarks, this.locale = 'en', this.hotels = const [], this.interactive = true});

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.grey; }
  }

  @override
  Widget build(BuildContext context) {
    final allPoints = [
      LatLng(area.station.lat, area.station.lng),
      ...landmarks.map((l) => LatLng(l.lat, l.lng)),
      ...hotels.where((h) => h.lat != 0).map((h) => LatLng(h.lat, h.lng)),
    ];
    // Fit all points with padding so every marker is visible
    final bounds = LatLngBounds.fromPoints(allPoints);
    final center = bounds.center;
    // Calculate zoom from bounds span + add margin
    final latSpan = bounds.north - bounds.south;
    final lngSpan = bounds.east - bounds.west;
    final span = (latSpan > lngSpan ? latSpan : lngSpan) * 1.3; // 30% padding
    final zoom = span < 0.005 ? 16.0 : span < 0.01 ? 15.0 : span < 0.03 ? 14.0 : span < 0.06 ? 13.0 : span < 0.12 ? 12.0 : span < 0.3 ? 11.0 : span < 1.0 ? 10.0 : 8.0;

    // Build polylines from route segments
    final polylines = <Polyline>[];
    for (final ld in area.landmarkDistances) {
      for (final seg in ld.route) {
        if (seg.path != null && seg.path!.length >= 2) {
          final points = seg.path!.map((p) => LatLng(p[0], p[1])).toList();
          final isTransfer = seg.line == 'transfer';
          polylines.add(Polyline(
            points: points,
            color: isTransfer ? Colors.grey : _parseColor(seg.color),
            strokeWidth: isTransfer ? 3.0 : 4.0,
            pattern: isTransfer ? const StrokePattern.dotted() : const StrokePattern.solid(),
          ));
        }
      }
      if (ld.route.isEmpty && ld.estimatedMinutes > 0) {
        final lm = landmarks.where((l) => l.name == ld.landmarkName || l.slug == ld.landmarkName).firstOrNull;
        if (lm != null) {
          polylines.add(Polyline(
            points: [LatLng(area.station.lat, area.station.lng), LatLng(lm.lat, lm.lng)],
            color: Colors.grey,
            strokeWidth: 2.0,
            pattern: const StrokePattern.dotted(),
          ));
        }
      }
    }

    final flags = interactive
        ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
        : InteractiveFlag.none;

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: zoom, interactionOptions: InteractionOptions(flags: flags)),
      children: [
        TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png', userAgentPackageName: 'app.norigo'),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: [
          ...landmarks.asMap().entries.map((e) {
            final l = e.value;
            return Marker(
              point: LatLng(l.lat, l.lng), width: 28, height: 28,
              child: Container(
                decoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)]),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              ),
            );
          }),
          Marker(
            point: LatLng(area.station.lat, area.station.lng), width: 32, height: 32,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
              child: const Center(child: Icon(Icons.hotel, size: 16, color: Colors.white)),
            ),
          ),
          ...hotels.where((h) => h.lat != 0 && h.lng != 0).take(3).toList().asMap().entries.map((e) {
            final h = e.value;
            return Marker(
              point: LatLng(h.lat, h.lng), width: 22, height: 22,
              child: Container(
                decoration: BoxDecoration(color: AppTheme.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              ),
            );
          }),
        ]),
      ],
    );
  }
}
