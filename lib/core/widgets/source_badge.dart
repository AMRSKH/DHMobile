import 'package:flutter/material.dart';

import '../../domain/models/content_source.dart';
import '../theme/app_theme.dart';

/// The site a show comes from, as a small label on its poster, so the same
/// series from two sources can be told apart. Shows nothing for a provider id
/// that is no known source (old saved data).
class SourceBadge extends StatelessWidget {
  final String providerId;

  const SourceBadge({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final name = sourceNameOf(providerId);
    if (name == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
