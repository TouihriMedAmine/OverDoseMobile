import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../ui/ui_kit.dart';

ImageProvider? resolveProductImageProvider(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) return null;

  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }

  if (kIsWeb) {
    return NetworkImage(path);
  }

  if (File(path).existsSync()) {
    return FileImage(File(path));
  }

  return NetworkImage(AppConfig.mediaUri(path).toString());
}

class ProductInsightCard extends StatelessWidget {
  const ProductInsightCard({
    super.key,
    required this.title,
    required this.status,
    this.subtitle,
    this.imageUrl,
    this.previewAlternatives = const [],
    this.footer,
    this.onTap,
    this.leadingIcon,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Widget status;
  final List<String> previewAlternatives;
  final Widget? footer;
  final VoidCallback? onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      padding: EdgeInsets.zero,
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.42,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3F7FF), Color(0xFFFFF3EC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: resolveProductImageProvider(imageUrl) == null
                    ? null
                    : DecorationImage(
                        image: resolveProductImageProvider(imageUrl)!,
                        fit: BoxFit.cover,
                      ),
              ),
              child: Stack(
                children: [
                  if (resolveProductImageProvider(imageUrl) == null)
                    Center(
                      child: Icon(
                        leadingIcon ?? Icons.science_outlined,
                        size: 48,
                        color: AppColors.ink.withValues(alpha: 0.72),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        status,
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (previewAlternatives.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: previewAlternatives
                        .take(2)
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue.withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 14),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: card,
      ),
    );
  }
}