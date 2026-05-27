import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Known Unsplash image IDs that return 404. Treat as no image.
const _brokenUnsplashIds = [
  '1624222247344-9303e5e5a7b2',
  '1591047134859-ff89a5b5c87e',
  '1603561596112-0d3b0c93381e',
];

/// Use when a stock URL is not available; [SafeCachedNetworkImage] renders a local placeholder instead.
String get placeholderImageUrl => '';

/// Returns [url] if it looks valid and not known-broken; otherwise returns empty (callers show a muted placeholder).
String safeImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return '';
  }
  for (final id in _brokenUnsplashIds) {
    if (url.contains(id)) {
      return '';
    }
  }
  return url;
}

/// A [CachedNetworkImage] that substitutes broken or empty URLs with a placeholder
/// so 404s don't throw and the UI shows a consistent fallback.
class SafeCachedNetworkImage extends StatelessWidget {
  const SafeCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  @override
  Widget build(BuildContext context) {
    final url = safeImageUrl(imageUrl);
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppTheme.mutedColor(context),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 40),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder ??
          (_, __) => Container(
                color: AppTheme.mutedColor(context),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      errorWidget: errorWidget ??
          (_, __, ___) => Container(
                color: AppTheme.mutedColor(context),
                child: const Icon(Icons.image_not_supported, size: 40),
              ),
    );
  }
}
