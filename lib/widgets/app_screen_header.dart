import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable top header displayed across main dashboard and flow screens.
class AppScreenHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final Widget? trailing;

  const AppScreenHeader({
    super.key,
    this.greeting = 'Welcome back',
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        trailing ??
            const CircleAvatar(
              backgroundColor: AppColors.avatarBg,
              child: Icon(Icons.person, color: AppColors.primaryStart),
            ),
      ],
    );
  }
}
