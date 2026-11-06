import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centralized section header with an icon badge, headline, and subtitle.
class SectionHeaderBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final Color iconColor;

  const SectionHeaderBadge({
    super.key,
    this.icon = Icons.favorite,
    required this.title,
    required this.subtitle,
    this.badgeColor = AppColors.brandPurple,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
