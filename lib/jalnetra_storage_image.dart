import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class JalnetraStorageImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const JalnetraStorageImage({
    super.key,
    required this.imageUrl,
    this.width = 120,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// Fix old / wrong Firebase Storage URLs (app + web safe).
  String? _fixUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    var fixed = url.trim();

    // If some old documents stored firebasestorage.app instead of appspot.com
    fixed = fixed.replaceFirst(
      'jalnetra-44a79.firebasestorage.app',
      'jalnetra-44a79.appspot.com',
    );

    // Extra safety: any `firebasestorage.app` → `appspot.com`
    fixed = fixed.replaceFirst('firebasestorage.app', 'appspot.com');

    return fixed;
  }

  @override
  Widget build(BuildContext context) {
    final fixedUrl = _fixUrl(imageUrl);

    if (fixedUrl == null) {
      return _buildPlaceholder(context, 'No image');
    }

    final radius = borderRadius ?? BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        fixedUrl,
        width: width,
        height: height,
        fit: fit,
        // Works in both app & web
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? (loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('🧨 Image load error: $error');
          if (kDebugMode) {
            debugPrint('Image URL: $fixedUrl');
          }
          return _buildPlaceholder(context, 'Image error');
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String message) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, size: 28),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
