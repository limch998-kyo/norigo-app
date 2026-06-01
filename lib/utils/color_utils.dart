import 'package:flutter/material.dart';

/// Parse a hex color string (e.g. '#1A2B3C' or '1A2B3C') into a [Color].
/// Falls back to [Colors.grey] when the string can't be parsed.
Color hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return Colors.grey;
  }
}
