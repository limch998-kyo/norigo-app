import 'package:flutter/material.dart';

/// Wraps content with max width constraint for tablet/desktop.
/// On phones (<600px), content stretches full width as usual.
/// On tablets/desktop, content is centered with maxWidth.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveWrapper({super.key, required this.child, this.maxWidth = 600, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }

  /// Returns true if the screen is tablet-width or wider
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

  /// Returns responsive column count for GridView
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 3;
    return 2;
  }
}
