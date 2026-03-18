import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../config/theme.dart';
import '../screens/trip/trip_screen.dart';

/// Shows a dialog to pick which trip to add a spot to
Future<String?> showTripPickerDialog(
  BuildContext context,
  List<Trip> candidates,
  String locale,
) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        locale == 'ja' ? '旅行を選択' : locale == 'ko' ? '여행 선택' : 'Choose Trip',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale == 'ja' ? 'どの旅行に追加しますか？'
              : locale == 'ko' ? '어떤 여행에 추가할까요?'
              : 'Which trip to add to?',
            style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 12),
          ...candidates.map((trip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, trip.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(localizedTripName(trip.name, locale)),
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(locale == 'ja' ? 'キャンセル' : locale == 'ko' ? '취소' : 'Cancel'),
        ),
      ],
    ),
  );
}
