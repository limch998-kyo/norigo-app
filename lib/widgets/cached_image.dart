import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

/// Drop-in replacement for Image.network with disk caching.
class CachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String, Object)? errorBuilder;

  const CachedImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(color: AppTheme.muted),
      errorWidget: errorBuilder != null
          ? (ctx, url, err) => errorBuilder!(ctx, url, err)
          : (_, __, ___) => Container(color: AppTheme.muted, child: Icon(Icons.image_not_supported, size: 20, color: AppTheme.mutedForeground)),
    );
  }
}
